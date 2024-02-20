#!/bin/python3

import re

class DediprogEraseException(Exception):
    pass

def dediprog_detect(exec_method):
    out, err = exec_method(cmd='dpcmd -d')
    if (re.search('Error', out) or err):
        raise DediprogEraseException("Chip cannot be detected, reset dediprog first!")

def dediprog_erase(exec_method, detect=True, max_attempts=5):
    attempt = 1
    if detect:
        dediprog_detect(exec_method=exec_method)
    while attempt <= max_attempts:
        print(f"Trying to erase chip for {max_attempts - attempt} times...")
        attempt += 1
        try:
            # Erase chip with dedpiprog
            _, err = exec_method(cmd='dpcmd --silent -e', timeout=60)
            if err:
                raise DediprogEraseException('Chip cannot be erased!')
            # Check if chip is blank
            out, err = exec_method(cmd='dpcmd --silent -b', timeout=60)
            if re.search('NOT blank', out):
                raise DediprogEraseException('Chip not blank or not identified!')
        except DediprogEraseException:
            continue
        break
