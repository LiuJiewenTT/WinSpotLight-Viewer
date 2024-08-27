@echo off

setlocal enableDelayedExpansion

set log_input=%1
echo log_input=%log_input%

set log_output=%log_input%
call :var_getPartAsParam log_output dpn
set log_output=%log_output%.parsed.log
echo log_output=%log_output%

echo.>"%log_output%"
for /f "usebackq skip=2 tokens=3*" %%i in ("%log_input%") do (
    echo %%j>>"%log_output%"
)

endlocal
goto:eof


:var_getPartAsParam
    set varname=%~1
    set varPartsSigns=%~2
    for /f "delims=" %%i in ("!%varname%!") do (
        set "tmp=%%~%varPartsSigns%i"
    )
    set "%varname%=%tmp%"
goto:eof
