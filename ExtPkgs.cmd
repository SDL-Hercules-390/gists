@if defined TRACEON (@echo on) else (@echo off)
  setlocal

  set "_versnum=1.3"
  set "_versdate=April 2, 2019"

  REM    If this batch file works then it was written by Fish.
  REM    If it doesn't then I don't know who the heck wrote it.

  goto :INIT

::-----------------------------------------------------------------------------
::                           EXTPKGS.CMD
::-----------------------------------------------------------------------------
:HELP

  echo.
  echo     NAME
  echo.
  echo         %nx0%  --  Build and install Hercules External Package(s)
  echo.
  echo     SYNOPSIS
  echo.
  echo         %nx0%      { [CLONE ^| UPDATE]   [C]  [D]  [S]  [T] }
  echo.
  echo     DESCRIPTION
  echo.
  echo         %n0% performs a full build and install of each specified
  echo         Hercules External Package.  It is used to automate the
  echo         cloning, updating and/or building and installing of all
  echo         selected External Packages with one simple command (rather
  echo         than having to perform each of the builds individually)
  echo         and ensures that each of them are built the same way.
  echo.
  echo     ARGUMENTS
  echo.
  echo         CLONE      Indicates the specified package repositories do
  echo                    not exist yet and need to be git cloned before
  echo                    building.  This option, if specified, must come
  echo                    before the C^|D^|S^|T option(s).
  echo.
  echo         UPDATE     Indicates the specified package repositories
  echo                    should be git updated before building.  This
  echo                    option, if specified, must come before the
  echo                    C^|D^|S^|T option(s).
  echo.
  echo         C^|D^|S^|T    Corresponds to which external package(s) you
  echo                    wish to clone, update and/or build and install
  echo                    (crypto, decNumber, SoftFloat and/or telnet,
  echo                    or all four, or any combination thereof)
  echo.
  echo     EXIT STATUS
  echo.
  echo         0   Success    All specified external packages successfully
  echo                        cloned, updated and/or built and installed.
  echo.
  echo         1   Failure    The clone, update, build or install of one
  echo                        or more specified packages has failed.
  echo.
  echo     NOTES
  echo.
  echo        The required "%nx0%.ini" control file identifies the
  echo        fixed parameters needed by the script, and is expected to
  echo        exist somewhere in your search PATH.
  echo.
  echo        The control file must contain statements that identify the
  echo        directory of each external package's repository, as well
  echo        as the common installation directory where each package
  echo        will be installed into.
  echo.
  echo        The format of the statements is very simple:
  echo.
  echo             cpu             =  aarch^|arm^|mips^|ppc^|sparc^|s390x^|xscale^|x86^|unknown
  echo             install_dir     =  ^<dir^>
  echo             crypto_repo     =  ^<dir^>
  echo             decnumber_repo  =  ^<dir^>
  echo             softfloat_repo  =  ^<dir^>
  echo             telnet_repo     =  ^<dir^>
  echo.
  echo        The specified directory may be either relative or absolute.
  echo        Blank lines and lines beginning with "*", "#" or ";" are
  echo        ignored.
  echo.
  echo     AUTHOR
  echo.
  echo         "Fish" (David B. Trout)
  echo.
  echo     VERSION
  echo.
  echo         %_versnum%  (%_versdate%)
  echo.

  set /a "rc=1"
  set /a "maxrc=1"

  %EXIT%

::------------------------------------------------------------------------------
::                               EXIT
::------------------------------------------------------------------------------
:EXIT

  endlocal && exit /b %maxrc%

