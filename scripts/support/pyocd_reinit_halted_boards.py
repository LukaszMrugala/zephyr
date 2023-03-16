#!/usr/bin/env python3

import re
from time import sleep

def _is_halted(exec_method, board_id):
    # Check if state of provided board is Halted and return True.
    cmd = ' '.join(['pyocd', 'cmd',
                    '-u', board_id,
                    '-c', 'status'])
    out, err = exec_method(cmd=cmd, timeout=10)
    if (re.search('Halted', out) or re.search('Halted', err)):
        return True
    return False

def reset_board(exec_method, board_id, timeout):
    # Reset the board with pyocd commander command 'reset'.
    if _is_halted(exec_method=exec_method, board_id=board_id):
        print(f'Resetting board: {board_id}')
        cmd = ["pyocd", "reset", "-l",
            "-O", "reset_type=hw",
            "-O", "connect_mode='under-reset'",
            "-u", board_id]
        exec_method(cmd=' '.join(cmd), timeout=timeout)
        sleep(timeout)
    else:
        print(f'Board {board_id} is not halted! Omitting..')
