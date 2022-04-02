#!/usr/bin/env bash 

#set -e

trap ctrl_c INT

reset='\e[0m'

color() {
  case $1 in
    [0-6])    printf '%b\e[3%sm'   "$reset" "$1" ;;
    7 | "fg") printf '\e[37m%b'    "$reset" ;;
    *)        printf '\e[38;5;%bm' "$1" ;;
  esac
}

err() {
  err+="$(color 1)[!]${reset} $1
"
}

err_now() {
  err_now="$(color 1)[!]${reset} $1
"
  printf '%b\033[m' "$err_now" >&2
}

abort() {
  err_now "$@"
  exit 1
}

ctrl_c() {
  cleanup
  abort "Captured ctrl-c, cleaning up and aborting."
}


usage() { printf "%s" "\
Usage: install.sh --option 
Options:
  -h | --help       Print this help.
  -v | --verbose    Display error messages. 
  -vv | --VERBOSE   Display a verbose log and report all executed commands.
                    Read:
                    https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
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
  temp_dir=$(mktemp -t zion-temp.XXXXX -d)
  printf "$(color 2)[*]${reset} Created temporary dir at ${temp_dir}\n"
}

have_sudo_access() {
  if [[ ! -x "/usr/bin/sudo" ]]; then
    return 1
  fi

  local -a SUDO=("/usr/bin/sudo")
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    SUDO+=("-A")
  fi

  if [[ -z "${HAVE_SUDO_ACCES-}" ]]; then
    "${SUDO[@]}" -v && "${SUDO[@]}" -l mkdir &>/dev/null
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ $os == "macOS" ]] && [[ "${HAVE_SUDO_ACCESS}" -ne 0 ]]; then
    abort "Need sudo on macOS, user needes to be a system Administrator!"
  fi
}

make_installation_dir() {
  # creates ZION_PREFIX variable, which is where zion gateway binary will be installed
  case $os in
    "macOS"|"Mac OS X")
      if have_sudo_access; then
        if [[ $arch == "arm" ]]; then
          ZION_PREFIX="/opt/zion"
        else
          ZION_PREFIX="/usr/local"
        fi
      fi
    ;;
    "Linux")
      if have_sudo_access; then 
        ZION_PREFIX="/opt/zion"
      else
        ZION_PREFIX="${HOME}/.zion"
      fi
    ;;
  esac

  if have_sudo_access; then
    sudo mkdir -p $ZION_PREFIX
  elif [[ $os == "Linux" ]] && [[ "${HAVE_SUDO_ACCESS}" -ne 0 ]]; then
    mkdir -p $ZION_PREFIX
  fi
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
  get_kernel_name
  # $kernel_name is set in a function called get_kernel_name and is
  # just the output of "uname -s".
  case $kernel_name in
    Darwin*)   os=$darwin_name ;;
    SunOS)    os=Solaris ;;
    Haiku)    os=Haiku ;;
    MINIX)    os=MINIX ;;
    AIX)      os=AIX ;;
    IRIX*)    os=IRIX ;;
    FreeMiNT) os=FreeMiNT ;;

    Linux*|GNU*)
      os=Linux
    ;;

    *BSD|DragonFly|Bitrig)
      os=BSD
    ;;

    CYGWIN*|MSYS*|MINGW*)
      os=Windows
    ;;

    *)
      abort "Unknown OS detected: '$kernel_name', aborting..."
    ;;
esac

  if [[ $os != "Linux" ]] && [[ $os != "macOS" ]]; then
    abort "Only Linux and macOS are supported. Your current system is ${os}"
  fi
}

