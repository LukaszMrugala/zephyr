#!/usr/bin/env python3
# vim: set syntax=python ts=4 :
#
# Copyright (c) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

import os

from pathlib import Path

def prepare_path_for_windows(path):
    if os.name == 'nt':
        return '\\\\?\\' + os.fspath(Path(path).resolve())
    return path

def open(filename, *args, **kwargs):
    return open(prepare_path_for_windows(filename), *args, **kwargs)


def makedirs(filename, *args, **kwargs):
    return os.makedirs(prepare_path_for_windows(filename), *args, **kwargs)


def mkdir(filename, *args, **kwargs):
    return os.mkdir(prepare_path_for_windows(filename), *args, **kwargs)
