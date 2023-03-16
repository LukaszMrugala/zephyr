#!/bin/python3
import subprocess, sys, argparse

# As the first argument, it takes place from the labgrid,
# and the second as power actions to be performed (on, off, cycle)

PARSER = argparse.ArgumentParser(allow_abbrev=False)
ARG_LIST = ["lg-place", "lg-power", "lg-crossbar", "lg-timeout"]
# List of available POWER_TYPE values
LG_POWER_TYPES = ["on", "off", "cycle"]

def parser(arguments: list):
    for arg in arguments:
        _action = 'store'
        _default = None
        PARSER.add_argument(
            f'--{arg}',
            action=_action,
            dest=f'{arg.replace("-", "_")}',
            default=_default
        )
    args = PARSER.parse_args()

    return args

def _execute(cmd, timeout=3, shell=True, executable="/bin/bash"):
    try:
        process = subprocess.Popen(cmd, shell=shell,
                                    executable=executable,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE)
        stdout, stderr = process.communicate(timeout=timeout)
    except TimeoutError:
        process.kill()

    print(f'command {cmd}: output {stdout.decode()}' \
          f'{f", error: {stderr.decode()}" if stderr else ""}')

    return stdout.decode(), stderr.decode()

def _get_locked_places_and_unlock_them(lg_crossbar, lg_place=None):
    cmd = ["labgrid-client", "-x", lg_crossbar,
           "who | awk 'NR>1 { print $3 }'"]
    out, _err = _execute(cmd=' '.join(cmd))
    if lg_place:
        if lg_place in out:
            _cmd = ["labgrid-client",
                    "-x", lg_crossbar,
                    "-p", lg_place,
                    "unlock", "--kick"]
            _execute(cmd=' '.join(_cmd))
    else:
        for place in out:
            _cmd = ["labgrid-client",
                    "-x", lg_crossbar,
                    "-p", place,
                    "unlock", "--kick"]
            _execute(cmd=' '.join(_cmd))

def power(lg_place=None, lg_power=None,lg_crossbar=None, lg_timeout=3):
    # Check if POWER_TYPE is in the list of available values
    if lg_power not in LG_POWER_TYPES:
        msg = f"Illegal LG_POWER value: {lg_power} " \
              f"Available LG_POWER: {', '.join(LG_POWER_TYPES)}"
        sys.exit(msg)

    _get_locked_places_and_unlock_them(lg_crossbar=lg_crossbar, lg_place=lg_place)
    # Labgrid commands
    commands = [
        f"labgrid-client -x {lg_crossbar} -p {lg_place} lock",
        f"labgrid-client -x {lg_crossbar} -p {lg_place} power {lg_power}",
        f"labgrid-client -x {lg_crossbar} -p {lg_place} unlock"
    ]

    for lg_cmd in commands:
        _execute(cmd=lg_cmd, timeout=lg_timeout)

if __name__ == "__main__":
    args = parser(ARG_LIST)
    power(lg_place=args.lg_place,
          lg_power=args.lg_power,
          lg_crossbar=args.lg_crossbar,
          lg_timeout=args.lg_timeout)
