@echo off
if "%~3" == "--test" (
    set "flag_test=1"
    setlocal enabledelayedexpansion
) else (
    set flag_test=0
)
if "%~3" == "--test-silent" (
    set "flag_test_silent=1"
    setlocal enabledelayedexpansion
) else (
    set flag_test_silent=0
)
if "%~3" == "--print-result" (
    set "flag_print_result=1"
) else (
    set flag_print_result=0
)

REM delayedexpansion must be enabled to use this script
set "testVar=something"
if "!testVar!" NEQ "something" (
	echo ERROR: delayedexpansion must be enabled to use this profile
	goto :eof
)
set "testVar="
@REM setlocal enabledelayedexpansion

:: 输入两个路径
@REM set "from=C:\Folder1\Subfolder1\Subfolder2"
@REM set "to=C:\Folder1\Subfolder1\Subfolder3\File.txt"
set "from=%~1"
set "to=%~2"

if "%from:~-1%" == "\" (
    set "from=%from:~0,-1%"
)
if "%to:~-1%" == "\" (
    set "to=%to:~0,-1%"
)

:: 将两个路径转换为各级目录的列表
call :PathToList "%from%" fromList
call :PathToList "%to%" toList

if /I "!fromList.Len!" GTR "!toList.Len!" (
    set commons_cnt_max=!toList.Len!
) else (
    set commons_cnt_max=!fromList.Len!
)

if "%flag_test%" == "1" (
    echo fromList=
    for /L %%i in (1, 1, %fromList.Len%) do (
        echo %%i= !fromList[%%i]!
    )
    echo toList=
    for /L %%i in (1, 1, %toList.Len%) do (
        echo %%i= !toList[%%i]!
    )
)

:: 找到两个路径的共同前缀
set "commonPath="
for /L %%i in (1,1,%commons_cnt_max%) do (
    for %%a in (!fromList[%%i]!) do (
        for %%b in (!toList[%%i]!) do (
            if "%%a" == "%%b" (
                set "commonPath=!commonPath!\%%a"
                if "%flag_test%" == "1" (
                    echo "commonPath=!commonPath!\%%a"
                )
                set "commonLen=%%i"
            ) else (
                goto :foundCommon
            )
        )
    )
)
:foundCommon

:: 计算相对路径
set "relativePath="
set /a tmplen=!commonLen!+1
for /L %%i in (%tmplen%,1,%fromList.Len%) do (
    set "relativePath=!relativePath!..\"
)
for /L %%i in (%tmplen%,1,%toList.Len%) do (
    set "relativePath=!relativePath!!toList[%%i]!"
    if %%i lss %toList.Len% set "relativePath=!relativePath!\"
)
set "tmplen="

:: 显示结果
if "%flag_test%" == "1" (
    echo From: "%from%"
    echo To: "%to%"
    echo Relative path: "!relativePath!"
)
if "%flag_test_silent%" == "1" (
    echo From: "%from%"
    echo To: "%to%"
    echo Relative path: "!relativePath!"
)
if "%flag_print_result%" == "1" (
    echo From: "%from%"
    echo To: "%to%"
    echo Relative path: "%relativePath%"
)

if "%flag_test%" == "1" (
    endlocal 
)

:endsection
set "flag_test="
set "flag_test_silent="
set "flag_print_result="
goto:eof

:PathToList
set "path=%~1"
set "name=%~2"

set "%name%.Len=0"
set "count=0"
for %%a in ("%path:\=" "%") do (
    set /a count+=1
    set "!name![!count!]=%%~a"
)
set "%name%.Len=!count!"
set "path="
set "name="
set "count="
goto:eof