get_base() {
  case $os in 
    "Linux")
      for release_file in /etc/*-release; do
        source $release_file
        base=$ID_LIKE
      done
    ;;

    "Mac OS X"|"macOS")
      base="darwin"
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

        for file in /etc/lsb-release /usr/lib/os-release \
                    /etc/os-release  /usr/openwrt_release; do
          source "$file" && break
        done

      else
        for release_file in /etc/*-release; do
          distro+=$(< "$release_file")
        done
      fi
    ;;

    "Mac OS X"|"macOS")
      distro="${osx_version}"
    ;;
  esac

  get_base

  [[ $distro ]] || distro="$os (Unknown)"
}

get_arch() {
  arch=$(uname -p)
}

install_element() {
  case $os in
    "Linux") 
      case $base in
        "debian")
          if [ $( dpkg -W -f='${Status}' libsqlcipher0 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
            err_now "libsqlcipher0 is not installed."
            if have_sudo_access; then
              printf "$(color 2)[*]${reset} Installing libsqlcipher0...\n"
              sudo apt install libsqlcipher0
            else
              err_now "You have to be in sudoers file in order to install libsqlcipher0. Skipping installing Element."
              return 1
            fi
          fi

          element_version=$(curl -s https://packages.element.io/debian/pool/main/e/element-desktop/ \
                            | grep -Eo "_([0-9]).([0-9]|[1-9][0-9]).([0-9]|[1-9][0-9])_" \
                            | sort -Vr \
                            | head -n 1)

          element_filename="element-desktop${element_version}amd64.deb"
          if [ $( dpkg -W -f='${Staus}' element-dekstop 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
            err_now "Element not installed or not updated, installing the newest version."

            wget https://packages.element.io/debian/pool/main/e/element-desktop/$element_filename -P $temp_dir
            element_download_dir="${temp_dir}/${element_filename}" 
            echo "Element temporary download directory: $element_download_dir"

            printf "$(color 2)[*]${reset} Installing Element...\n"
            sudo dpkg -i $element_download_dir
            
          else
            printf "$(color 2)[*]${reset} Element is already installed.\n"
          fi
        ;;
        *)
          err_now "Only Debian and macOS are supported, your base is ${base}."
          return 1
        ;;
      esac
    ;;

    "Mac OS X"|"macOS")
      if [[ $(mdfind "kMDItemKind == 'Application'" | grep Element.app) -eq 0 ]]; then
        if [[ -x $(command -v brew) ]]; then
          brew install -q --cask element
        else
          err_now "homebrew is not installed, skipping..."
          return 1
        fi
      else
        err_now "Element is already installed."
      fi
    ;;
    *)
      err_now "Only Linux and macOS are supported, your OS is ${os}."
    ;;
  esac

}

install_zion() {
  zion_url="http://zion244k2d5snr6uao5mxukpacqbr4z25oaji5kegjw43ypd72pri3qd.onion/gateway.zip"
  zion_zip_sum="d30a420147346c76641e6ca6843dbcba31b70ff97315235130615d690b23c7ec"

  case $os in
    "Linux")
      case $base in
        "debian")
          if [[ $( dpkg -W -f='${Status}' tor 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
            err_now "tor is not installed, installing."
            if have_sudo_access; then
              sudo apt install tor
            else
              err_now "No sudo access. Aborting"
              abort
            fi
          fi
          if [[ $( dpkg -W -f='${Status}' golang-go 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
            err_now "golang is not installed, installing."
            if have_sudo_access; then
              sudo apt install golang-go
            else
              abort "No sudo access. Aborting"
            fi
          fi
        ;;
      esac
    ;;
    "macOS"|"Mac OS X")
      if [[ -x "$(command -v brew)" ]]; then
        if ! [[ -x "$(command -v tor)" ]]; then
          err_now "tor service not installed, installing"
          brew install -q tor
        fi

        if ! [[ -x "$(command -v go)" ]]; then
          err_now "golang is not installed, installing"
          brew install go
        fi
      else
        abort "homebrew is not installed"
      fi
    ;;
    *)
      abort "Only Linux and macOS are supported, your OS is ${os}."
    ;;
  esac

  # start tor in order to use socks5 proxy on port 9050
  tor --quiet &
  tor_PID=$! # this doesn't work no ones know why
  printf "$(color 2)[*]${reset} Starting tor service... (${tor_PID})\n" && sleep 2

  
  curl -s --socks5-hostname 127.0.0.1:9050 $zion_url >/dev/null
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then 
    printf "$(color 2)[*]${reset} Temporarily downloading zion-gateway into $temp_dir\n"

    curl -s --socks5-hostname 127.0.0.1:9050 $zion_url > $temp_dir/gateway.zip

    if [[ "$?" -eq 0 ]] && [[ -f "${temp_dir}/gateway.zip" ]] ; then
      printf "$(color 2)[*]${reset} Sucessfully downloaded gateway.zip file, extracting... \n"
    else
      cleanup
      abort "Error occured downloading gateway.zip file, aborting."
    fi

    downloaded_zip_sum=$(shasum -a 256 ${temp_dir}/gateway.zip | cut -d" " -f 1)

    printf "$(color 2)[*]${reset} Verifying checksums...\n"
    if [ $zion_zip_sum == $downloaded_zip_sum ]; then
      printf "Expected: $(color 2)${zion_zip_sum}${reset} \nCurrent:  $(color 2)${downloaded_zip_sum}${reset}\n"

      cd ${temp_dir}
      printf "$(color 2)[*]${reset} Installing...\n"
      sudo unzip -d $ZION_PREFIX gateway.zip
      printf "$(color 2)[*]${reset} Building...\n"
      
      cd $ZION_PREFIX
      sudo go mod download
      sudo go build zion-gateway.go
      if [[ -x "${ZION_PREFIX}/zion-gateway" ]]; then
        printf "$(color 2)[*]${reset} Installation at ${ZION_PREFIX} successful. \n"
      else
        sudo chmod gu+x $ZION_PREFIX/zion-gateway
      fi

    else
      printf "Expected: $(color 2)${zion_zip_sum}${reset} \nCurrent:  $(color 1)${downloaded_zip_sum}${reset}\n"
      cleanup
      abort "Checksum error."
    fi 
  else
    cleanup
    abort "Remote host seems down, make sure Zion Project .onion site is up! Aborting."
  fi
}

install() {
  make_temp_dir
  make_installation_dir
  
  read -p 'Install element? [y/N] ' -r -n 1 install_element 
  echo ""
  if [[ $install_element =~ ^[Yy]$ ]]; then
    install_element
  fi

  install_zion
  
  cleanup
}

cleanup() {
  printf "$(color 2)[*]${reset} Cleaning up..\n"
  rm -rf "${temp_dir}"
  
  printf "$(color 2)[*]${reset} Stopping tor service... (${tor_PID})\n"
  kill $tor_PID

  if [[ -z "$(ls -A ${ZION_PREFIX})" ]]; then
    sudo rm -rf $ZION_PREFIX
  fi
}

print_info() {
  printf "$(color 2)[*]${reset} System info:\n"
  echo "OS: ${os}"
  echo "Kernel: ${kernel_name}"
  echo "Distro: ${distro}"
  echo "Base: ${base}"
  echo "CPU: ${arch}"
}

main() {
  get_args "$@"

  get_os
  get_distro
  get_arch

  have_sudo_access

  if [[ $verbose == "on" ]]; then  
    print_info 
  fi

  install

  [[ $verbose == "on" ]] && printf '%b\033[m' "$err" >&2

  return 0
}

main "$@"
