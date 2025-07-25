#!/bin/bash

# Set up Android environment for WSL
export ANDROID_SDK_ROOT="/mnt/c/Users/paninfra/AppData/Local/Android/Sdk"
export PATH="/mnt/c/Users/paninfra/AppData/Local/Android/Sdk/platform-tools:$PATH"

echo "Checking for Android devices..."
adb.exe devices

echo "Starting Flutter app..."
flutter run
