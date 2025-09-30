SETLOCAL ENABLEDELAYEDEXPANSION

REM The menuinst v2 json file is not compatible with menuinst versions
REM older than 2.1.1. Copy the appropriate file as the menu file.

SET LOGFILE=%PREFIX%\.messages.txt
SET MENU_DIR=%PREFIX%\Menu
SET MENU_PATH=%MENU_DIR%\%PKG_NAME%_menu.json


REM Determine menuinst version.
REM menuinst in the base environment is used to create the shortcuts,
REM so use the python binary in the base environment.
IF EXIST "%CONDA_PYTHON_EXE%" (
    SET PYTHON_CMD="%CONDA_PYTHON_EXE%"
    GOTO :get_menuinst
)
REM The CONDA_PYTHON_EXE variable is not set for installers, so use conda-standalone.
IF EXIST "%PREFIX%\_conda.exe" (
    SET PYTHON_CMD="%PREFIX%\_conda.exe" python
    SET CONDA_STANDALONE=1
    GOTO :get_menuinst
)
GOTO :use_menuinst_v1

:get_menuinst
%PYTHON_CMD% -c "import menuinst, sys; sys.exit(1 if tuple(int(x) for x in menuinst.__version__.split(\".\"))[:3] < (2, 1, 1) else 0)"
IF %ERRORLEVEL% == 1 GOTO :use_menuinst_v1

COPY /y "%PREFIX%\Menu\%PKG_NAME%_menu-v2.json.bak" "%MENU_PATH%"

REM Determine if the shortcut is installed into the base environment
%PYTHON_CMD% -c "import os, sys; from pathlib import Path; from menuinst.utils import _default_prefix; sys.exit(int(Path(os.environ['PREFIX']).samefile(_default_prefix(which='base'))))"
IF %ERRORLEVEL% == 0 (
    CALL :patch "__ENV_PLACEHOLDER__= ^({{ ENV_NAME }}^)"
) ELSE (
    CALL :patch "__ENV_PLACEHOLDER__="
)
GOTO :exit

:patch
    SET TMPMENU=%MENU_DIR%\%PKG_NAME%_menu_tmp.json
    SET FINDREPLACE=%~1
    FOR /f "delims=" %%i IN ('type "%MENU_PATH%"') DO (
        SET s=%%i
        ECHO !s:%FINDREPLACE%!>> "%TMPMENU%"
    )
    MOVE /Y "%TMPMENU%" "%MENU_PATH%"
    GOTO :eof

:use_menuinst_v1:
    COPY /y "%PREFIX%\Menu\%PKG_NAME%_menu-v1.json.bak" "%MENU_PATH%"
    ECHO. >> "%LOGFILE%"
    ECHO Warning: using menuinst v1 shortcuts >> "%LOGFILE%"
    ECHO Please update menuinst in the base environment and reinstall %PKG_NAME%. >> "%LOGFILE%"
    GOTO :exit

:exit
    EXIT /B %ERRORLEVEL%
