#!/usr/bin/env bash

  #  If this bash script works then it was written by Fish.
  #  If it doesn't then I don't know who the heck wrote it.

  _versnum="1.6"
  _versdate="January 3, 2021"

#------------------------------------------------------------------------------
#                               EXTPKGS.SH
#------------------------------------------------------------------------------
HELP()
{
  errmsg ""
  errmsg "    NAME"
  errmsg ""
  errmsg "        $nx0   --   Build and install Hercules External Package(s)"
  errmsg ""
  errmsg "    SYNOPSIS"
  errmsg ""
  errmsg "        $nx0      { [CLONE | UPDATE]   [C]  [D]  [S]  [T] }"
  errmsg ""
  errmsg "    DESCRIPTION"
  errmsg ""
  errmsg "        $nx0 performs a full build and install of each specified"
  errmsg "        Hercules External Package.  It is used to automate the"
  errmsg "        cloning, updating and/or building and installing of all"
  errmsg "        selected External Packages with one simple command (rather"
  errmsg "        than having to perform each of the builds individually)"
  errmsg "        and ensures that each of them are built the same way."
  errmsg ""
  errmsg "    ARGUMENTS"
  errmsg ""
  errmsg "        CLONE      Indicates the specified package repositories do"
  errmsg "                   not exist yet and need to be git cloned before"
  errmsg "                   building.  This option, if specified, must come"
  errmsg "                   before the C|D|S|T option(s)."
  errmsg ""
  errmsg "        UPDATE     Indicates the specified package repositories"
  errmsg "                   should be git updated before building.  This"
  errmsg "                   option, if specified, must come before the"
  errmsg "                   C|D|S|T option(s)."
  errmsg ""
  errmsg "        C|D|S|T    Corresponds to which external package(s) you"
  errmsg "                   wish to clone, update and/or build and install"
  errmsg "                   (crypto, decNumber, SoftFloat and/or telnet,"
  errmsg "                   or all four, or any combination thereof)"
  errmsg ""
  errmsg "    EXIT STATUS"
  errmsg ""
  errmsg "        0   Success    All specified external packages built and"
  errmsg "                       successfully installed."
  errmsg ""
  errmsg "        1   Failure    The build or install of one or more of the"
  errmsg "                       specified packages has failed."
  errmsg ""
  errmsg "    NOTES"
  errmsg ""
  errmsg "        The required "${nx0}.ini" control file identifies the"
  errmsg "        fixed parameters needed by the script, and is expected to"
  errmsg "        exist somewhere in your search PATH."
  errmsg ""
  errmsg "        The control file must contain statements that identify the"
  errmsg "        directory of each external package's repository, as well"
  errmsg "        as the common installation directory where each package"
  errmsg "        will be installed into."
  errmsg ""
  errmsg "        The format of the statements is very simple:"
  errmsg ""
  errmsg "             cpu             =  aarch64|arm|e2k|mips|i686|ppc|s390x|sparc|x86|xscale|unknown"
  errmsg "             install_dir     =  <dir>"
  errmsg "             crypto_repo     =  <dir>"
  errmsg "             decnumber_repo  =  <dir>"
  errmsg "             softfloat_repo  =  <dir>"
  errmsg "             telnet_repo     =  <dir>"
  errmsg ""
  errmsg "        The specified directory may be either relative or absolute."
  errmsg "        Blank lines and lines beginning with '*', '#' or ';' are"
  errmsg "        ignored."
  errmsg ""
  errmsg "    AUTHOR"
  errmsg ""
  errmsg "        \"Fish\"  (David B. Trout)"
  errmsg ""
  errmsg "    VERSION"
  errmsg ""
  errmsg "        $_versnum     ($_versdate)"
  errmsg ""

  quit
}

#------------------------------------------------------------------------------
#                               quit
#------------------------------------------------------------------------------
quit()
{
  popd >/dev/null 2>&1
  exit $maxrc
}

