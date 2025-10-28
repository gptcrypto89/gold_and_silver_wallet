@echo off
REM Gold and Silver Wallet - Complete Setup and Run Script for Windows
REM Builds native libraries and runs the Flutter app on specified platform
REM Usage: start.bat --platform=<windows|ios|ios-simulator|android|android-simulator> [--skip-build]

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PLATFORM="
set "SKIP_BUILD=false"

REM Parse arguments
:parse_args
if "%~1"=="" goto check_platform
if "%~1"=="--platform=windows" (
    set "PLATFORM=windows"
    shift
    goto parse_args
)
if "%~1"=="--platform=ios" (
    set "PLATFORM=ios"
    shift
    goto parse_args
)
if "%~1"=="--platform=ios-simulator" (
    set "PLATFORM=ios-simulator"
    shift
    goto parse_args
)
if "%~1"=="--platform=android" (
    set "PLATFORM=android"
    shift
    goto parse_args
)
if "%~1"=="--platform=android-simulator" (
    set "PLATFORM=android-simulator"
    shift
    goto parse_args
)
if "%~1"=="--skip-build" (
    set "SKIP_BUILD=true"
    shift
    goto parse_args
)
echo Unknown argument: %~1
goto usage

:check_platform
if "%PLATFORM%"=="" goto usage

echo ========================================
echo Gold and Silver Wallet Setup and Launch
echo ========================================
echo.

REM Check for Flutter
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Warning: Flutter not found in PATH
    echo Adding Flutter to PATH from standard location...
    if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
        set "PATH=%PATH%;%USERPROFILE%\flutter\bin"
    ) else (
        echo Error: Flutter not found. Please install Flutter first.
        exit /b 1
    )
)

REM Build native libraries if needed
if "%SKIP_BUILD%"=="false" (
    echo Building secp256k1 native library for Windows...
    echo.
    
    set "SECP256K1_DIR=%SCRIPT_DIR%secp256k1"
    set "WRAPPER_DIR=%SCRIPT_DIR%secp256k1_wrapper\native"
    
    REM Check if library already exists
    if not exist "%WRAPPER_DIR%\windows\secp256k1.dll" (
        echo.
        echo ========================================
        echo Building secp256k1 for Windows
        echo ========================================
        echo.
        echo This requires:
        echo   - Visual Studio with C++ tools
        echo   - CMake
        echo   - Git
        echo.
        
        REM Clone secp256k1 if not exists
        if not exist "!SECP256K1_DIR!" (
            echo Cloning secp256k1 (tag v0.7.0)...
            git clone https://github.com/bitcoin-core/secp256k1.git "!SECP256K1_DIR!"
            cd /d "!SECP256K1_DIR!"
            git checkout v0.7.0
            cd /d "%SCRIPT_DIR%"
        )
        
        cd /d "!SECP256K1_DIR!"
        
        REM Create build directory
        if not exist "build" mkdir build
        cd build
        
        REM Configure with CMake
        echo Configuring build...
        cmake .. -DCMAKE_BUILD_TYPE=Release ^
                 -DSECP256K1_BUILD_TESTS=OFF ^
                 -DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF ^
                 -DSECP256K1_BUILD_BENCHMARK=OFF ^
                 -DSECP256K1_ENABLE_MODULE_RECOVERY=ON ^
                 -DSECP256K1_ENABLE_MODULE_ECDH=ON ^
                 -DSECP256K1_BUILD_SHARED=ON
        
        if %ERRORLEVEL% neq 0 (
            echo.
            echo Error: CMake configuration failed.
            echo Please install CMake and Visual Studio with C++ tools.
            echo.
            echo You can also manually build the library and place it in:
            echo   %WRAPPER_DIR%\windows\secp256k1.dll
            echo.
            pause
            exit /b 1
        )
        
        REM Build
        echo Building library...
        cmake --build . --config Release
        
        if %ERRORLEVEL% neq 0 (
            echo.
            echo Error: Build failed.
            echo Please check that Visual Studio C++ tools are installed.
            pause
            exit /b 1
        )
        
        REM Copy library
        if not exist "%WRAPPER_DIR%\windows" mkdir "%WRAPPER_DIR%\windows"
        if exist "Release\secp256k1.dll" (
            copy "Release\secp256k1.dll" "%WRAPPER_DIR%\windows\"
            echo Library built successfully
        ) else if exist "src\Release\secp256k1.dll" (
            copy "src\Release\secp256k1.dll" "%WRAPPER_DIR%\windows\"
            echo Library built successfully
        ) else (
            echo Error: Could not find built library
            echo Looking for: Release\secp256k1.dll or src\Release\secp256k1.dll
            pause
            exit /b 1
        )
        
        cd /d "%SCRIPT_DIR%"
    ) else (
        echo Windows library already exists
    )
    echo.
) else (
    echo Skipping native library build
    echo.
)

REM Navigate to Flutter project
cd /d "%SCRIPT_DIR%gold_and_silver_wallet"

echo Launching Gold and Silver Wallet on %PLATFORM%...
echo.

