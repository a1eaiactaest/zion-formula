# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Zion < Formula
  desc ""
  homepage "http://zion244k2d5snr6uao5mxukpacqbr4z25oaji5kegjw43ypd72pri3qd.onion/"
  url "http://zion244k2d5snr6uao5mxukpacqbr4z25oaji5kegjw43ypd72pri3qd.onion/gateway.zip"
  #version ""
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
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test zion`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