::------------------------------------------------------------------------------
::                               INIT
::------------------------------------------------------------------------------
:INIT

  set "TRACE=if defined DEBUG echo"

  set "return=goto :EOF"
  set "break=goto  :break"
  set "skip=goto   :skip"
  set "EXIT=goto   :EXIT"
  set "HELP=goto   :HELP"

  set /a "rc=0"
  set /a "maxrc=0"

  set "n0=%~n0"               && REM (our name only)
  set "nx0=%~nx0"             && REM (our name and extension)
  set "dp0=%~dp0"             && REM (our own drive and path only)
  set "dp0=%dp0:~0,-1%"       && REM (remove trailing backslash)
  set "nx0_cmdline=%0 %*"     && REM (save original cmdline used)

  echo.
  echo cmdline = %nx0_cmdline%
  echo.

  :: -----------------------------------------------
  ::  Check if CLONE or UPDATE and remove if found
  :: -----------------------------------------------

  set "action=BUILD"
  set "do_clone="
  set "do_update="
  set "need_git="

  if /i "%~1" == "clone" (
    set       "do_clone=1"
    set   "action=CLONE"
    set   "need_git=1"
    shift /1
  ) else (
    if /i "%~1" == "update" (
      set       "do_update=1"
      set   "action=UPDATE"
      set   "need_git=1"
      shift /1
    )
  )

  :: -----------------------------------------------
  ::  Check if help needed
  :: -----------------------------------------------

  if    "%~1" == ""       %HELP%
  if /i "%~1" == "/?"     %HELP%
  if /i "%~1" == "--help" %HELP%

  :: -----------------------------------------------
  ::  We need git if CLONE or UPDATE was requested
  :: -----------------------------------------------

  if defined need_git (

    call :fullpath "git.exe"  git.exe

    if not defined # (
      echo ERROR: "git.exe" not found. 1>&2
      set /a "maxrc=1"
      %EXIT%
    )

    set "git_url=https://github.com/SDL-Hercules-390"
  )

  goto :parse_args


::-----------------------------------------------------------------------------
::                             fullpath
::-----------------------------------------------------------------------------
:fullpath

  set "@=%path%"
  set "path=.;%path%"
  set "#=%~$PATH:1"
  set "path=%@%"
  if defined # (
    if not "%~2" == "" (
      set "%~2=%#%"
    )
  )
  %return%

::-----------------------------------------------------------------------------
::                       remove_trailing_slash
::-----------------------------------------------------------------------------
:remove_trailing_slash
  set "_1=%~1"
  set "_2=%~2"
:remove_trailing_slash_loop
  if not "%_1:~-1%" == "/" (
    if not "%_1:~-1%" == "\" (
      %break%
    )
  )
  set "_1=%_1:~0,-1%"
  goto :remove_trailing_slash_loop
:break
  if defined _2 set "%_2%=%_1%"
  %return%

::-----------------------------------------------------------------------------
::                             splitpath
::-----------------------------------------------------------------------------
:splitpath

  REM arg1 = input path, arg2 thru arg5 = VARNAMES for drv, dir, name,  .ext
  REM use '.' (period/dot) as placeholder for parts you're not interested in
  REM Also note that the path does NOT need to exist nor even be valid!
  REM Even invalid paths can be parsed and their components returned!

  if not "%~2" == "" (if not "%~2" == "." set "%~2=%~d1")
  if not "%~3" == "" (if not "%~3" == "." set "%~3=%~p1")
  if not "%~4" == "" (if not "%~4" == "." set "%~4=%~n1")
  if not "%~5" == "" (if not "%~5" == "." set "%~5=%~x1")

  %return%


::-----------------------------------------------------------------------------
::                              isfile
::-----------------------------------------------------------------------------
:isfile

  set "isfile=%~a1"
  if defined isfile (
    if /i "%isfile:~0,1%" == "d" set "isfile="
  )
  %return%


::-----------------------------------------------------------------------------
::                              isdir
::-----------------------------------------------------------------------------
:isdir

  set "isdir=%~a1"
  if defined isdir (
    if /i not "%isdir:~0,1%" == "d" set "isdir="
  )
  %return%

::-----------------------------------------------------------------------------
::                              tempfn
::-----------------------------------------------------------------------------
:tempfn

  setlocal
  set "var_name=%~1"
  set "file_ext=%~2"
  set "%var_name%="
  set "@="
  for /f "delims=/ tokens=1-3" %%a in ("%date:~4%") do (
    for /f "delims=:. tokens=1-4" %%d in ("%time: =0%") do (
      set "@=TMP%%c%%a%%b%%d%%e%%f%%g%random%%file_ext%"
    )
  )
  endlocal && set "%var_name%=%@%"
  %return%


::-----------------------------------------------------------------------------
::                             parse_args
::-----------------------------------------------------------------------------
:parse_args

  set "do_c="
  set "do_d="
  set "do_s="
  set "do_t="