#------------------------------------------------------------------------------
#                                  INIT
#------------------------------------------------------------------------------
init()
{
  pushd "." >/dev/null 2>&1
  maxrc=0
  rc=0

  #  Define some constants...

  dp0="$(dirname  "$0")"
  nx0="$(basename "$0")"

  x0="${nx0##*.}"
  n0="${nx0%.*}"

  nx0_cmdline="${nx0} $*"

  logmsg ""
  logmsg "cmdline = ${nx0_cmdline}"
  logmsg ""

  #------------------------------------------------
  #  Check if CLONE or UPDATE and remove if found
  #------------------------------------------------

  action="BUILD"
  do_clone=""
  do_update=""
  need_git=""

  push_shopt -s nocasematch

  if [[ $1 == "clone" ]]; then
            do_clone="1"
       action="CLONE"
    need_git="1"
    shift 1
  else
    if [[ $1 == "update" ]]; then
              do_update="1"
         action="UPDATE"
      need_git="1"
      shift 1
    fi
  fi

  #------------------------------------------------
  #  Check if HELP needed
  #------------------------------------------------

  if [[    -z   $1     ]]; then HELP; fi
  if [[ $1 == "?"      ]]; then HELP; fi
  if [[ $1 == "-?"     ]]; then HELP; fi
  if [[ $1 == "-h"     ]]; then HELP; fi
  if [[ $1 == "--help" ]]; then HELP; fi

  pop_shopt

  #------------------------------------------------
  #  We need git if CLONE or UPDATE was requested
  #------------------------------------------------

  if [[ -n $need_git ]]; then

    fullpath  "git"  git
    if [[ -z $fullpath ]]; then
      errmsg ""
      errmsg "ERROR: \"git\" not found"
      exit_rc1
    fi

    git_url="https://github.com/SDL-Hercules-390"

  fi

  parse_args  $@
}

#------------------------------------------------------------------------------
#                              push_shopt
#------------------------------------------------------------------------------
push_shopt()
{
  if [[ -z $shopt_idx ]]; then shopt_idx="-1"; fi
  shopt_idx=$(( $shopt_idx + 1 ))
  shopt_opt[ $shopt_idx ]=$2
  shopt -q $2
  shopt_val[ $shopt_idx ]=$?
  eval shopt $1 $2
}

#------------------------------------------------------------------------------
#                              pop_shopt
#------------------------------------------------------------------------------
pop_shopt()
{
  if [[ -n $shopt_idx ]] && (( $shopt_idx >= 0 )); then
    if (( ${shopt_val[ $shopt_idx ]} == 0 )); then
      eval shopt -s ${shopt_opt[ $shopt_idx ]}
    else
      eval shopt -u ${shopt_opt[ $shopt_idx ]}
    fi
    shopt_idx=$(( $shopt_idx - 1 ))
  fi
}

#------------------------------------------------------------------------------
#                               trace
#------------------------------------------------------------------------------
trace()
{
  if [[ -n $debug ]]  || \
     [[ -n $DEBUG ]]; then
    logmsg  "++ $1"
  fi
}

#------------------------------------------------------------------------------
#                               logmsg
#------------------------------------------------------------------------------
logmsg()
{
  stdmsg  "stdout"  "$1"
}

#------------------------------------------------------------------------------
#                               errmsg
#------------------------------------------------------------------------------
errmsg()
{
  stdmsg  "stderr"  "$1"
  set_rc1
}

#------------------------------------------------------------------------------
#                               stdmsg
#------------------------------------------------------------------------------
stdmsg()
{
  local  _stdxxx="$1"
  local  _msg="$2"

  push_shopt -s nocasematch

  if [[ $_stdxxx != "stdout" ]]  && \
     [[ $_stdxxx != "stderr" ]]; then
    _stdxxx=stdout
  fi

  if [[ $_stdxxx == "stdout" ]]; then
    echo "$_msg"
  else
    echo "$_msg" 1>&2
  fi

  pop_shopt
}

