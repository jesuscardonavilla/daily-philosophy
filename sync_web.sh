#!/bin/sh
# Copies the web app into the Xcode project and enables full-screen safe-area support.
set -e
SRC="${1:-../philosophy/index.html}"
sed 's#<meta name="viewport" content="width=device-width, initial-scale=1">#<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">#' "$SRC" > DailyPhilosophy/Resources/index.html
echo "Copied $SRC to DailyPhilosophy/Resources/index.html"
