#!/usr/bin/env bash
# Render static-site build script for Flutter web.
# Renders' build env has bash + git + curl + ~20GB disk on free tier.

set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.38.3}"
FLUTTER_DIR="$HOME/flutter"

echo "==> Installing Flutter $FLUTTER_VERSION"
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$PATH:$FLUTTER_DIR/bin"

flutter --version
flutter config --no-analytics

echo "==> Writing .env from Render env vars"
# API_BASE_URL comes from supertutor-api service host (no scheme by default).
API_URL="${API_BASE_URL:-}"
if [ -n "$API_URL" ] && [[ "$API_URL" != http* ]]; then
  API_URL="https://$API_URL"
fi
cat > .env <<EOF
API_BASE_URL=$API_URL
SUPABASE_URL=${SUPABASE_URL:-}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-}
EOF
cat .env

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build web --release"
flutter build web --release

echo "==> done"
ls -la build/web | head -20