#------------------------------------------------------------------------------
#                           realpath_func
#------------------------------------------------------------------------------
realpath_func()
{
  # PROGRAMMING NOTE: does NOT check if file/directory actually exists or not!
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

#------------------------------------------------------------------------------
#                              exists
#------------------------------------------------------------------------------
exists()
{
  # Check if passed value is a directory that exists or a file that exists
  if [[ -e "$1" ]] || [[ -d "$1" ]]; then true; else false; fi
}

#------------------------------------------------------------------------------
#                              fullpath
#------------------------------------------------------------------------------
fullpath()
{
  # Upon return $fullpath will contain full path or empty string if not found.
  # If optional argument 2 is passed then that variable also set to $fullpath.

  # Determine if target is just a plain name or has directory components

  local dir=$(dirname "$1")

  if [[ -z "$dir" ]] || [[ $dir == "." ]]; then
    # only filename
    if exists "$1"; then
      fullpath=$(realpath_func "./$1")
    else
      # file doesn't exist in current directory
      # search each directory in $PATH variable
      fullpath=""
      while IFS=':' read -ra arPATHS; do
        for dir in "${arPATHS[@]}"; do
          if [[ -z $fullpath ]]; then
            if exists "$dir/$1"; then
              fullpath="$dir/$1"
            fi
          fi
        done
      done <<< "$PATH"
    fi
  else
    # has directory component(s); use as-is
    if exists "$1"; then
      fullpath=$(realpath_func "$1")
    else
      fullpath=""
    fi
  fi

  # If passed, assign results to the specified return variable too

  if [[ -n $fullpath ]] && [[ -n $2 ]]; then
    eval $2="\$fullpath"
  fi

  # Return true/false success/failure

  if [[ -n $fullpath ]]; then true; else false; fi
}

#------------------------------------------------------------------------------
#                           remove_trailing_slash
#------------------------------------------------------------------------------
remove_trailing_slash()
{
  local _1=${1%/}
  [[ -n "$2" ]] && eval "$2=\${_1}"
}

#------------------------------------------------------------------------------
#                              splitpath
#------------------------------------------------------------------------------
splitpath()
{
  # $1 = input path, $2 and $3 = VARNAMES for dirname, basename
  # use '.' (period/dot) as placeholder for parts not interested in
  # Also note that the path does NOT need to exist nor even be valid!
  # Even invalid paths can be parsed and their components returned!

  local _1="$(dirname  "$1")"
  local _2="$(basename "$1")"

  [[ -n $2 ]] && [[ $2 != "." ]] && eval $2="\${_1}"
  [[ -n $3 ]] && [[ $3 != "." ]] && eval $3="\${_2}"
}

#------------------------------------------------------------------------------
#                              isfile
#------------------------------------------------------------------------------
isfile()
{
  # if isfile "xxx"; then echo "is file"; else echo "NOT file"; fi
  if [[ -f $1 ]]; then isfile="1"; true; else isfile=""; false; fi
}

#------------------------------------------------------------------------------
#                               isdir
#------------------------------------------------------------------------------
isdir()
{
  # if isdir "xxx"; then echo "is directory"; else echo "NOT directory"; fi
  if [[ -d $1 ]]; then isdir="1"; true; else isdir=""; false; fi
}

#------------------------------------------------------------------------------
#                               trim
#------------------------------------------------------------------------------
trim()
{
  # trim  "$foo"  foo

  push_shopt -s extglob         # (enable globbing)
    local trim="$1"
    trim="${trim##*( )}"        # (trim leading  whitespace)
    trim="${trim%%*( )}"        # (trim trailing whitespace)
  pop_shopt                     # (restore globbing)
  eval "$2='${trim}'"           # (pass back results)
}

#------------------------------------------------------------------------------
#                             parse_args
#------------------------------------------------------------------------------
parse_args()
{
  do_c=""
  do_d=""
  do_s=""
  do_t=""

  push_shopt -s nocasematch

  while [[  -n  $1  ]]; do

    case $1 in

      c) do_c="1" ;;
      d) do_d="1" ;;
      s) do_s="1" ;;
      t) do_t="1" ;;

      *)
        errmsg ""
        errmsg "ERROR: unrecognized/unsupported argument \"$1\""
        exit_rc1
        ;;

    esac

    shift 1

  done

  #---------------------------------------------------------
  #  Now that we know which packages they want to CLONE,
  #  UPDATE and/or BUILD, parse the ctlfile, ignoring
  #  any statements for packages we're not interested in.
  #---------------------------------------------------------

  ctlfile="${nx0}.ini"
  parse_ctlfile
  if (( $rc != 0 )); then HELP; fi

  #------------------------------------------
  #  Make sure we found everything we need
  #------------------------------------------

                    [[ -n $install_dir    ]] || errmsg "ERROR: install_dir undefined"
  [[ -z $do_c ]] || [[ -n $crypto_repo    ]] || errmsg "ERROR: crypto_repo undefined"
  [[ -z $do_d ]] || [[ -n $decnumber_repo ]] || errmsg "ERROR: decnumber_repo undefined"
  [[ -z $do_s ]] || [[ -n $softfloat_repo ]] || errmsg "ERROR: softfloat_repo undefined"
  [[ -z $do_t ]] || [[ -n $telnet_repo    ]] || errmsg "ERROR: telnet_repo undefined"

  if (( $maxrc != 0 )); then
    HELP
  fi

  #------------------------------------------
  #  Log what we're about to do...
  #------------------------------------------

                              logmsg "action         =  ${action}"
  [[ -n $crypto_repo    ]] && logmsg "crypto_repo    = \"${crypto_repo}\""
  [[ -n $decnumber_repo ]] && logmsg "decnumber_repo = \"${decnumber_repo}\""
  [[ -n $softfloat_repo ]] && logmsg "softfloat_repo = \"${softfloat_repo}\""
  [[ -n $telnet_repo    ]] && logmsg "telnet_repo    = \"${telnet_repo}\""
                              logmsg "install_dir    = \"${install_dir}\""
  [[ -n $cpu            ]] && logmsg "cpu            = \"${cpu}\""


  ${action}   # (perform requested action)
}

