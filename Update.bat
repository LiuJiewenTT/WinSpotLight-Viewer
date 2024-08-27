@setlocal enableDelayedExpansion
@echo off
@REM Set codepage to UTF-8(65001)
@call "%~dp0\utils\utils.bat" :func_ensureACP 65001 --nametip "UTF-8" --default-silent
@REM -----divider-----

@REM Settings

@REM read_dir indicates the source directory for the work.
set read_dir=%LOCALAPPDATA%\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets\

set picture_ext=.jpg

@REM default output directories 
set output_preview_dir_default=%cd%\Preview\
set output_dir_default=%cd%\Extracted\
set output_db_extract_record_dir_default=%cd%\db\extract_record\

@REM work_mode can take values from list: [preview, extract]
set work_mode_default=preview
@REM set work_mode_default=extract

@REM -----divider-----

set flag_dry_run=false
set flag_input_abspath=false
set flag_input_relpath_ok=false

@REM -----divider-----

call :show_versioninfo

@REM -----divider-----

echo cwd=%cd%

set argv_all=%*
set argv0=%~f0
set /a arg_cnt=0

for %%A in (%*) do (
    set /a arg_cnt+=1
    set "argv!arg_cnt!=%%~A"
)
echo arg_cnt=%arg_cnt%

set next_flag=0
set next_field_valtype=STORE

for /L %%i in (1, 1, %arg_cnt%) do (
    if /I "!next_flag!" equ "1" (
        call :set_varval_argv_processor %%i
        set next_flag=0
        set next_field_destvar=
    )
    set next_field_valtype=STORE
    
    if "!argv%%i!" == "-S" (
        set next_flag=1
        set next_field_destvar=read_dir
    ) else if "!argv%%i!" == "-M" (
        set next_flag=1
        set next_field_destvar=work_mode
    ) else if "!argv%%i!" == "-O" (
        set next_flag=1
        set next_field_destvar=output_dir
    ) else if "!argv%%i!" == "--dry-run" (
        set next_field_destvar=flag_dry_run
        set next_field_valtype=BOOLEAN_TRUE
    ) else if "!argv%%i!" == "--input-abspath" (
        set next_field_destvar=flag_input_abspath
        set next_field_valtype=BOOLEAN_TRUE
    ) else if "!argv%%i!" == "-h" (
        call :show_help
        goto:endsection
    )

    @REM Process now!
    if "!next_field_valtype:~0,8!" == "BOOLEAN_" (
        call :set_varval_argv_processor %%i
    )
)

if "%next_flag%" == "1" (
    echo WARNING: Did not receive a value for "%next_field_destvar%" of option "!argv%arg_cnt%!".
)

echo flag_dry_run=!flag_dry_run!
if /I "!flag_dry_run!" == "true" (
    set dry_exec1=echo ^[DRY RUN^] Would execute:
) else (
    set "dry_exec1="
)

if not defined work_mode (
    set work_mode=%work_mode_default%
)
echo work_mode=%work_mode%

if "%flag_input_abspath%" == "true" (
    call :ensure_directory_abspath read_dir
)
call :ensure_directory_ending read_dir
echo read_dir=%read_dir%


if not defined output_dir (
    if "%work_mode%" == "preview" (
        set output_dir=%output_preview_dir_default%
    ) else if "%work_mode%" == "extract" (
        set output_dir=%output_dir_default%
    ) else (
        echo ERROR: work_mode="%work_mode%" is not supported.
        goto:endsection
    )
)
@REM if "%flag_input_abspath%" == "true" (
@REM     call :ensure_directory_abspath output_dir
@REM )
call :ensure_directory_ending output_dir
echo output_dir=%output_dir%

if not exist "%output_dir%" (
    %dry_exec1% mkdir "%output_dir%"
    if ERRORLEVEL 1 (
        echo ERROR: Create outdir "%output_dir%" failed.
        goto:endsection
    )
)

if not exist "%read_dir%" (
    echo ERROR: The read directory "%read_dir%" does not exist.
    goto:endsection
)

set disksign_output_dir=
for /f "delims=" %%i in ('echo %output_dir% ^| findstr ":"') do (
    set tmp=%%i
    set disksign_output_dir=%tmp:~0,1%
)
set tmp=
set disksign_read_dir=
for /f "delims=" %%i in ('echo %read_dir% ^| findstr ":"') do (
    set tmp=%%i
    set disksign_read_dir=%tmp:~0,1%
)
set tmp=