:arg_loop

  if "%~1" == "" %break%

  :: -----------------------
  ::      c = crypto
  :: -----------------------

  if /i "%~1" == "c" (
    set       "do_c=1"
    shift /1
    goto :arg_loop
  )

  :: -----------------------
  ::     d = decNumber
  :: -----------------------

  if /i "%~1" == "d" (
    set       "do_d=1"
    shift /1
    goto :arg_loop
  )

  :: -----------------------
  ::     s = SoftFloat
  :: -----------------------

  if /i "%~1" == "s" (
    set       "do_s=1"
    shift /1
    goto :arg_loop
  )

  :: -----------------------
  ::      t = telnet
  :: -----------------------

  if /i "%~1" == "t" (
    set       "do_t=1"
    shift /1
    goto :arg_loop
  )

  :: -----------------------

  echo.
  echo ERROR: Invalid argument "%~1" 1>&2
  set "rc=1"

  %HELP%

:break

  :: ------------------------------------------------------
  ::  Now that we know which packages they want to CLONE,
  ::  UPDATE and/or BUILD, parse the ctlfile, ignoring
  ::  any statements for packages we're not interested in.
  :: ------------------------------------------------------

  set "ctlfile=%~nx0.ini"
  call :parse_ctlfile
  if %rc% NEQ 0 %HELP%

  :: ----------------------------------------
  ::  Make sure we found everything we need
  :: ----------------------------------------

                   if not defined install_dir    (set "rc=1" && echo.&& echo ERROR: install_dir undefined 1>&2)
  if defined do_c (if not defined crypto_repo    (set "rc=1" && echo.&& echo ERROR: crypto_repo undefined 1>&2))
  if defined do_d (if not defined decnumber_repo (set "rc=1" && echo.&& echo ERROR: decnumber_repo undefined 1>&2))
  if defined do_s (if not defined softfloat_repo (set "rc=1" && echo.&& echo ERROR: softfloat_repo undefined 1>&2))
  if defined do_t (if not defined telnet_repo    (set "rc=1" && echo.&& echo ERROR: telnet_repo undefined 1>&2))

  if %rc% NEQ 0 %HELP%

  :: -------------------------------------------------------
  ::  Log what we're about to do...
  :: -------------------------------------------------------

                    echo action         =  %action%
  if defined  do_c  echo crypto_repo    = "%crypto_repo%"
  if defined  do_d  echo decnumber_repo = "%decnumber_repo%"
  if defined  do_s  echo softfloat_repo = "%softfloat_repo%"
  if defined  do_t  echo telnet_repo    = "%telnet_repo%"
                    echo install_dir    = "%install_dir%"
  if defined  cpu   echo cpu            = "%cpu%"

  goto :%action%


::------------------------------------------------------------------------------
::                            parse_ctlfile
::------------------------------------------------------------------------------
:parse_ctlfile

  :: Make sure the file exists

  call :fullpath  "%ctlfile%"  ctlfile
  if not defined # goto :ctlfile_notfound

  call :isfile  "%ctlfile%"
  if not defined isfile goto :ctlfile_notfound

  :: Initialize variables

  call :get_default_cpu

  set "cpu="
  set "install_dir="
  set "crypto_repo="
  set "decnumber_repo="
  set "softfloat_repo="
  set "telnet_repo="

  :: Read and parse the control file, statement by statement...

  for /f "tokens=1,2,*" %%a in ('type "%ctlfile%"') do (
    call :parse_ctlfile_stmt "%%a" "%%b" "%%c"
  )

  :: Validate cpu

  if not defined cpu (
    set "cpu=%default_cpu%"
  )

  if /i not "%cpu%" == "%default_cpu%" (
    echo.
    echo ERROR: control file specifies "cpu = %cpu%" but actual cpu is "%default_cpu%" 1>&2
    set "rc=1"
  )

  %return%

:ctlfile_notfound

  echo.
  echo ERROR: Control file "%ctlfile%" not found 1>&2
  set "rc=1"
  %return%


::-----------------------------------------------------------------------------
::                           get_default_cpu
::-----------------------------------------------------------------------------
:get_default_cpu

  set "default_cpu="

  if /i "%PROCESSOR_ARCHITECTURE%" == "AMD64" set "default_cpu=x86"
  if /i "%PROCESSOR_ARCHITECTURE%" == "ARM64" set "default_cpu=arm"
  if /i "%PROCESSOR_ARCHITECTURE%" == "IA64"  set "default_cpu=unknown"

  if not defined default_cpu (
    set "default_cpu=x86"
  )
  %return%