#------------------------------------------------------------------------------
#                          parse_ctlfile
#------------------------------------------------------------------------------
parse_ctlfile()
{
  # Make sure the file exists

  fullpath  "${ctlfile}"  ctlfile
  if [[ -z $fullpath ]]; then
    errmsg ""
    errmsg "ERROR: ctlfile \"${ctlfile}\" not found"
    exit_rc1
  fi

  isfile  "${ctlfile}"
  if [[ -z $isfile ]]; then
    errmsg ""
    errmsg "ERROR: \"${ctlfile}\" is not a file"
    exit_rc1
  fi

  # Initialize variables

  get_default_cpu

  cpu=""
  install_dir=""
  crypto_repo=""
  decnumber_repo=""
  softfloat_repo=""
  telnet_repo=""

  # Read and parse the control file, statement by statement...

  while  read -r  CTLFILE_STMT
  do
    if [ -n    "${CTLFILE_STMT}" ]; then
      parse_ctlfile_stmt
    fi
  done < "${ctlfile}"

  # Validate cpu

  if [[ -z $cpu ]]; then
    cpu="${default_cpu}"
  fi

  if [[ $cpu != "${default_cpu}" ]]; then
    errmsg ""
    errmsg "ERROR: control file specifies \"cpu = ${cpu}\" but actual cpu is \"${default_cpu}\""
    exit_rc1
  fi
}