echo flag_input_abspath=%flag_input_abspath%
if "%flag_input_abspath%" NEQ "true" (
    if "%disksign_output_dir%" == "%disksign_read_dir%" (
        rem on the same drive, convert it to relative path.
        call calc_relpath.bat "%output_dir%" "%read_dir%"
        @REM call calc_relpath.bat "%output_dir%" "%read_dir%" --print-result
        set flag_input_relpath_ok=true
        call :ensure_directory_ending relativePath
        echo relativePath=!relativePath!
    )
)

if "%work_mode%" == "preview" (
    call :main_of_preview_mode
) else if "%work_mode%" == "extract" (
    call :main_of_extract_mode
) else (
    echo ERROR: work_mode="%work_mode%" is not supported. ^(Illegal situation^).
    goto:endsection
)

:endsection
endlocal
goto:eof


:show_versioninfo
    echo WinSpotLight Viewer ^(v1.0.0, build 2024082301^) by LiuJiewenTT ^(liuljwtt@163.com^)
    echo Repo Link: https://github.com/LiuJiewenTT/WinSpotLight-Viewer
    echo ------------------------------------------------------------------------------------
goto:eof


:show_help
    echo usage: %~nx0 [options]...
    echo options:
    echo     -O outdir : Specify output directory.
    echo     -M mode   : Specify work_mode. Can be one of ^[preview, extract^].
    echo     -S srcdir : Specify source directory where files are read from. Default is %read_dir%.
    echo     --dry-run : Don't actually do anything, just show what would be done.
    echo     -h        : Show this help message.
goto:eof


:ensure_directory_ending
    set varname=%~1
    set value=!%~1!

    if "%value:~-1%" NEQ "\" (
        set %varname%=!value!\
    )

    set varname=
    set value=
goto:eof


:ensure_directory_abspath
    set varname=%~1
    set value=!%~1!

    for /f "delims=" %%i in ('echo %value% ^| findstr ":"') do (
        goto:eof
    )
    set %varname%=%cd%\!value!

    set varname=
    set value=
goto:eof


:set_varval
    set %~1=%~2
goto:eof


:set_varval_argv_processor
    if "%next_field_valtype%" == "BOOLEAN_TRUE" (
        call :set_varval "!next_field_destvar!" "true"
    ) else if "%next_field_valtype%" == "BOOLEAN_FALSE" (
        call :set_varval "!next_field_destvar!" "false"
    ) else (
        if "%next_field_valtype%" NEQ "STORE" (
            echo WARNING: Bad argv forward type when processing argv^[%~1^].
        )
        call :set_varval "!next_field_destvar!" "!argv%~1!"
    )
goto:eof


:main_of_preview_mode
    echo Work in Preview Mode
    for /f "delims=" %%i in ('dir /B /A:-D "%read_dir%"') do (
        if not exist "%output_dir%%%~ni%picture_ext%" (
            echo Gonna link: "%%i"
            if "%flag_input_relpath_ok%" == "true" (
                set tmp_target_path=%relativePath%
            ) else (
                set tmp_target_path=%read_dir%
            )
            %dry_exec1% mklink "%output_dir%%%~ni%picture_ext%" "!tmp_target_path!%%i"
            if ERRORLEVEL 1 (
                echo ERROR: ^(For "%%~ni"^) Create symbolic link "%output_dir%%%~ni%picture_ext%" failed.
            ) else if "%flag_dry_run%" NEQ "true" (
                echo Created: "%output_dir%%%~ni%picture_ext%" ^^ target="%read_dir%%%i"
                echo.
            )
        )
    )
    set tmp_target_path=
goto:eof


:main_of_extract_mode
    echo Work in Extract Mode

    set tmp_robocopy_cmd=robocopy "!read_dir!." "!output_dir!." /LEV:1 /XD * /XJD /LOG:robo.log /TEE /NJH /NJS /FP
    if "%flag_dry_run%" == "true" (
        set tmp_robocopy_cmd=%tmp_robocopy_cmd% /L
        !tmp_robocopy_cmd!
    ) else (
        @REM execute case params appending
        @REM set tmp_robocopy_cmd=%tmp_robocopy_cmd% /UNILOG:robo.log /TEE /NJH /NJS /FP
    )
    %dry_exec1% %tmp_robocopy_cmd%
    set tmp_robocopy_cmd=
goto:eof
