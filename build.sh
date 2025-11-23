#!/bin/bash
set -e

echo "🚀 Starting Flutter build for Vercel..."

# Install Flutter using fvm or direct installation
echo "📦 Installing Flutter..."

# Check if Flutter is already in PATH
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found, installing..."
  
  # Install Flutter SDK
  FLUTTER_SDK_PATH="$HOME/flutter"
  
  if [ ! -d "$FLUTTER_SDK_PATH" ]; then
    echo "Downloading Flutter SDK (this may take a few minutes)..."
    git clone --branch stable https://github.com/flutter/flutter.git "$FLUTTER_SDK_PATH" --depth 1
  fi
  
  export PATH="$FLUTTER_SDK_PATH/bin:$PATH"
  
  # Accept licenses
  flutter doctor --android-licenses || true
fi

# Verify Flutter installation
echo "Flutter version:"
flutter --version

# Enable web support (if not already enabled)
flutter config --enable-web || true

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Build web
echo "🔨 Building Flutter web app..."
flutter build web --release --web-renderer canvaskit

echo "✅ Build completed successfully!"

