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

make_temp_dir() {
  temp_dir=$(mktemp -t zion-temp -d)
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

install() {
  make_temp_dir

  # TODO: check if element is alread installed
  case $os in
    "Linux") # TODO: test
      case $distro in
        "Tails")
          if !( dpkg -l | grep libsqlcipher0 &> /dev/null); then
            err "libsqlcipher0 not installed, installing."
            sudo apt install libsqlcipher0
          fi

          element_version=$(curl -s https://packages.element.io/debian/pool/main/e/element-desktop/ \
                            | grep -Eo "_([0-9]).([0-9]|[1-9][0-9]).([0-9]|[1-9][0-9])_" \
                            | sort -Vr \
                            | head -n 1)
          
          element_filename="element-desktop${element_version}amd64.deb"
          wget https://packages.riot.im/debian/pool/main/e/element-desktop/$element_filename -P $temp_dir
          element_download_dir="${temp_dir}/${element_filename}"
          echo $element_download_dir
          # TODO: finish installation
        ;;
      esac
    ;;

    "Mac OS X"|"macOS")
      element_version=$(curl -s https://packages.element.io/desktop/install/macos/ \
                        | grep -Eo "Element-([0-9]).([0-9]|[1-9][0-9]).([0-9]|[1-9][0-9])" \
                        | sort -Vr \
                        | head -n 1)
      element_filename="${element_version}-universal.dmg" 
      wget https://packages.element.io/desktop/install/macos/$element_filename -P $temp_dir
      element_download_dir="${temp_dir}/${element_filename}"

      # mount .dmg file
      if hdiutil attach $element_download_dir >/dev/null; then
        mounted="true"
        element_mount_dir="/Volumes/${element_version}-universal/"
        cp -R $element_mount_dir/Element.app /Applications/
      elif
        mounted="false"
        err "Couldn't mount ${element_download_dir}. Aborting"
        exit 1
      fi
    ;;
  esac
}

cleanup() {
  rm $element_download_dir
  if [[ $mounted == "true" ]]; then
    hdiutil unmount $element_mound_dir
  fi
}

main() {
  get_kernel_name
  get_os
  get_distro
  get_arch

  install

  [[ $verbose == "on" ]] && printf '%b\033[m' "$err" >&2

  return 0
}

verbose="on"
main "$@"
