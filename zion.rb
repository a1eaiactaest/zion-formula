class Zion < Formula
  desc "Provides E2EE gateway to create secure communication"
  version "0.0.2"
  homepage "https://nullby1e.github.io/zion/"
  url "https://github.com/a1eaiactaest/zion-formula/releases/download/main/zion-0.0.2.tar.gz"
  sha256 "11d089faa1332743d4f02e199e244962fb770857fe6e2f577c2fe152f8f94e41"
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
