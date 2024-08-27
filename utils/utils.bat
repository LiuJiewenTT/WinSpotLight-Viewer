REM delayedexpansion must be enabled to use this profile
set "testVar=something"
if "!testVar!" NEQ "something" (
	echo delayedexpansion must be enabled to use this profile
	goto :eof
)
set "testVar="
@REM echo on

set "arg1=%~1"

if "!arg1!"=="" (
	REM init
) else if "!arg1:~0,1!"==":" (
	goto !arg1!
)

@ goto:eof


:func_ensureACP
    @for /F "tokens=2 delims=:" %%i in ('chcp') do @( set /A codepage=%%i ) 
    set func_ensureACP_flag_default_silent=false
    :func_ensureACP_argparsing_looplabel
        set /A tmp=%~1-0
        if /I "%tmp%" == "%~1" (
            set func_ensureACP_target_codepage=%~1
        ) else if "%~1" == "--nametip" (
            set "func_ensureACP_target_codepage_name=%~2"
        ) else if "%~1" == "--default-silent" (
            set func_ensureACP_flag_default_silent=true
            set "func_ensureACP_flag_default_silent_echo_exec=@REM"
        )
        set tmp=
        shift /1
        if "%~1" NEQ "" (
            goto :func_ensureACP_argparsing_looplabel
        )
    
    if not defined func_ensureACP_target_codepage (
        echo ^[ERROR^]: No indicated codepage value.
        exit /b 1
    )
    if not defined func_ensureACP_target_codepage_name (
        set func_ensureACP_target_codepage_name=no tip
        if "%func_ensureACP_target_codepage%" == "65001" (
            set func_ensureACP_target_codepage_name=UTF-8
        )
    )

    @if /I "%codepage%" NEQ "%func_ensureACP_target_codepage%" ( 
        echo ^[LOG^]: Active code page is not %func_ensureACP_target_codepage% ^(%func_ensureACP_target_codepage_name%^). ^[%codepage%^]
        chcp %func_ensureACP_target_codepage%    
    ) else (
        %func_ensureACP_flag_default_silent_echo_exec% echo ^[LOG^]: Current code page is %codepage% ^(%func_ensureACP_target_codepage_name%^) already.
    )
    set func_ensureACP_target_codepage=
    set func_ensureACP_target_codepage_name=
    set func_ensureACP_flag_default_silent=
    set func_ensureACP_flag_default_silent_echo_exec=
@ goto:eof
