/*
 * Copyright (c) 2018-2024 Intel Corporation
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <limits.h>

#include <zephyr/devicetree.h>
#include <zephyr/init.h>
#include <zephyr/irq.h>
#include <zephyr/sys_clock.h>
#include <zephyr/spinlock.h>
#include <zephyr/arch/riscv/csr.h>
#include <zephyr/drivers/timer/system_timer.h>

/**
 * @brief Timer driver for used with Whisper simulator
 *
 * The Whisper simulator provides a pseudo timer which is based on
 * number of instructions executed instead of wall clock. It acts
 * similar to RISC-V machine timer with MTIME/MTIMECMP. However,
 * Whisper does not provide both MTIME and MTIMECMP. So the RISC-V
 * machine timer cannot be used. Instead, it provides the user CSR
 * TIME/TIMEH which acts the same as MTIME. However, there is no
 * equivalent to MTIMECMP. Instead, the comparison value needs to
 * be written to the memory address offseted to the address
 * specified in the "--clint" command line argument.
 * For interrupt, it still uses the CSR MIE for timer interrupt.
 *
 * Note that current version of whisper cannot process 64-bit write
 * to the compare value correctly under 32-bit system. That requires
 * 2 32-bit writes. However, writing the upper 32-bit value to
 * the 64-bit register would write to the lower 32-bit value instead,
 * effectively overriding the compare value. Once this issue is fixed,
 * enable CONFIG_TIMER_HAS_64BIT_CYCLE_COUNTER for full 64-bit
 * compare value support. For now, treat time/compare values as 32-bit
 * only. The whisper internal timer is still 64-bit. This means that
 * once the timer passes 0xFFFFFFFF cycles, no more timer interrupts
 * will trigger.
 */

#define DT_DRV_COMPAT	whisper_timer

#define TIMECMP_ADDR	DT_INST_REG_ADDR(0)
#define TIMER_IRQN	DT_INST_IRQN(0)

#define CYC_PER_TICK	\
	(uint32_t)(sys_clock_hw_cycles_per_sec() / CONFIG_SYS_CLOCK_TICKS_PER_SEC)

/* the unsigned long cast limits divisions to native CPU register width */
#define cycle_diff_t unsigned long
#define CYCLE_DIFF_MAX (~(cycle_diff_t)0)

/*
 * We have two constraints on the maximum number of cycles we can wait for.
 *
 * 1) sys_clock_announce() accepts at most INT32_MAX ticks.
 *
 * 2) The number of cycles between two reports must fit in a cycle_diff_t
 *    variable before converting it to ticks.
 *
 * Then:
 *
 * 3) Pick the smallest between (1) and (2).
 *
 * 4) Take into account some room for the unavoidable IRQ servicing latency.
 *    Let's use 3/4 of the max range.
 *
 * Finally let's add the LSB value to the result so to clear out a bunch of
 * consecutive set bits coming from the original max values to produce a
 * nicer literal for assembly generation.
 */
#define CYCLES_MAX_1	((uint64_t)INT32_MAX * (uint64_t)CYC_PER_TICK)
#define CYCLES_MAX_2	((uint64_t)CYCLE_DIFF_MAX)
#define CYCLES_MAX_3	MIN(CYCLES_MAX_1, CYCLES_MAX_2)
#define CYCLES_MAX_4	(CYCLES_MAX_3 / 2 + CYCLES_MAX_3 / 4)
#define CYCLES_MAX	(CYCLES_MAX_4 + LSB_GET(CYCLES_MAX_4))

static struct k_spinlock lock;
static uint64_t last_count;
static uint64_t last_ticks;
static uint32_t last_elapsed;

#if defined(CONFIG_TEST)
const int32_t z_sys_timer_irq_for_test = TIMER_IRQN;
#endif

static uintptr_t get_hart_timecmp(void)
{
	return TIMECMP_ADDR + (arch_proc_id() * 8);
}