#------------------------------------------------------------------------------
#                             get_default_cpu
#------------------------------------------------------------------------------
get_default_cpu()
{
  case "$(uname -m)" in

    aarch64*)
      default_cpu="aarch64"
      ;;

    amd*)
      default_cpu="x86"
      ;;

    arm64*)
      default_cpu="aarch64"
      ;;

    arm*)
      default_cpu="arm"
      ;;

    e2k*)
      default_cpu="e2k"
      ;;

    i686*)
      default_cpu="i686"
      ;;

    mips*)
      default_cpu="mips"
      ;;

    ppc*)
      default_cpu="ppc"
      ;;

    sparc*)
      default_cpu="sparc"
      ;;

    s390x*)
      default_cpu="s390x"
      ;;

    xscale*)
      default_cpu="xscale"
      ;;

    x86*)
      default_cpu="x86"
      ;;

    *)
      default_cpu="unknown"
      ;;

  esac
}

#------------------------------------------------------------------------------
#                           parse_ctlfile_stmt
#------------------------------------------------------------------------------
parse_ctlfile_stmt()
{
  local ARRAY=()
  IFS='=' read -ra ARRAY <<< "${CTLFILE_STMT}"

  reponame="${ARRAY[0]}"
  repodir="${ARRAY[1]}"

  trim "${reponame}" reponame
  trim "${repodir}"  repodir

  # Ignore lines that start with '#', '*' or ';'

  if [[ ${reponame:0:1} == "#" ]] || \
     [[ ${reponame:0:1} == "*" ]] || \
     [[ ${reponame:0:1} == ";" ]]; then
    return
  fi

  if [[ -z $reponame ]] || [[ -z $repodir ]]; then
    errmsg ""
    errmsg "ERROR: Invalid ctlfile syntax: \"${CTLFILE_STMT}\""
    exit_rc1
  fi

  case "$reponame" in

    install_dir)

      fullpath  "${repodir}"  repodir
      isdir     "${repodir}"
      if [[ -z $fullpath ]] || [[ -z $isdir ]]; then
        repodir_not_found "install_dir"
      fi
      install_dir="${repodir}"

      # Create base build directory if it doesn't exist

      build_dir="${install_dir}/build"

      fullpath  "${build_dir}"  build_dir
      if [[ -z $fullpath ]]; then
        mkdir -p "${build_dir}"
      fi

      isdir "${build_dir}"
      if [[ -z $isdir ]]; then
        repodir="${build_dir}"
        repodir_not_found "build_dir"
      fi
      ;;

    crypto_repo | decnumber_repo | softfloat_repo | telnet_repo)

      # Ignore ctlfile statements for packages we're not interested in
      if ignore_reponame ${reponame}; then return; fi

      fullpath "${repodir}" repodir
      if [[ -z $fullpath ]]; then
        repodir_not_found "${reponame}"
        return
      fi

      isdir "${repodir}"
      if [[ -z $isdir ]]; then
        repodir_not_dir "${reponame}"
      fi

      # Remember this package's repository directory
      eval ${reponame}="\${repodir}"

      # If they're NOT doing a clone, then all is well.  Otherwise
      # if they ARE trying to do a clone, then that's an error. We
      # can't do it since the repository has already been cloned!
      # (The repository directory already exists!)

      if [[ -n $do_clone ]]; then
        errmsg ""
        errmsg "ERROR: ${reponame} \${repodir}\" already exists"
        exit_rc1
      fi
      ;;

    cpu)

      case "$repodir" in

        aarch64 | arm | e2k | i686 | mips | ppc | sparc | s390x | xscale | x86 | unknown)

          cpu="${repodir}"
          ;;

        *)

          errmsg ""
          errmsg "ERROR: Invalid cpu: \"${repodir}\""
          exit_rc1
          ;;

      esac
      ;;

    *)

      errmsg ""
      errmsg "ERROR: Invalid ctlfile syntax: \"${CTLFILE_STMT}\""
      exit_rc1
      ;;

  esac
}

