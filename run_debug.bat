@echo off
echo Starting CommunityRun in debug mode...
echo.
echo Note: This must be run from Windows Command Prompt, not WSL
echo Make sure you have:
echo 1. Android Studio installed with Java/JDK
echo 2. Android emulator running or device connected  
echo 3. Flutter configured properly on Windows
echo.
pause
flutter clean
flutter pub get
flutter run --debug
pause