REM Platform-specific logic
if "%PLATFORM%"=="windows" goto :windows_platform
if "%PLATFORM%"=="ios" goto :ios_platform
if "%PLATFORM%"=="ios-simulator" goto :ios_simulator_platform
if "%PLATFORM%"=="android" goto :android_platform
if "%PLATFORM%"=="android-simulator" goto :android_simulator_platform
echo Error: Unknown platform: %PLATFORM%
exit /b 1

:windows_platform
REM Build and run Flutter app for Windows
flutter build windows --debug
if %ERRORLEVEL% neq 0 (
    echo Error: Flutter build failed
    pause
    exit /b 1
)

REM Copy library to build output
set "BUILD_DIR=%SCRIPT_DIR%gold_and_silver_wallet\build\windows\x64\runner\Debug"
set "LIB_SOURCE=%SCRIPT_DIR%secp256k1_wrapper\native\windows\secp256k1.dll"

if exist "%LIB_SOURCE%" (
    if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
    copy "%LIB_SOURCE%" "%BUILD_DIR%\"
)

REM Launch the app
start "" "%BUILD_DIR%\gold_and_silver_wallet.exe"
goto :end_platform

:ios_platform
REM List available iOS devices
echo Available iOS devices:
flutter devices | findstr /C:"mobile" /C:"tablet" | findstr /V "•"
echo.

REM Get device list and let user select
for /f "tokens=*" %%i in ('flutter devices ^| findstr /C:"mobile" /C:"tablet" ^| findstr /V "•" ^| findstr /C:"•"') do (
    set "DEVICE_LINE=%%i"
    echo   !DEVICE_LINE!
)

REM Simple device selection - use first available device
for /f "tokens=*" %%i in ('flutter devices ^| findstr /C:"mobile" /C:"tablet" ^| findstr /V "•" ^| findstr /C:"•" ^| findstr /C:"ios"') do (
    set "DEVICE_ID=%%i"
    goto :found_ios_device
)

echo Error: No iOS devices found. Please:
echo   1. Connect your iPhone via USB
echo   2. Trust this computer on your iPhone
echo   3. Enable Developer Mode in Settings ^> Privacy ^& Security
echo   4. Or use wireless debugging if already set up
pause
exit /b 1

:found_ios_device
echo Using device: !DEVICE_ID!
flutter run -d "!DEVICE_ID!"
goto :end_platform

:ios_simulator_platform
REM Start iOS Simulator if needed
flutter devices | findstr /C:"iOS" | findstr /V "•" >nul
if %ERRORLEVEL% neq 0 (
    echo Starting iOS Simulator...
    start "" "C:\Program Files\Xcode\Contents\Developer\Applications\Simulator.app"
    timeout /t 5 /nobreak >nul
)

REM Get first iOS simulator device
for /f "tokens=*" %%i in ('flutter devices ^| findstr /C:"iOS" ^| findstr /V "•" ^| findstr /C:"•"') do (
    set "DEVICE_ID=%%i"
    goto :found_ios_simulator
)

echo Error: No iOS simulator found
pause
exit /b 1

:found_ios_simulator
flutter run -d "!DEVICE_ID!"
goto :end_platform

:android_platform
REM List available Android devices
echo Available Android devices:
flutter devices | findstr /C:"mobile" /C:"tablet" | findstr /V "•"
echo.

REM Simple device selection - use first available device
for /f "tokens=*" %%i in ('flutter devices ^| findstr /C:"mobile" /C:"tablet" ^| findstr /V "•" ^| findstr /C:"android"') do (
    set "DEVICE_ID=%%i"
    goto :found_android_device
)

echo Error: No Android devices found. Please:
echo   1. Connect your Android device via USB
echo   2. Enable USB Debugging in Developer Options
echo   3. Trust this computer when prompted
echo   4. Or start an Android emulator
pause
exit /b 1

:found_android_device
echo Using device: !DEVICE_ID!
flutter run -d "!DEVICE_ID!"
goto :end_platform

:android_simulator_platform
REM Check for Android emulator
adb devices | findstr "emulator" >nul
if %ERRORLEVEL% neq 0 (
    echo Starting Android emulator...
    for /f "tokens=*" %%i in ('emulator -list-avds 2^>nul') do (
        set "EMULATOR_NAME=%%i"
        goto :start_emulator
    )
    echo Error: No Android emulator found. Please create one in Android Studio.
    pause
    exit /b 1
)

:start_emulator
start "" emulator -avd "!EMULATOR_NAME!"
adb wait-for-device
timeout /t 5 /nobreak >nul
flutter run
goto :end_platform

:end_platform
echo.
echo Gold and Silver Wallet is running!
goto :eof

:usage
echo Error: Platform not specified
echo Usage: start.bat --platform=<windows|ios|ios-simulator|android|android-simulator> [--skip-build]
echo.
echo Available platforms:
echo   - windows            : Run on Windows desktop
echo   - ios                : Run on iOS device (with device selection)
echo   - ios-simulator      : Run on iOS simulator
echo   - android            : Run on Android device (with device selection)
echo   - android-simulator  : Run on Android emulator
echo.
echo Options:
echo   --skip-build         : Skip building native libraries (if already built)
echo.
echo Note: For macOS and Linux, use start.sh
exit /b 1