#------------------------------------------------------------------------------
#                          ignore_reponame
#------------------------------------------------------------------------------
ignore_reponame()
{
  # Ignore ctlfile statements for packages we're not interested in.
  # Boolean: returns success == 0 (true) or failure == 1 (false)

  if [[ $1 == "crypto_repo"    ]] && [[ -z $do_c ]]; then return 0; else return 1; fi
  if [[ $1 == "decnumber_repo" ]] && [[ -z $do_d ]]; then return 0; else return 1; fi
  if [[ $1 == "softfloat_repo" ]] && [[ -z $do_s ]]; then return 0; else return 1; fi
  if [[ $1 == "telnet_repo"    ]] && [[ -z $do_t ]]; then return 0; else return 1; fi

  return 1    # (failure == 1 == false)
}

#------------------------------------------------------------------------------
#                          repodir_not_dir
#------------------------------------------------------------------------------
repodir_not_dir()
{
  errmsg ""
  errmsg "ERROR: $1 \"${repodir}\" is not a directory"
  exit_rc1
}

#------------------------------------------------------------------------------
#                          repodir_not_found
#------------------------------------------------------------------------------
repodir_not_found()
{
  # If we're doing an UPDATE or BUILD, the repository directory
  # must obviously exist.  If we're doing a CLONE however, then
  # we expect the repository directory to not exist yet.

  if [[ -z $do_clone ]]; then
    errmsg ""
    errmsg "ERROR: $1 \"${repodir}\" not found"
    exit_rc1
  fi

  #------------------------------------------------------------------
  # They want to CREATE the repository directory via git clone.
  #
  # Verify the path leading up to where the external package's
  # repository is supposed to be cloned into, is valid.
  #
  # That is to say, if the repository directory is defined as
  # "C:\foobar\crypto-0", then verify the path "C:\foobar" exists
  # (where the git clone will will create the "crypto-0" directory).
  #------------------------------------------------------------------

  remove_trailing_slash  "${repodir}"  repodir2
  splitpath  "${repodir2}"  dirname    basename
  remove_trailing_slash  "${dirname}"  clonedir

  fullpath "${clonedir}"  clonedir
  if [[ -z $fullpath ]]; then
    clonedir_notfound "${reponame}"
  fi

  clonedir_found
}

#------------------------------------------------------------------------------
#                          clonedir_notfound
#------------------------------------------------------------------------------
clonedir_notfound()
{
  # Try automatically creating the directory where
  # the CLONE of the repository is supposed to go...

  mkdir -p "${clonedir}" >/dev/null 2>&1
  fullpath "${clonedir}"  clonedir

  if [[ -z $fullpath ]]; then
    errmsg ""
    errmsg "ERROR: $1 clone directory \"${clonedir}\" not found"
    exit_rc1
  fi

  clonedir_found
}

#------------------------------------------------------------------------------
#                          clonedir_found
#------------------------------------------------------------------------------
clonedir_found()
{
  isdir "${clonedir}"
  if [[ -z $isdir ]]; then
    clonedir_not_dir "${reponame}"
  fi

  eval ${reponame}="\${repodir}"
  eval ${reponame}_clonedir="\${clonedir}"
  eval ${reponame}_clonename="\${basename}"
}

#------------------------------------------------------------------------------
#                          clonedir_not_dir
#------------------------------------------------------------------------------
clonedir_not_dir()
{
  errmsg ""
  errmsg "ERROR: $1 clone directory \"${clonedir}\" is not a directory"
  exit_rc1
}