::-----------------------------------------------------------------------------
::                           parse_ctlfile_stmt
::-----------------------------------------------------------------------------
:parse_ctlfile_stmt

  set "reponame=%~1"
  set "equals=%~2"
  set "repodir=%~3"

  set "firstchar=%reponame:~0,1%"

  if "%firstchar%" == "*" %return%
  if "%firstchar%" == "#" %return%
  if "%firstchar%" == ";" %return%

  if     "%reponame%" == ""  goto :parse_syntax
  if not "%equals%"   == "=" goto :parse_syntax
  if     "%repodir%"  == ""  goto :parse_syntax

  if /i "%reponame%" == "cpu"            goto :parse_cpu
  if /i "%reponame%" == "install_dir"    goto :parse_install_dir
  if /i "%reponame%" == "crypto_repo"    goto :parse_reponame
  if /i "%reponame%" == "decnumber_repo" goto :parse_reponame
  if /i "%reponame%" == "softfloat_repo" goto :parse_reponame
  if /i "%reponame%" == "telnet_repo"    goto :parse_reponame

:parse_syntax

  echo.
  echo ERROR: Invalid control file syntax: %reponame% %equals% %repodir% 1>&2
  set "rc=1"
  %return%

::-----------------
:parse_cpu
::-----------------

  if /i "%repodir%" == "aarch"   goto :parse_cpu_ok
  if /i "%repodir%" == "arm"     goto :parse_cpu_ok
  if /i "%repodir%" == "mips"    goto :parse_cpu_ok
  if /i "%repodir%" == "ppc"     goto :parse_cpu_ok
  if /i "%repodir%" == "sparc"   goto :parse_cpu_ok
  if /i "%repodir%" == "s390x"   goto :parse_cpu_ok
  if /i "%repodir%" == "xscale"  goto :parse_cpu_ok
  if /i "%repodir%" == "x86"     goto :parse_cpu_ok
  if /i "%repodir%" == "unknown" goto :parse_cpu_ok

  echo.
  echo ERROR: Invalid cpu: "%repodir%" 1>&2
  set "rc=1"
  %return%

:parse_cpu_ok

  set "cpu=%repodir%"
  %return%

::-----------------
:parse_install_dir
::-----------------

  call :fullpath  "%repodir%"  install_dir
  if not defined # goto :install_dir_notfound

  call :isdir  "%install_dir%"
  if not defined isdir goto :install_dir_not_dir

  REM Create base build directory if it doesn't exist

  set "build_dir=%install_dir%\build"

  call :fullpath  "%build_dir%"  build_dir
  if not defined # mkdir "%build_dir%"

  call :isdir  "%build_dir%"
  if not defined isdir (
    echo.
    echo ERROR: build_dir "%build_dir%" is not a directory 1>&2
    set "rc=1"
  )
  %return%

:install_dir_notfound

  echo.
  echo ERROR: install_dir "%repodir%" not found 1>&2
  set "rc=1"
  %return%

:install_dir_not_dir

  echo.
  echo ERROR: install_dir "%install_dir%" is not a directory 1>&2
  set "rc=1"
  %return%

::-----------------
:parse_reponame
::-----------------

  REM Ignore ctlfile statements for packages we're not interested in

  if /i "%reponame%" == "crypto_repo"    (if not defined do_c %return%)
  if /i "%reponame%" == "decnumber_repo" (if not defined do_d %return%)
  if /i "%reponame%" == "softfloat_repo" (if not defined do_s %return%)
  if /i "%reponame%" == "telnet_repo"    (if not defined do_t %return%)

  call :fullpath  "%repodir%"  repodir
  if not defined # goto :repodir_notfound

  call :isdir  "%repodir%"
  if not defined isdir goto :repodir_not_dir

  REM Remember this package's repository directory
  set "%reponame%=%repodir%"

  REM If they're NOT doing a clone, then all is well.  Otherwise
  REM if they ARE trying to do a clone, then that's an error. We
  REM can't do it since the repository has already been cloned!
  REM (The repository directory already exists!)

  if not defined do_clone %return%        && REM (not clone = OK)

  echo.
  echo ERROR: %reponame% "%repodir%" already exists 1>&2
  set "rc=1"
  %return%

:repodir_notfound

  REM The repository directory must obviously exist if we're doing
  REM an UPDATE or BUILD. Otherwise if we're doing a CLONE, then we
  REM expect the repository directory to not exist yet.

  if defined do_clone goto :repodir_check_clonedir

  echo.
  echo ERROR: %reponame% "%repodir%" not found 1>&2
  set "rc=1"
  %return%

