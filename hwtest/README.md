# Zephyr DevOps HW Test Module

dut.map - maps Zephyr-named DUT (Device Under Test) to specific Test-Agent via MAC address

get-tty.sh - get TTY/UART device on Test-Agent. Uses dut.map to look-up by MAC & Zephyr platform name

runner.sh - bash runner script that executes HW test on Test-Agent