#-------------------------------------------------------------------------------
#                              CLONE
#-------------------------------------------------------------------------------
CLONE()
{
  [[ -n $do_c ]] && clone_pkg  "crypto"     "${crypto_repo_clonedir}"     "${crypto_repo_clonename}"
  [[ -n $do_d ]] && clone_pkg  "decNumber"  "${decnumber_repo_clonedir}"  "${decnumber_repo_clonename}"
  [[ -n $do_s ]] && clone_pkg  "SoftFloat"  "${softfloat_repo_clonedir}"  "${softfloat_repo_clonename}"
  [[ -n $do_t ]] && clone_pkg  "telnet"     "${telnet_repo_clonedir}"     "${telnet_repo_clonename}"

  logmsg ""

  if (( $maxrc == 0 )); then
    logmsg "All External Packages SUCCESSFULLY cloned!  :))"
  else
    logmsg "The clone of one or more External Packages FAILED!  :("
    quit
  fi

  logmsg ""
  BUILD
}

#-------------------------------------------------------------------------------
#                              UPDATE
#-------------------------------------------------------------------------------
UPDATE()
{
  [[ -n $do_c ]] && update_pkg  "crypto"     "${crypto_repo}"
  [[ -n $do_d ]] && update_pkg  "decNumber"  "${decnumber_repo}"
  [[ -n $do_s ]] && update_pkg  "SoftFloat"  "${softfloat_repo}"
  [[ -n $do_t ]] && update_pkg  "telnet"     "${telnet_repo}"

  logmsg ""

  if (( $maxrc == 0 )); then
    logmsg "All External Packages SUCCESSFULLY updated!  :))"
  else
    logmsg "The update of one or more External Packages FAILED!  :("
    quit
  fi

  logmsg ""
  BUILD
}

#-------------------------------------------------------------------------------
#                              BUILD
#-------------------------------------------------------------------------------
BUILD()
{
  [[ -n $do_c ]] && build_pkg  "crypto"     "${crypto_repo}"
  [[ -n $do_d ]] && build_pkg  "decNumber"  "${decnumber_repo}"
  [[ -n $do_s ]] && build_pkg  "SoftFloat"  "${softfloat_repo}"
  [[ -n $do_t ]] && build_pkg  "telnet"     "${telnet_repo}"

  logmsg ""

  if (( $maxrc == 0 )); then
    logmsg "All External Packages SUCCESSFULLY built!  :))"
    logmsg ""
    logmsg "Don't forget to update your 'LIBRARY_PATH' and 'CPATH' variables to"
    logmsg "point to '${install_dir}/lib' and '${install_dir}/include' before"
    logmsg "building Hercules, or else use the '--enable-extpkgs=${install_dir}'"
    logmsg "option on your './configure' command."
    logmsg ""
  else
    logmsg "One or more External Packages has FAILED!  :("
  fi

  quit
}

#-------------------------------------------------------------------------------
#                              clone_pkg
#-------------------------------------------------------------------------------
clone_pkg()
{
  pkg_name="$1"
  pkg_clonedir="$2"
  pkg_clonename="$3"

  pushd "${pkg_clonedir}" >/dev/null 2>&1
    "${git}"  clone  "${git_url}/${pkg_name}.git"  "${pkg_clonename}"  2>&1
    rc=$?
  popd >/dev/null 2>&1

  if (( $rc != 0 )); then
    errmsg "ERROR: clone of ${pkg_name} to \"${pkg_clonedir}/${pkg_clonename}\" failed"
  fi
}

#-------------------------------------------------------------------------------
#                              update_pkg
#-------------------------------------------------------------------------------
update_pkg()
{
  pkg_name="$1"
  pkg_repo="$2"

  pushd "${pkg_repo}" >/dev/null 2>&1
    logmsg ""
    "${git}" pull 2>&1
    rc=$?
  popd >/dev/null 2>&1

  if (( $rc != 0 )); then
    errmsg "ERROR: update of ${pkg_repo} failed"
  fi
}

