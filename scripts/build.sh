#!/bin/bash
set -e

osascript -e 'quit app "AgentRadar"' 2>/dev/null || true

xcodebuild \
  -project AgentRadar.xcodeproj \
  -scheme AgentRadar \
  -configuration Debug \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  -derivedDataPath build \
  build 2>&1 | grep -E "error:|warning:|BUILD" | tail -30

APP_PATH="build/Build/Products/Debug/AgentRadar.app"
rm -rf /Applications/AgentRadar.app
cp -R "$APP_PATH" /Applications/AgentRadar.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/AgentRadar.app
open /Applications/AgentRadar.app
