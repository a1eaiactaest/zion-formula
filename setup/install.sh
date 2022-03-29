#!/bin/bash


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


get_kernel_name
get_os

echo $os