#-------------------------------------------------------------------------------
#                             build_pkg
#-------------------------------------------------------------------------------
build_pkg()
{
  if (( $maxrc != 0 )); then
    return
  fi

  pkg_name="$1"
  pkg_repo="$2"
  pkg_work="${build_dir}/${pkg_name}"

  logmsg "${pkg_name} ..."

  fullpath "${pkg_repo}" pkg_repo
  if [[ -z $fullpath ]]; then
    errmsg "ERROR: fullpath pkg_repo \"${pkg_repo}\" failed"
    exit_rc1
  fi

  # Create package work directory if it doesn't exist

  fullpath "${pkg_work}" pkg_work
  if [[ -z $fullpath ]]; then
    mkdir -p "${pkg_work}" >/dev/null 2>&1
  fi
  isdir "${pkg_work}"
  if [[ -z $isdir ]]; then
    logmsg ""
    logmsg "  ERROR: pkg_work \"${pkg_work}\" is not a directory"
    logmsg "  FAILED!"
    set_rc1
    return
  fi

  # Delete previous log file!

  pushd "${pkg_work}" >/dev/null 2>&1
    # Delete previous log file!
    isfile  "${pkg_name}.log"
    [[ -n $isfile ]] && rm "${pkg_name}.log"
  popd >/dev/null 2>&1

  want_32bit=1
  want_64bit=1

  # Don't build BOTH for i686
  if [[ $cpu == "i686" ]]; then
    logmsg "Skipping 64-bit builds on i686"
    want_64bit=0
  fi

  # Don't build BOTH for arm or aarch64
  if [[ $cpu == "arm" ]]; then
    logmsg "Skipping 64-bit builds on arm"
    want_64bit=0
  fi

  if [[ $cpu == "aarch64" ]]; then
    logmsg "  Skipping 32-bit builds on aarch64"
    want_32bit=0
  fi

  # Don't build BOTH for e2k
  if [[ $cpu == "e2k" ]]; then
    logmsg "Skipping 32-bit builds on e2k"
    want_32bit=0
  fi
  (( want_64bit == 1 )) && (( $maxrc == 0 )) && build_ext_pkg  "64"  "Debug"
  (( want_64bit == 1 )) && (( $maxrc == 0 )) && build_ext_pkg  "64"  "Release"
  (( want_32bit == 1 )) && (( $maxrc == 0 )) && build_ext_pkg  "32"  "Debug"
  (( want_32bit == 1 )) && (( $maxrc == 0 )) && build_ext_pkg  "32"  "Release"
}

#-------------------------------------------------------------------------------
#                            build_ext_pkg
#-------------------------------------------------------------------------------
build_ext_pkg()
{
  pkg_arch="$1"
  pkg_config="$2"

  logmsg "  ${pkg_arch}-bit ${pkg_config} ..."

  pushd "${pkg_work}" >/dev/null 2>&1
    # Append log file!
    "${pkg_repo}/build" --pkgname . --rebuild --cpu ${cpu} --arch ${pkg_arch} --config ${pkg_config} --install "${install_dir}" >> "${pkg_name}.log" 2>&1
    rc=$?
  popd >/dev/null 2>&1

  if (( $rc == 0 )); then
    logmsg "  SUCCESS!"
  else
    logmsg "  FAILED!"
    set_rc1
  fi
}

#------------------------------------------------------------------------------
#                              exit_rc1
#------------------------------------------------------------------------------
exit_rc1()
{
  set_rc1
  quit
}

#------------------------------------------------------------------------------
#                               set_rc1
#------------------------------------------------------------------------------
set_rc1()
{
  rc=1
  update_maxrc
}

#------------------------------------------------------------------------------
#                             update_maxrc
#------------------------------------------------------------------------------
update_maxrc()
{
  # Note: maxrc remains negative once it's negative.

  if (( $maxrc >= 0 )); then
    if (( $rc < 0 )); then
      maxrc=$rc
    else
      if (( $rc > 0 )); then
        if (( $rc > $maxrc )); then
          maxrc=$rc
        fi
      fi
    fi
  fi
}

#-------------------------------------------------------------------------------
#                                MAIN
#------------------------------------------------------------------------------

init  $@

#-------------------------------------------------------------------------------
