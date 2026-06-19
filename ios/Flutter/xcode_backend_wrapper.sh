#!/bin/sh
set -e

# hand_detection -> dartcv4 needs CMake during Flutter's native asset build.
# Xcode often runs with a minimal PATH that excludes Homebrew.
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

if [ -f "${SRCROOT}/Flutter/.xcode.env.local" ]; then
  # shellcheck disable=SC1091
  . "${SRCROOT}/Flutter/.xcode.env.local"
fi

exec /bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" "$@"
