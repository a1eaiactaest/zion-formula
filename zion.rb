# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Zion < Formula
  version "0.0.1"
  desc ""
  homepage "http://zion244k2d5snr6uao5mxukpacqbr4z25oaji5kegjw43ypd72pri3qd.onion/"
  url "https://github.com/a1eaiactaest/zion-formula/releases/download/main/zion-0.0.1.tar.gz"
  sha256 "67195db8814ae805643692a5e9703c7b9cd3dea16f0c33cbef7f13a7ecf68064"
  license "WTFPL"
  
  depends_on "go" => :build
  depends_on "tor" => :build
  depends_on "unzip" => :build

  def install
    system "./configure"
    bin.install "zion-gateway"
  end

  test do
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    pipe_output("#{bin}/zion-gateway -h", 0)
  end
end
