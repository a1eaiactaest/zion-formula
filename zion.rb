# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Zion < Formula
  desc ""
  homepage "http://zion244k2d5snr6uao5mxukpacqbr4z25oaji5kegjw43ypd72pri3qd.onion/"
  url "https://github.com/a1eaiactaest/zion-formula"
  version "0.0.1"
  sha256 "d30a420147346c76641e6ca6843dbcba31b70ff97315235130615d690b23c7ec"
  license "WTFPL"

  # depends_on "cmake" => :build
  
  depends_on "go" => :build
  depends_on "tor" => :build
  depends_on "unzip" => :build

  def install
    system "./configure"
  end

  test do
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    pipe_output("#{bin}/zion-gateway -h", 0)
  end
end
