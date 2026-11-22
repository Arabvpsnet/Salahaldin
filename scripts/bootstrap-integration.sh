#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(git rev-parse --show-toplevel)"
if [ -e mobile/pubspec.yaml ] && [ -e tv/package.json ] && [ -e server/composer.json ]; then
  echo "Source import already exists, skipping."; exit 0
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git clone --depth 1 https://github.com/HydraaLabs/salatime_app.git "$work/mobile"
git clone --depth 1 https://github.com/filinodz/sakina.git "$work/tv"
git clone --depth 1 https://github.com/HydraaLabs/salatime.git "$work/server"
git -C "$work/mobile" checkout b418b217287d81915d59fe75d1ac05c8a2fa4aac
git -C "$work/tv" checkout b5fcb673910902e0a73f280048c09a6686af2d11
git -C "$work/server" checkout b3596745537f9d58291df8b94f37d0c5b54eea10
mkdir -p mobile tv server
rsync -a --exclude '.git/' --exclude '.github/' --exclude 'play-store/' --exclude 'build/' --exclude '.dart_tool/' --exclude '*.jks' --exclude '*.keystore' --exclude 'google-services.json' --exclude 'GoogleService-Info.plist' "$work/mobile/" mobile/
rsync -a --exclude '.git/' --exclude '.github/' --exclude 'landing/' --exclude 'build/' "$work/tv/" tv/
rsync -a --exclude '.git/' --exclude '.github/' --exclude 'vendor/' --exclude '.env' --exclude '.DS_Store' --exclude 'node_modules/' --exclude 'storage/logs/' "$work/server/" server/
python3 scripts/adapt_integrations.py
git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
git add mobile tv server shared
git commit -m "Import SalaTime mobile/API and Sakina TV with Salahaldin adaptations"
git push origin HEAD:integration/salatime-sakina-multilingual