:repodir_not_dir

  echo.
  echo ERROR: %reponame% "%repodir%" is not a directory 1>&2
  set "rc=1"
  %return%

:repodir_check_clonedir

  :: ------------------------------------------------------------------
  ::  They want to CREATE the repository directory via git clone.
  ::
  ::  Verify the path leading up to where the external package's
  ::  repository is supposed to be cloned into, is valid.
  ::
  ::  That is to say, if the repository directory is defined as
  ::  "C:\foobar\crypto-0", then verify the path "C:\foobar" exists
  ::  (where the git clone will will create the "crypto-0" directory).
  :: ------------------------------------------------------------------

  call :remove_trailing_slash  "%repodir%"             repodir2
  call :splitpath              "%repodir2%"            clonedrv clonedir clonename cloneext
  call :remove_trailing_slash  "%clonedrv%%clonedir%"  clonedir

  call :fullpath  "%clonedir%"  clonedir
  if not defined # goto :clonedir_notfound

:clonedir_found

  call :isdir  "%clonedir%"
  if not defined isdir goto :clonedir_not_dir

  set "%reponame%=%repodir%"
  set "%reponame%_clonedir=%clonedir%"
  set "%reponame%_clonename=%clonename%%cloneext%"

  %return%

:clonedir_notfound

  REM Try automatically creating the directory where
  REM the CLONE of the repository is supposed to go...

  mkdir "%clonedir%"
  call :fullpath  "%clonedir%"  clonedir
  if defined # goto :clonedir_found

  echo.
  echo ERROR: %reponame% clone directory "%clonedir%" not found 1>&2
  set "rc=1"
  %return%

:clonedir_not_dir

  echo.
  echo ERROR: %reponame% clone directory "%clonedir%" is not a directory 1>&2
  set "rc=1"
  %return%


