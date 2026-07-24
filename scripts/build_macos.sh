#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

flutter pub get
flutter analyze
flutter test
flutter build macos --release

echo "GRADE OPERA criado em build/macos/Build/Products/Release/grade_opera.app"