static void set_timecmp(uint64_t time)
{
#if defined(CONFIG_64BIT)
	*(volatile uint64_t *)get_hart_timecmp() = time;
#elif defined(CONFIG_TIMER_HAS_64BIT_CYCLE_COUNTER)
	volatile uint32_t *r = (uint32_t *)get_hart_timecmp();

	/* The compare register is 64 bit, and we can only store 32-bit
	 * at a time. So we have to be careful about sequencing to avoid
	 * triggering spurious interrupts: always set the high word to
	 * a max value first.
	 */
	r[1] = 0xffffffff;
	r[0] = (uint32_t)time;
	r[1] = (uint32_t)(time >> 32);
#else
	volatile uint32_t *r = (uint32_t *)get_hart_timecmp();
	r[0] = (uint32_t)time;
#endif
}

static uint64_t get_current_time(void)
{
#if defined(CONFIG_64BIT)
	return csr_read(time);
#elif defined(CONFIG_TIMER_HAS_64BIT_CYCLE_COUNTER)
	uint32_t lo, hi;

	/* Likewise, must guard against rollover when reading */
	do {
		hi = csr_read(timeh);
		lo = csr_read(time);
	} while (csr_read(timeh) != hi);

	return (((uint64_t)hi) << 32) | lo;
#else
	return csr_read(time);
#endif
}

static void timer_isr(const void *arg)
{
	ARG_UNUSED(arg);

	k_spinlock_key_t key = k_spin_lock(&lock);

	uint64_t now = get_current_time();
	uint64_t dcycles = now - last_count;
	uint32_t dticks = (cycle_diff_t)dcycles / CYC_PER_TICK;

	last_count += (cycle_diff_t)dticks * CYC_PER_TICK;
	last_ticks += dticks;
	last_elapsed = 0;

	if (!IS_ENABLED(CONFIG_TICKLESS_KERNEL)) {
		uint64_t next = last_count + CYC_PER_TICK;

		set_timecmp(next);
	}

	k_spin_unlock(&lock, key);
	sys_clock_announce(dticks);
}

void sys_clock_set_timeout(int32_t ticks, bool idle)
{
	ARG_UNUSED(idle);

	if (!IS_ENABLED(CONFIG_TICKLESS_KERNEL)) {
		return;
	}

	k_spinlock_key_t key = k_spin_lock(&lock);
	uint64_t cyc;

	if (ticks == K_TICKS_FOREVER) {
		cyc = last_count + CYCLES_MAX;
	} else {
		cyc = (last_ticks + last_elapsed + ticks) * CYC_PER_TICK;
		if ((cyc - last_count) > CYCLES_MAX) {
			cyc = last_count + CYCLES_MAX;
		}
	}
	set_timecmp(cyc);

	k_spin_unlock(&lock, key);
}

uint32_t sys_clock_elapsed(void)
{
	if (!IS_ENABLED(CONFIG_TICKLESS_KERNEL)) {
		return 0;
	}

	k_spinlock_key_t key = k_spin_lock(&lock);
	uint64_t now = get_current_time();
	uint64_t dcycles = now - last_count;
	uint32_t dticks = (cycle_diff_t)dcycles / CYC_PER_TICK;

	last_elapsed = dticks;

	k_spin_unlock(&lock, key);

	return dticks;
}

uint32_t sys_clock_cycle_get_32(void)
{
	return ((uint32_t)get_current_time());
}

#if defined(CONFIG_TIMER_HAS_64BIT_CYCLE_COUNTER)
uint64_t sys_clock_cycle_get_64(void)
{
	return get_current_time();
}
#endif

static int sys_clock_driver_init(void)
{
	IRQ_CONNECT(TIMER_IRQN, 0, timer_isr, NULL, 0);
	last_ticks = get_current_time() / CYC_PER_TICK;
	last_count = last_ticks * CYC_PER_TICK;
	set_timecmp(last_count + CYC_PER_TICK);
	irq_enable(TIMER_IRQN);
	return 0;
}

#ifdef CONFIG_SMP
void smp_timer_init(void)
{
	set_timecmp(last_count + CYC_PER_TICK);
	irq_enable(TIMER_IRQN);
}
#endif

SYS_INIT(sys_clock_driver_init, PRE_KERNEL_2,
	 CONFIG_SYSTEM_CLOCK_INIT_PRIORITY);
