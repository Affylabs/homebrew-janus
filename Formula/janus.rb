class Janus < Formula
  desc "Server management tool with CLI and web interface"
  homepage "https://janus.dev"
  version "1.0.0"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/Affylabs/homebrew-janus/releases/download/v1.0.0/janus-darwin-arm64.tar.gz"
      sha256 "da2f5a86516a143028a393d9ff45ada59b1ec8444024fd799655f6a2ffe5de1d"
    end
    on_intel do
      odie "Janus requires Apple Silicon. Intel Macs are not supported."
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/Affylabs/homebrew-janus/releases/download/v1.0.0/janus-linux-arm64.tar.gz"
      sha256 "e8ba41252b67cac9508c1f33546c7f59de669ecc998bbaac06ea6cc3ac0ffee9"
    end
    on_intel do
      url "https://github.com/Affylabs/homebrew-janus/releases/download/v1.0.0/janus-linux-amd64.tar.gz"
      sha256 "4e7d2664708295021fe2f03c840623da9d839d69abc429093ee1db29ffe7c1bb"
    end
  end

  def install
    bin.install "janus"
  end

  def caveats
    <<~EOS
      Get started:

        janus init      # Create your encrypted vault
        janus import    # Import from ~/.ssh/config
        janus web       # Start the web interface
    EOS
  end

  test do
    assert_match "janus version", shell_output("#{bin}/janus version")
  end
end
