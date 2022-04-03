# Zion Installator

This used to be a formula for homebrew, but their requirements are very strict.  

Decided to make my own installation script. Check out [install.sh](./install.sh)!

## Deps

* libsqlicipher0 (Linux)
* golang 
* tor (service, not browser)
* Element client (optional)
* Homebrew (macOS)

All dependecies are installed with `install.sh`, except Homebrew. You either have to have it installed or install it your self.

## Installation

Run this in your terminal.

```
curl https://raw.githubusercontent.com/a1eaiactaest/zion-formula/master/install.sh | sh
```

## Docs

Zion is installed into `ZION_PREFIX` which on macOS is `/opt/zion` and `$HOME/.zion` on Linux.

Sudo access is required to install Zion.

Only Linux and macOS supported.

If you have any issues with installation please report them [here](https://github.com/a1eaiactaest/zion-formula/issues).

