@echo on

REM Initial Processing-----------------------------------------------------------------
REM Directory/File Path Setting
set ROOT_DIR=%~dp0
set DATA_DIR=%ROOT_DIR%Data
set LOG_DIR=%DATA_DIR%\log
set OUTPUT_DIR=%ROOT_DIR%Out
set CONF_FILE=config-sample.ini

set DT=%date:/=%
set TM=%time: =0%
set DTTM=%DT%%TM:~0,2%%TM:~3,2%%TM:~6,2%

REM Start Main Processing--------------------------------------------------------------
REM Delete Files Generated Duaring Previous Run
if exist %LOG_DIR%\*.* del /Q %LOG_DIR%\*.*
if exist %OUTPUT_DIR%\*.* del /Q %OUTPUT_DIR%\*.*

REM Run Data Loader
powershell -NoProfile -ExecutionPolicy Unrestricted %DATA_DIR%\main.ps1 %CONF_FILE%

REM Store Generated Log Files
robocopy %LOG_DIR% %LOG_DIR%\old\%DTTM% /IF *.*

REM End Processing---------------------------------------------------------------------
echo "Process Completed"
pause
exit