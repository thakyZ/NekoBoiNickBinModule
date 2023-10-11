@echo off
:: Copyright 2021 The Chromium Authors. All rights reserved.
:: Use of this source code is governed by a BSD-style license that can be
:: found in the LICENSE file.

setlocal

for /f %%i in (%~dp0\python3_bin_reldir.txt) do set PYTHON_BIN_ABSDIR=%%i
set PATH=%PYTHON_BIN_ABSDIR%;%PYTHON_BIN_ABSDIR%\Scripts;%PATH%
"%PYTHON_BIN_ABSDIR%\python3.exe" %*