#!/usr/bin/env python3

import re
from time import sleep
from dediprog_erase import dediprog_detect, dediprog_erase, DediprogEraseException
from labgrid_prepare_platform import power, parser, _execute
from pyocd_reinit_halted_boards import reset_board


ARGS = ['pyocd-board-id', 'pyocd-timeout',
        'labgrid-place', 'labgrid-crossbar',
        'labgrid-timeout', 'dpcmd-erase',
        'dpcmd-place']

def prepare_platform(pyocd_board_id=None, pyocd_timeout=None,
                     labgrid_place=None, labgrid_crossbar=None,
                     labgrid_timeout=None, dpcmd_erase=None,
                     dpcmd_place=None):
    if not labgrid_timeout:
        labgrid_timeout = 5
    if isinstance(labgrid_timeout, str):
        labgrid_timeout = int(labgrid_timeout)
    if not pyocd_board_id:
        pyocd_timeout = 5
    if isinstance(pyocd_timeout, str):
        pyocd_timeout = int(pyocd_timeout)
    if pyocd_board_id:
        if re.search(',', pyocd_board_id):
            for id in pyocd_board_id.split(','):
                reset_board(exec_method=_execute,
                            board_id=id,
                            timeout=pyocd_timeout)
                sleep(pyocd_timeout)
        else:
            reset_board(exec_method=_execute,
                        board_id=pyocd_board_id,
                        timeout=pyocd_timeout)

    elif labgrid_place:
        if re.search(',', labgrid_place):
            for place in labgrid_place.split(','):
                power(lg_place=place, lg_crossbar=labgrid_crossbar,
                      lg_power='off', lg_timeout=labgrid_timeout)
                sleep(labgrid_timeout)
                if dpcmd_erase == 'True':
                    try:
                        dediprog_detect(exec_method=_execute)
                    except DediprogEraseException:
                        if dpcmd_place:
                            # Dediprog reset is sometimes needed to detect chip
                            power(lg_place=dpcmd_place, lg_crossbar=labgrid_crossbar,
                                  lg_power='off', lg_timeout=labgrid_timeout)
                            sleep(labgrid_timeout)
                            power(lg_place=dpcmd_place, lg_crossbar=labgrid_crossbar,
                                  lg_power='on', lg_timeout=labgrid_timeout)
                    finally:
                        dediprog_erase(exec_method=_execute, detect=False)
                power(lg_place=place, lg_crossbar=labgrid_crossbar,
                      lg_power='on', lg_timeout=labgrid_timeout)
        else:
            power(lg_place=labgrid_place, lg_crossbar=labgrid_crossbar,
                  lg_power='off', lg_timeout=labgrid_timeout)
            sleep(labgrid_timeout)
            if dpcmd_erase == 'True':
                try:
                    dediprog_detect(exec_method=_execute)
                except DediprogEraseException:
                    if dpcmd_place:
                        # Dediprog reset is sometimes needed to detect chip
                        power(lg_place=dpcmd_place, lg_crossbar=labgrid_crossbar,
                              lg_power='off', lg_timeout=labgrid_timeout)
                        sleep(labgrid_timeout)
                        power(lg_place=dpcmd_place, lg_crossbar=labgrid_crossbar,
                              lg_power='on', lg_timeout=labgrid_timeout)
                finally:
                    dediprog_erase(exec_method=_execute, detect=False)
            power(lg_place=labgrid_place, lg_crossbar=labgrid_crossbar,
                  lg_power='on', lg_timeout=labgrid_timeout)

    else:
        raise Exception('ERROR: Provide labgrid-place or pyocd-board-id!')

if __name__ == "__main__":
    args = parser(arguments=ARGS)
    prepare_platform(pyocd_board_id=args.pyocd_board_id,
                     pyocd_timeout=args.pyocd_timeout,
                     labgrid_place=args.labgrid_place,
                     labgrid_crossbar=args.labgrid_crossbar,
                     labgrid_timeout=args.labgrid_timeout,
                     dpcmd_erase=args.dpcmd_erase,
                     dpcmd_place=args.dpcmd_place)
