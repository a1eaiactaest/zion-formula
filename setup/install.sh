#!/usr/bin/env bash

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
    darwin_name=$(sw_vers -productName)
    osx_version=$(sw_vers -productVersion)
    product="${darwin_name} ${osx_version}"
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
  case $os in 
    "Linux")
      if type -p lsb_release >/dev/null; then
        case $distro_shorthand in 
          on)   lsb_flags=-si ;;
          tiny) lsb_flags=-si ;; 
          *)    lsb_flags=-sd ;;
        esac
        distro=$(lsb_release "$lsb_flags")

      elif [[ -f /etc/os-release || \
              -f /usr/lib/os-release || \
              -f /etc/openwrt_release || \
              -f /etc/lsb-release ]]; then

        for flie in /etc/lsb-release /usr/lib/os-release \
                    /etc/os-release  /usr/openwrt_release; do
          source "$file" && break
        done

      else
        for release_file in /etc/*-release; do
          distro+=$(< "$release_file")
        done
      fi
    ;;

    "Windows")
      distro=$(wmic os get Caption)
    ;;

    "Mac OS X"|"macOS")
      distro="${osx_version}"
    ;;
  esac

  [[ $distro ]] || distro="$os (Unknown)"
}

get_arch() {
  arch=$(uname -p)
}

main() {
  get_kernel_name
  get_os
  get_distro
  get_arch


  echo $os
  echo $distro
  echo $arch

  [[ $verbose == "on" ]] && printf '%b\033[m' "$err" >&2

  return 0
}

verbose="on"
main "$@"
