@echo off
echo ================================
echo CLEANING FLUTTER CACHE...
echo ================================
flutter clean

echo.
echo ================================
echo GETTING DEPENDENCIES...
echo ================================
flutter pub get

echo.
echo ================================
echo BUILDING APK...
echo ================================
flutter build apk --release

echo.
echo ================================
echo BUILD COMPLETE!
echo ================================
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo.
pause

