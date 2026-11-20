#!/bin/sh
# Prints the Homebrew cask for a Power Level release. Usage: scripts/make-cask.sh VERSION SHA256
set -eu
VERSION=$1
SHA=$2
cat <<CASK
cask "powerlevel" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/Stalin-uchiha7/PowerLevel/releases/download/v#{version}/PowerLevel-#{version}.zip"
  name "Power Level"
  desc "Menu bar monitor that shows CPU load as a scouter power level"
  homepage "https://github.com/Stalin-uchiha7/PowerLevel"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "PowerLevel.app"

  zap trash: "~/Library/Preferences/dev.powerlevel.app.plist"

  caveats <<~EOS
    Power Level is free and not notarized by Apple, so macOS blocks the first launch:
      1. Open Power Level once (it will be blocked).
      2. System Settings → Privacy & Security → "PowerLevel was blocked…" → Open Anyway.
  EOS
end
CASK
