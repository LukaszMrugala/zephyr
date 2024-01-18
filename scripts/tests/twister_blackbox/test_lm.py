#!/usr/bin/env python3
# Copyright (c) 2023 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
"""
Blackbox tests for twister's command line functions
"""

import importlib
import re
import mock
import os
import shutil
import pytest
import sys
import json

from conftest import ZEPHYR_BASE, TEST_DATA, testsuite_filename_mock
from twisterlib.testplan import TestPlan
from twisterlib.error import TwisterRuntimeError


class TestReport:
    TESTDATA_1 = [
        ('dummy.agnostic.group2.assert1', SystemExit, 3),
        (
            os.path.join('scripts', 'tests', 'twister_blackbox', 'test_data', 'tests',
                         'dummy', 'agnostic', 'group1', 'subgroup1',
                         'dummy.agnostic.group2.assert1'),
            TwisterRuntimeError,
            None
        ),
    ]

    @classmethod
    def setup_class(cls):
        apath = os.path.join(ZEPHYR_BASE, 'scripts', 'twister')
        cls.loader = importlib.machinery.SourceFileLoader('__main__', apath)
        cls.spec = importlib.util.spec_from_loader(cls.loader.name, cls.loader)
        cls.twister_module = importlib.util.module_from_spec(cls.spec)

    @classmethod
    def teardown_class(cls):
        pass

    @pytest.mark.usefixtures("clear_log")
    @pytest.mark.parametrize(
        '',
        TESTDATA_1,
        ids=[]
    )
    def BASE(self, capfd, out_path):
        test_platforms = ['qemu_x86', 'frdm_k64f']
        path = os.path.join(TEST_DATA)
        args = ['-i', '--outdir', out_path, '-T', path, '-y'] + \
               [] + \
               [val for pair in zip(
                   ['-p'] * len(test_platforms), test_platforms
               ) for val in pair]

        with mock.patch.object(sys, 'argv', [sys.argv[0]] + args), \
                pytest.raises(SystemExit) as sys_exit:
            self.loader.exec_module(self.twister_module)

        out, err = capfd.readouterr()
        sys.stdout.write(out)
        sys.stderr.write(err)

        # TESTPLAN CHECK SECTION
        #with open(os.path.join(out_path, 'testplan.json')) as f:
        #    j = json.load(f)
        #filtered_j = [
        #    (ts['platform'], ts['name'], tc['identifier']) \
        #        for ts in j['testsuites'] \
        #        for tc in ts['testcases'] if 'reason' not in tc
        #]

        assert str(sys_exit.value) == '0'

    @pytest.mark.skip
    @mock.patch.object(TestPlan, 'TESTSUITE_FILENAME', testsuite_filename_mock)
    def test_fixture(self, capfd, out_path):
        test_platforms = ['qemu_x86', 'frdm_k64f']
        path = os.path.join(TEST_DATA)
        args = ['-i', '--outdir', out_path, '-T', path, '-y'] + \
               ['--fixture', 'dummy_device_fixture'] + \
               [val for pair in zip(
                   ['-p'] * len(test_platforms), test_platforms
               ) for val in pair]

        with mock.patch.object(sys, 'argv', [sys.argv[0]] + args), \
                pytest.raises(SystemExit) as sys_exit:
            self.loader.exec_module(self.twister_module)

        out, err = capfd.readouterr()
        sys.stdout.write(out)
        sys.stderr.write(err)

        # TESTPLAN CHECK SECTION
        with open(os.path.join(out_path, 'testplan.json')) as f:
            j = json.load(f)
        filtered_j = [
            (ts['platform'], ts['name'], tc['identifier']) \
                for ts in j['testsuites'] \
                for tc in ts['testcases'] if 'reason' not in tc
        ]

        print(filtered_j)
        print(len(filtered_j))

        assert str(sys_exit.value) == '0'

    @pytest.mark.usefixtures("clear_log")
    @pytest.mark.parametrize(
        'jobs',
        ['1', '2'],
        ids=['single job', 'two jobs']
    )
    @mock.patch.object(TestPlan, 'TESTSUITE_FILENAME', testsuite_filename_mock)
    def test_jobs(self, out_path, jobs):
        test_platforms = ['qemu_x86', 'frdm_k64f']
        path = os.path.join(TEST_DATA, 'tests', 'dummy', 'agnostic', 'group2')
        args = ['-i', '--outdir', out_path, '-T', path] + \
               ['--jobs', jobs] + \
               [val for pair in zip(
                   ['-p'] * len(test_platforms), test_platforms
               ) for val in pair]

        with mock.patch.object(sys, 'argv', [sys.argv[0]] + args), \
                pytest.raises(SystemExit) as sys_exit:
            self.loader.exec_module(self.twister_module)

        with open(os.path.join(out_path, 'twister.log')) as f:
            log = f.read()
            assert f'JOBS: {jobs}' in log

        assert str(sys_exit.value) == '0'

    @pytest.mark.usefixtures("clear_log")
    @pytest.mark.parametrize(
        'tag, expected_test_count',
        [
            ('device', 5),   # dummy.agnostic.group1.subgroup1.assert
                             # dummy.agnostic.group1.subgroup2.assert
                             # dummy.agnostic.group2.assert1
                             # dummy.agnostic.group2.assert2
                             # dummy.agnostic.group2.assert3
            ('agnostic', 1)  # dummy.device.group.assert
        ],
        ids=['no device', 'no agnostic']
    )
    @mock.patch.object(TestPlan, 'TESTSUITE_FILENAME', testsuite_filename_mock)
    def test_exclude_tag(self, out_path, tag, expected_test_count):
        test_platforms = ['qemu_x86', 'frdm_k64f']
        path = os.path.join(TEST_DATA, 'tests', 'dummy')
        args = ['-i', '--outdir', out_path, '-T', path, '-y'] + \
               ['--exclude-tag', tag] + \
               [val for pair in zip(
                   ['-p'] * len(test_platforms), test_platforms
               ) for val in pair]

        with mock.patch.object(sys, 'argv', [sys.argv[0]] + args), \
                pytest.raises(SystemExit) as sys_exit:
            self.loader.exec_module(self.twister_module)

        with open(os.path.join(out_path, 'testplan.json')) as f:
            j = json.load(f)
        filtered_j = [
            (ts['platform'], ts['name'], tc['identifier']) \
                for ts in j['testsuites'] \
                for tc in ts['testcases'] if 'reason' not in tc
        ]

        assert len(filtered_j) == expected_test_count

        assert str(sys_exit.value) == '0'

    @pytest.mark.usefixtures("clear_log")
    @pytest.mark.parametrize(
        'seed, ratio, expected_order',
        [
            ('123', '1/2', ['dummy.agnostic.group1.subgroup1', 'dummy.agnostic.group1.subgroup2']),
            ('123', '2/2', ['dummy.agnostic.group2', 'dummy.device.group']),
            ('321', '1/2', ['dummy.agnostic.group1.subgroup1', 'dummy.agnostic.group2']),
            ('321', '2/2', ['dummy.device.group', 'dummy.agnostic.group1.subgroup2']),
            ('123', '1/3', ['dummy.agnostic.group1.subgroup1', 'dummy.agnostic.group1.subgroup2']),
            ('123', '2/3', ['dummy.agnostic.group2']),
            ('123', '3/3', ['dummy.device.group']),
            ('321', '1/3', ['dummy.agnostic.group1.subgroup1', 'dummy.agnostic.group2']),
            ('321', '2/3', ['dummy.device.group']),
            ('321', '3/3', ['dummy.agnostic.group1.subgroup2'])
        ],
        ids=['first half, 123', 'second half, 123', 'first half, 321', 'second half, 321',
             'first third, 123', 'middle third, 123', 'last third, 123',
             'first third, 321', 'middle third, 321', 'last third, 321']
    )
    @mock.patch.object(TestPlan, 'TESTSUITE_FILENAME', testsuite_filename_mock)
    def test_shuffle_tests(self, out_path, seed, ratio, expected_order):
        test_platforms = ['qemu_x86', 'frdm_k64f']
        path = os.path.join(TEST_DATA, 'tests', 'dummy')
        args = ['-i', '--outdir', out_path, '-T', path, '-y'] + \
               ['--shuffle-tests', '--shuffle-tests-seed', seed] + \
               ['--subset', ratio] + \
               [val for pair in zip(
                   ['-p'] * len(test_platforms), test_platforms
               ) for val in pair]

        with mock.patch.object(sys, 'argv', [sys.argv[0]] + args), \
                pytest.raises(SystemExit) as sys_exit:
            self.loader.exec_module(self.twister_module)

        with open(os.path.join(out_path, 'testplan.json')) as f:
            j = json.load(f)
        filtered_j = [
            (ts['platform'], ts['name'], tc['identifier']) \
                for ts in j['testsuites'] \
                for tc in ts['testcases'] if 'reason' not in tc
        ]

        testcases = [re.sub(r'\.assert[^\.]*?$', '', j[2]) for j in filtered_j]
        testsuites = list(dict.fromkeys(testcases))

        assert testsuites == expected_order

        assert str(sys_exit.value) == '0'


    @pytest.mark.usefixtures("clear_log")
    @pytest.mark.parametrize(
        'board_root, expected_returncode',
        [(True, '0'), (False, '2')],
        ids=['dummy in additional board root', 'no additional board root, crash']
    )
    @mock.patch.object(TestPlan, 'TESTSUITE_FILENAME', testsuite_filename_mock)
    def test_board_root(self, out_path, board_root, expected_returncode):
        test_platforms = ['qemu_x86', 'dummy']
        board_root_path = os.path.join(TEST_DATA, 'boards')
        path = os.path.join(TEST_DATA, 'tests', 'dummy')
        args = ['-i', '--outdir', out_path, '-T', path, '-y'] + \
               (['--board-root', board_root_path] if board_root else []) + \
               [val for pair in zip(
                   ['-p'] * len(test_platforms), test_platforms
               ) for val in pair]

        with mock.patch.object(sys, 'argv', [sys.argv[0]] + args), \
                pytest.raises(SystemExit) as sys_exit:
            self.loader.exec_module(self.twister_module)

        # Checking twister.log increases coupling,
        # but we need to differentiate crashes.
        with open(os.path.join(out_path, 'twister.log')) as f:
            log = f.read()
            error_regex = r'ERROR.*platform_filter\s+-\s+unrecognized\s+platform\s+-\s+dummy$'
            board_error = re.search(error_regex, log)
            assert board_error if not board_root else not board_error

        assert str(sys_exit.value) == expected_returncode

    @pytest.mark.usefixtures("clear_log")
    @pytest.mark.parametrize(
        'flag, expect_paths',
        [
            ('--no-detailed-test-id', False),
            ('--detailed-test-id', True)
        ],
        ids=['no-detailed-test-id', 'detailed-test-id']
    )
    @mock.patch.object(TestPlan, 'TESTSUITE_FILENAME', testsuite_filename_mock)
    def test_detailed_test_id(self, out_path, flag, expect_paths):
        test_platforms = ['qemu_x86', 'frdm_k64f']
        path = os.path.join(TEST_DATA, 'tests', 'dummy')
        args = ['-i', '--outdir', out_path, '-T', path, '-y'] + \
               [flag] + \
               [val for pair in zip(
                   ['-p'] * len(test_platforms), test_platforms
               ) for val in pair]

        with mock.patch.object(sys, 'argv', [sys.argv[0]] + args), \
                pytest.raises(SystemExit) as sys_exit:
            self.loader.exec_module(self.twister_module)

        with open(os.path.join(out_path, 'testplan.json')) as f:
            j = json.load(f)
        filtered_j = [
            (ts['platform'], ts['name'], tc['identifier']) \
                for ts in j['testsuites'] \
                for tc in ts['testcases'] if 'reason' not in tc
        ]

        assert len(filtered_j) > 0, "No dummy tests found."

        expected_start = os.path.relpath(TEST_DATA, ZEPHYR_BASE) if expect_paths else 'dummy.'
        assert all([testsuite.startswith(expected_start)for _, testsuite, _ in filtered_j])

        assert str(sys_exit.value) == '0'