::------------------------------------------------------------------------------
::                               CLONE
::------------------------------------------------------------------------------
:CLONE

  if defined  do_c  call :clone_pkg  "crypto"     "%crypto_repo_clonedir%"     "%crypto_repo_clonename%"
  if defined  do_d  call :clone_pkg  "decNumber"  "%decnumber_repo_clonedir%"  "%decnumber_repo_clonename%"
  if defined  do_s  call :clone_pkg  "SoftFloat"  "%softfloat_repo_clonedir%"  "%softfloat_repo_clonename%"
  if defined  do_t  call :clone_pkg  "telnet"     "%telnet_repo_clonedir%"     "%telnet_repo_clonename%"

  echo.

  if %maxrc% EQU 0 (
    echo All External Packages SUCCESSFULLY cloned!  :^)^)
  ) else (
    echo The clone of one or more External Packages FAILED!  :^(
  )

  echo.

  if %maxrc% EQU 0 goto :BUILD
  %EXIT%


::------------------------------------------------------------------------------
::                               UPDATE
::------------------------------------------------------------------------------
:UPDATE

  if defined  do_c  call :update_pkg   "crypto"      "%crypto_repo%"
  if defined  do_d  call :update_pkg   "decNumber"   "%decnumber_repo%"
  if defined  do_s  call :update_pkg   "SoftFloat"   "%softfloat_repo%"
  if defined  do_t  call :update_pkg   "telnet"      "%telnet_repo%"

  echo.

  if %maxrc% EQU 0 (
    echo All External Packages SUCCESSFULLY updated!  :^)^)
  ) else (
    echo The update of one or more External Packages FAILED!  :^(
  )

  echo.

  if %maxrc% EQU 0 goto :BUILD
  %EXIT%


::------------------------------------------------------------------------------
::                               BUILD
::------------------------------------------------------------------------------
:BUILD

  if defined  do_c  call :build_pkg   "crypto"      "%crypto_repo%"
  if defined  do_d  call :build_pkg   "decNumber"   "%decnumber_repo%"
  if defined  do_s  call :build_pkg   "SoftFloat"   "%softfloat_repo%"
  if defined  do_t  call :build_pkg   "telnet"      "%telnet_repo%"

  echo.

  if %maxrc% EQU 0 (
    echo All External Packages SUCCESSFULLY built!  :^)^)
    echo.
    echo Don't forget to update your 'LIB' and 'INCLUDE' variables to point to
    echo "%install_dir%\lib" and "%install_dir%\include" before building Hercules
    echo or use the '-extpkg ^"%install_dir%^"' option on your 'makefile.bat'
    echo command. ^(Using the environment variables technique is easier IMO.^)
  ) else (
    echo One or more External Packages has FAILED!  :^(
  )

  %EXIT%


::------------------------------------------------------------------------------
::                                clone_pkg
::------------------------------------------------------------------------------
:clone_pkg

  set "pkg_name=%~1"
  set "pkg_clonedir=%~2"
  set "pkg_clonename=%~3"

  pushd "%pkg_clonedir%"

    call :tempfn  tempfn  .txt
    "%git.exe%"  clone  "%git_url%/%pkg_name%.git"  "%pkg_clonename%"  >  "%tempfn%"  2>&1
    set /a "rc=%errorlevel%"

    REM The following is needed because "git" uses LF line endings instead or CRLF
    for /f "tokens=1* delims=]" %%a in ('type "%tempfn%" ^| find /V /N ""') do echo.%%b

    del "%tempfn%"

  popd

  if %rc% NEQ 0 (
    echo ERROR: clone of %pkg_name% to "%pkg_clonedir%\%pkg_clonename%" failed 1>&2
    set "maxrc=1"
  )
  %return%


::------------------------------------------------------------------------------
::                                update_pkg
::------------------------------------------------------------------------------
:update_pkg

  set "pkg_name=%~1"
  set "pkg_repo=%~2"

  pushd "%pkg_repo%"

    REM The following is needed because "git" uses LF line endings instead or CRLF
    call :tempfn  tempfn  .txt

    echo.
    "%git.exe%" pull > "%tempfn%" 2>&1
    set /a "rc=%errorlevel%"

    REM The following is needed because "git" uses LF line endings instead or CRLF
    for /f "tokens=1* delims=]" %%a in ('type "%tempfn%" ^| find /V /N ""') do echo.%%b
    del "%tempfn%"

  popd

  if %rc% NEQ 0 (
    echo ERROR: update of "%pkg_repo%" failed 1>&2
    set "maxrc=1"
  )
  %return%


::------------------------------------------------------------------------------
::                               build_pkg
::------------------------------------------------------------------------------
:build_pkg

  if %maxrc% NEQ 0 %return%

  set "pkg_name=%~1"
  set "pkg_repo=%~2"
  set "pkg_work=%build_dir%\%pkg_name%"

  echo %pkg_name% ...

  call :fullpath  "%pkg_repo%"  pkg_repo
  if not defined # (
    echo.
    echo ERROR: fullpath "%pkg_repo%" failed 1>&2
    set "maxrc=1"
  )

  REM Create package work directory if it doesn't exist

  call :fullpath  "%pkg_work%"  pkg_work
  if not defined # mkdir "%pkg_work%"

  call :isdir  "%pkg_work%"
  if not defined isdir goto :pkg_work_not_dir

  REM Delete previous log file!

  pushd   "%pkg_work%"
    if exist  "%pkg_name%.log" (
        del   "%pkg_name%.log"
    )
  popd

  if %maxrc% EQU 0 call :build_ext_pkg  64  Debug
  if %maxrc% EQU 0 call :build_ext_pkg  64  Release
  if %maxrc% EQU 0 call :build_ext_pkg  32  Debug
  if %maxrc% EQU 0 call :build_ext_pkg  32  Release

  %return%

:pkg_work_not_dir

  echo.
  echo   ERROR: pkg_work "%pkg_work%" is not a directory 1>&2
  set "rc=1"
  set "maxrc=1" && echo   FAILED!
  %return%


::------------------------------------------------------------------------------
::                              build_ext_pkg
::------------------------------------------------------------------------------
:build_ext_pkg

  set "pkg_arch=%~1"
  set "pkg_config=%~2"

  echo   %pkg_arch%-bit %pkg_config% ...

  pushd   "%pkg_work%"

    REM Append log file!

    if defined cpu (
      call "%pkg_repo%\build.cmd" --pkgname . --rebuild --cpu %cpu% --arch %pkg_arch% --config %pkg_config% --install "%install_dir%" >> "%pkg_name%.log" 2>&1
    ) else (
      call "%pkg_repo%\build.cmd" --pkgname . --rebuild             --arch %pkg_arch% --config %pkg_config% --install "%install_dir%" >> "%pkg_name%.log" 2>&1
    )

    set "rc=%errorlevel%"

    if %rc% EQU 0 (echo   SUCCESS!) else (set "maxrc=1" && echo   FAILED!)

  popd

  %return%

::-------------------------------- ( EOF ) -------------------------------------
