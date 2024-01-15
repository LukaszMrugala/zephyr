#!/usr/bin/env python3
# Copyright (c) 2023 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
"""
Blackbox tests for twister's command line functions
"""

import importlib
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
