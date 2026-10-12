#!/bin/bash

# build_release.sh - Build and package the DockTamer app for release
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$PROJECT_DIR/release"

echo "=== DockTamer Release Build ==="
echo "Project directory: $PROJECT_DIR"

# 1. Create release folder if it doesn't exist
if [ ! -d "$RELEASE_DIR" ]; then
    echo "Creating release directory: $RELEASE_DIR"
    mkdir -p "$RELEASE_DIR"
else
    echo "Release directory already exists: $RELEASE_DIR"
fi

# 2. Generate Xcode project using xcodegen
echo "Generating Xcode project..."
xcodegen generate

# 3. Build the project in Release configuration
echo "Building DockTamer in Release configuration..."
xcodebuild -project "$PROJECT_DIR/DockTamer.xcodeproj" \
           -scheme DockTamer \
           -configuration Release \
           -sdk macosx \
           clean build

# 4. Find the built app in DerivedData
DERIVED_DATA_DIR=$(xcodebuild -showBuildSettings -project "$PROJECT_DIR/DockTamer.xcodeproj" -scheme DockTamer -configuration Release 2>/dev/null | grep -A1 "DERIVED_DATA_DIR" | tail -n 1 | awk '{print $3}')

if [ -z "$DERIVED_DATA_DIR" ]; then
    # Fallback to known DerivedData path
    DERIVED_DATA_DIR="$HOME/Library/Developer/Xcode/DerivedData"
fi

BUILT_APP=$(find "$DERIVED_DATA_DIR" -name "DockTamer.app" -path "*/Release/*" -type d | head -n 1)

if [ -z "$BUILT_APP" ]; then
    echo "Error: Built app not found in DerivedData!"
    exit 1
fi

echo "Found built app: $BUILT_APP"

# 5. Copy the app to the release folder
echo "Copying app to release directory..."
mkdir -p "$RELEASE_DIR/DockTamer.app"
cp -R "$BUILT_APP/." "$RELEASE_DIR/DockTamer.app/"

echo "=== Release build completed ==="
echo "Release app location: $RELEASE_DIR/DockTamer.app"
