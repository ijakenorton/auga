@echo off
setlocal

set SCRIPT_DIR=%~dp0
set BUILD=%SCRIPT_DIR%build
set TOOLS=%SCRIPT_DIR%tools\windows

if not exist "%BUILD%" mkdir "%BUILD%"

where cl >nul 2>&1
if %errorlevel% == 0 (
    echo CC: cl
    cl /nologo /W3 /Fo"%BUILD%\\" /Fe"%BUILD%\auga.exe" "%SCRIPT_DIR%auga.c"
    goto done
)

where gcc >nul 2>&1
if %errorlevel% == 0 (
    echo CC: gcc
    gcc -Wall -Wextra -Wswitch -o "%BUILD%\auga.exe" "%SCRIPT_DIR%auga.c"
    goto done
)

where clang >nul 2>&1
if %errorlevel% == 0 (
    echo CC: clang
    clang -Wall -Wextra -Wswitch -o "%BUILD%\auga.exe" "%SCRIPT_DIR%auga.c"
    goto done
)

if exist "%TOOLS%\tcc.exe" (
    echo No system compiler found, using bundled tcc
    "%TOOLS%\tcc.exe" -B "%TOOLS%" -o "%BUILD%\auga.exe" "%SCRIPT_DIR%auga.c"
    goto done
)

echo Error: no C compiler found and bundled tcc is missing
exit /b 1

:done
echo Built: %BUILD%\auga.exe
