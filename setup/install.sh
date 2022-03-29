#!/bin/bash

reset='\e[0m'

err() {
  err+="$(color 1)[!]${reset} $1
"
}

color() {
  case $1 in
    [0-6])    printf '%b\e[3%sm'   "$reset" "$1" ;;
    7 | "fg") printf '\e[37m%b'    "$reset" ;;
    *)        printf '\e[38;5;%bm' "$1" ;;
  esac
}

usage() { printf "%s" "\
Usage: install.sh --option 
Options:
  -h | --help       Print this help.
  -v | --verbose    Display error messages. 
  -vv | --VERBOSE   Display a verbose log and report all executed commands.
                    Read:
                    https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html#:~:text=they%20are%20read.-,%2Dx,-Print%20a%20trace
"
exit 1
}

get_args() {
  while [[ "$1" ]]; do
    case $1 in
      "-v" | "--verbose") verbose="on" ;;
      "-vv" | "--VERBOSE") set -x; verbose="on" ;; # print all executed commands (https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html)
      "-h" | "--help") usage ;;
    esac

    shift 

  done
}

get_kernel_name() {
  kernel_name=$(uname -s)

  if [[ $kernel_name == "Darwin" ]]; then
    productName=$(sw_vers -productName)
    productVersion=$(sw_vers -productVersion)
    darwin_name="${productName} ${productVersion}"
  fi

}

get_os() {
  # $kernel_name is set in a function called get_kernel_name and is
  # just the output of "uname -s".
  case $kernel_name in
    Darwin)   os=$darwin_name ;;
    SunOS)    os=Solaris ;;
    Haiku)    os=Haiku ;;
    MINIX)    os=MINIX ;;
    AIX)      os=AIX ;;
    IRIX*)    os=IRIX ;;
    FreeMiNT) os=FreeMiNT ;;

    Linux|GNU*)
      os=Linux
    ;;

    *BSD|DragonFly|Bitrig)
      os=BSD
    ;;

    CYGWIN*|MSYS*|MINGW*)
      os=Windows
    ;;

    *)
      printf '%s\n' "Unknown OS detected: '$kernel_name', aborting..." >&2
      exit 1
    ;;
esac
}

get_distro() {
  return 0
}


main() {
  get_kernel_name
  get_os


  #echo $os

  [[ $verbose == "on" ]] && printf '%b\033[m' "$err" >&2

  return 0
}

verbose="on"
main "$@"
