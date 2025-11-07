#!/bin/bash

# Gold and Silver Wallet - Complete Setup and Run Script
# Builds native libraries and runs the Flutter app on specified platform
# Usage: ./start.sh --platform=<macos|ios|ios-simulator|android|android-simulator|linux|windows>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLATFORM=""
SKIP_BUILD=false
DEBUG=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --platform=*)
            PLATFORM="${arg#*=}"
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --debug=true)
            DEBUG=true
            shift
            ;;
        --debug=false)
            DEBUG=false
            shift
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: ./start.sh --platform=<macos|ios|ios-simulator|android|android-simulator|linux|windows> [--skip-build] [--debug]"
            exit 1
            ;;
    esac
done

# Check if platform is provided
if [ -z "$PLATFORM" ]; then
    echo "❌ Error: Platform not specified"
    echo "Usage: ./start.sh --platform=<macos|ios|ios-simulator|android|android-simulator|linux|windows> [--skip-build] [--debug]"
    echo ""
    echo "Available platforms:"
    echo "  - macos              : Run on macOS desktop"
    echo "  - ios                : Run on iOS device (with device selection)"
    echo "  - ios-simulator      : Run on iOS simulator"
    echo "  - android            : Run on Android device (with device selection)"
    echo "  - android-simulator  : Run on Android emulator"
    echo "  - linux              : Run on Linux desktop"
    echo "  - windows            : Run on Windows desktop (use start.bat instead)"
    echo ""
    echo "Options:"
    echo "  --skip-build         : Skip building native libraries (if already built)"
    echo "  --debug              : Enable debug logging (default: false)"
    exit 1
fi

echo "🚀 Gold and Silver Wallet Setup and Launch"
echo "=================================="
echo ""

# Show debug status
if [ "$DEBUG" = true ]; then
    echo "🐛 Debug logging: ENABLED"
    echo "   - API requests and responses will be logged"
    echo "   - Error details will be shown in dialogs"
    echo "   - Verbose Flutter output enabled"
    echo ""
else
    echo "🐛 Debug logging: DISABLED"
    echo "   - Use --debug flag to enable detailed logging"
    echo ""
fi

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "⚠️  Flutter not found in PATH"
    echo "Cloning Flutter SDK..."
    
    FLUTTER_DIR="$SCRIPT_DIR/flutter"
    
    # Clone Flutter if not exists
    if [ ! -d "$FLUTTER_DIR" ]; then
        echo "📥 Cloning Flutter SDK..."
        git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
    fi
    
    # Add Flutter to PATH
    export PATH="$PATH:$FLUTTER_DIR/bin"
    
    if ! command -v flutter &> /dev/null; then
        echo "❌ Error: Flutter not found after cloning."
        exit 1
    fi
fi

# Check for Linux build dependencies
if [ "$PLATFORM" = "linux" ] && [ "$SKIP_BUILD" = false ]; then
    MISSING_DEPS=()
    if ! command -v autoconf &> /dev/null; then
        MISSING_DEPS+=("autoconf")
    fi
    if ! command -v automake &> /dev/null; then
        MISSING_DEPS+=("automake")
    fi
    if ! command -v libtool &> /dev/null; then
        MISSING_DEPS+=("libtool")
    fi
    if ! command -v make &> /dev/null; then
        MISSING_DEPS+=("build-essential")
    fi
    
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        echo "❌ Missing required build dependencies for Linux:"
        for dep in "${MISSING_DEPS[@]}"; do
            echo "   - $dep"
        done
        echo ""
        echo "💡 Please install them with:"
        echo "   sudo apt-get update"
        echo "   sudo apt-get install -y ${MISSING_DEPS[*]}"
        echo ""
        echo "Then run this script again."
        exit 1
    fi
fi

# Build native libraries if needed
if [ "$SKIP_BUILD" = false ]; then
    echo "🔧 Building secp256k1 native libraries..."
    echo ""
    
    SECP256K1_DIR="$SCRIPT_DIR/secp256k1"
    WRAPPER_DIR="$SCRIPT_DIR/secp256k1_wrapper/native"
    
    # Clone secp256k1 if not exists
    if [ ! -d "$SECP256K1_DIR" ]; then
        echo "📥 Cloning secp256k1 from bitcoin-core (tag v0.7.0)..."
        git clone https://github.com/bitcoin-core/secp256k1.git "$SECP256K1_DIR"
        cd "$SECP256K1_DIR"
        git checkout v0.7.0
        cd "$SCRIPT_DIR"
    fi
    
    cd "$SECP256K1_DIR" || {
        echo "❌ Failed to change to secp256k1 directory: $SECP256K1_DIR"
        exit 1
    }
    
    # Generate configure script if needed
    if [ ! -f "configure" ]; then
        echo "🔨 Generating build configuration..."
        if [ ! -f "autogen.sh" ]; then
            echo "❌ autogen.sh not found in $SECP256K1_DIR"
            exit 1
        fi
        
        # Make autogen.sh executable
        chmod +x autogen.sh
        
        # Check for required tools
        if ! command -v autoconf &> /dev/null; then
            echo "⚠️  Warning: autoconf not found. Install with: sudo apt-get install autoconf"
        fi
        if ! command -v automake &> /dev/null; then
            echo "⚠️  Warning: automake not found. Install with: sudo apt-get install automake"
        fi
        if ! command -v libtool &> /dev/null; then
            echo "⚠️  Warning: libtool not found. Install with: sudo apt-get install libtool"
        fi
        
        # Run autogen.sh
        ./autogen.sh || {
            echo "❌ Failed to generate configure script"
            echo "💡 Make sure you have autotools installed: sudo apt-get install autoconf automake libtool"
            exit 1
        }
        
        # Verify configure was created
        if [ ! -f "configure" ]; then
            echo "❌ configure script was not created after running autogen.sh"
            echo "💡 Check the output above for errors. You may need to install autotools."
            exit 1
        fi
        
        # Make configure executable
        chmod +x configure
    fi
    
    # Common configuration
    COMMON_FLAGS="--enable-module-recovery --disable-tests --disable-benchmark --disable-exhaustive-tests"
    
    # Determine which libraries to build based on platform
    case $PLATFORM in
        macos)
            if [ ! -f "$WRAPPER_DIR/macos/libsecp256k1.dylib" ]; then
                echo "🍎 Building for macOS..."
                ./configure $COMMON_FLAGS --prefix="$SCRIPT_DIR/build/macos"
                make clean > /dev/null 2>&1
                make -j$(sysctl -n hw.ncpu)
                make install
                mkdir -p "$WRAPPER_DIR/macos"
                cp "$SCRIPT_DIR/build/macos/lib/libsecp256k1.dylib" "$WRAPPER_DIR/macos/"
                echo "✓ macOS library built"
            else
                echo "✓ macOS library already exists"
            fi
            ;;
            
        ios|ios-simulator)
            if [ ! -f "$WRAPPER_DIR/ios/libsecp256k1.dylib" ]; then
                echo "📱 Building for iOS Simulator..."
                export CFLAGS="-arch arm64 -mios-simulator-version-min=12.0 -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path)"
                export LDFLAGS="-arch arm64 -mios-simulator-version-min=12.0 -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path)"
                ./configure $COMMON_FLAGS --host=aarch64-apple-darwin --prefix="$SCRIPT_DIR/build/ios-simulator"
                make clean > /dev/null 2>&1
                make -j$(sysctl -n hw.ncpu)
                make install
                unset CFLAGS LDFLAGS
                mkdir -p "$WRAPPER_DIR/ios"
                cp "$SCRIPT_DIR/build/ios-simulator/lib/libsecp256k1.dylib" "$WRAPPER_DIR/ios/"
                echo "✓ iOS Simulator library built"
            else
                echo "✓ iOS Simulator library already exists"
            fi
            
            if [ "$PLATFORM" = "ios" ] && [ ! -f "$WRAPPER_DIR/ios-device/libsecp256k1.dylib" ]; then
                echo "📱 Building for iOS Device..."
                export CFLAGS="-arch arm64 -mios-version-min=12.0 -isysroot $(xcrun --sdk iphoneos --show-sdk-path)"
                export LDFLAGS="-arch arm64 -mios-version-min=12.0 -isysroot $(xcrun --sdk iphoneos --show-sdk-path)"
                ./configure $COMMON_FLAGS --host=aarch64-apple-darwin --prefix="$SCRIPT_DIR/build/ios-device"
                make clean > /dev/null 2>&1
                make -j$(sysctl -n hw.ncpu)
                make install
                unset CFLAGS LDFLAGS
                mkdir -p "$WRAPPER_DIR/ios-device"
                cp "$SCRIPT_DIR/build/ios-device/lib/libsecp256k1.dylib" "$WRAPPER_DIR/ios-device/"
                echo "✓ iOS Device library built"
            fi
            ;;
            
        android|android-simulator)
            # Check for Android NDK
            NDK_PATH=""
            if [ -n "$ANDROID_NDK_HOME" ]; then
                NDK_PATH="$ANDROID_NDK_HOME"
            elif [ -n "$ANDROID_NDK" ]; then
                NDK_PATH="$ANDROID_NDK"
            elif [ -d "$HOME/Library/Android/sdk/ndk" ]; then
                NDK_PATH="$HOME/Library/Android/sdk/ndk/$(ls -1 $HOME/Library/Android/sdk/ndk | sort -V | tail -1)"
            fi
            
            if [ -z "$NDK_PATH" ] || [ ! -d "$NDK_PATH" ]; then
                echo "❌ Android NDK not found. Please install Android Studio with NDK."
                exit 1
            fi
            
            echo "🤖 Building for Android..."
            declare -A ANDROID_ARCHS=(
                ["arm64-v8a"]="aarch64-linux-android"
                ["armeabi-v7a"]="armv7a-linux-androideabi"
                ["x86_64"]="x86_64-linux-android"
                ["x86"]="i686-linux-android"
            )
            
            ANDROID_API=21
            TOOLCHAIN="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64"
            
            for ARCH in "${!ANDROID_ARCHS[@]}"; do
                if [ ! -f "$WRAPPER_DIR/android/jniLibs/$ARCH/libsecp256k1.so" ]; then
                    HOST="${ANDROID_ARCHS[$ARCH]}"
                    echo "  Building for $ARCH..."
                    
                    export CC="$TOOLCHAIN/bin/${HOST}${ANDROID_API}-clang"
                    export CXX="$TOOLCHAIN/bin/${HOST}${ANDROID_API}-clang++"
                    export AR="$TOOLCHAIN/bin/llvm-ar"
                    export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
                    export STRIP="$TOOLCHAIN/bin/llvm-strip"
                    
                    ./configure $COMMON_FLAGS --host="$HOST" --prefix="$SCRIPT_DIR/build/android-$ARCH"
                    make clean > /dev/null 2>&1
                    make -j$(sysctl -n hw.ncpu) > /dev/null 2>&1
                    make install > /dev/null 2>&1
                    
                    mkdir -p "$WRAPPER_DIR/android/jniLibs/$ARCH"
                    cp "$SCRIPT_DIR/build/android-$ARCH/lib/libsecp256k1.so" "$WRAPPER_DIR/android/jniLibs/$ARCH/"
                    
                    unset CC CXX AR RANLIB STRIP
                fi
            done
            echo "✓ Android libraries built"
            ;;
            
        linux)
            if [ ! -f "$WRAPPER_DIR/linux/libsecp256k1.so" ]; then
                echo "🐧 Building for Linux..."
                cd "$SECP256K1_DIR" || {
                    echo "❌ Failed to change to secp256k1 directory: $SECP256K1_DIR"
                    exit 1
                }
                
                # Ensure configure script exists (should already be generated above, but double-check)
                if [ ! -f "configure" ]; then
                    echo "🔨 Configure script not found, generating..."
                    if [ ! -f "autogen.sh" ]; then
                        echo "❌ autogen.sh not found in $SECP256K1_DIR"
                        exit 1
                    fi
                    chmod +x autogen.sh
                    ./autogen.sh || {
                        echo "❌ Failed to generate configure script"
                        echo "💡 Make sure you have autotools installed: sudo apt-get install autoconf automake libtool"
                        exit 1
                    }
                    if [ ! -f "configure" ]; then
                        echo "❌ configure script was not created"
                        exit 1
                    fi
                    chmod +x configure
                fi
                
                # Verify configure is executable and exists
                if [ ! -x "./configure" ]; then
                    echo "⚠️  Configure script is not executable, fixing..."
                    chmod +x ./configure
                fi
                
                if [ ! -f "./configure" ]; then
                    echo "❌ Configure script not found in $SECP256K1_DIR"
                    echo "Current directory: $(pwd)"
                    echo "Files in directory: $(ls -la | head -20)"
                    exit 1
                fi
                
                ./configure $COMMON_FLAGS --prefix="$SCRIPT_DIR/build/linux" || {
                    echo "❌ Configure failed"
                    exit 1
                }
                make clean > /dev/null 2>&1
                make -j$(nproc) || {
                    echo "❌ Build failed"
                    exit 1
                }
                make install || {
                    echo "❌ Install failed"
                    exit 1
                }
                mkdir -p "$WRAPPER_DIR/linux"
                cp "$SCRIPT_DIR/build/linux/lib/libsecp256k1.so" "$WRAPPER_DIR/linux/" || {
                    echo "❌ Failed to copy library"
                    exit 1
                }
                echo "✓ Linux library built"
            else
                echo "✓ Linux library already exists"
            fi
            ;;
    esac
    
    cd "$SCRIPT_DIR"
    echo ""
else
    echo "⏭️  Skipping native library build"
    echo ""
fi

# Navigate to Flutter project
cd "$SCRIPT_DIR/gold_and_silver_wallet"

echo "📱 Launching Gold and Silver Wallet on $PLATFORM..."
echo ""

case $PLATFORM in
    macos)
        # Build the app (same process for both debug and release)
        if [ "$DEBUG" = true ]; then
            echo "🔧 Building macOS app in debug mode..."
            flutter build macos --debug --verbose
        else
            echo "🔧 Building macOS app..."
            flutter build macos --debug
        fi
        
        # Bundle library (same for both modes)
        APP_FRAMEWORKS="$SCRIPT_DIR/gold_and_silver_wallet/build/macos/Build/Products/Debug/gold_and_silver_wallet.app/Contents/Frameworks"
        LIB_SOURCE="$SCRIPT_DIR/secp256k1_wrapper/native/macos/libsecp256k1.dylib"
        
        if [ -f "$LIB_SOURCE" ]; then
            mkdir -p "$APP_FRAMEWORKS"
            cp "$LIB_SOURCE" "$APP_FRAMEWORKS/"
            install_name_tool -id "@executable_path/../Frameworks/libsecp256k1.dylib" "$APP_FRAMEWORKS/libsecp256k1.dylib"
            echo "✓ Native library bundled successfully"
        else
            echo "⚠️  Warning: Native library not found at $LIB_SOURCE"
        fi
        
        # Open the app
        if [ "$DEBUG" = true ]; then
            echo "🚀 Opening app in debug mode (logs will be shown in terminal)"
            # Run the app and show logs
            "$SCRIPT_DIR/gold_and_silver_wallet/build/macos/Build/Products/Debug/gold_and_silver_wallet.app/Contents/MacOS/gold_and_silver_wallet" &
            # Show logs in terminal
            echo "📱 App is running! Check the app window for the interface."
            echo "🔍 Debug logs will appear below:"
            wait
        else
            echo "🚀 Opening app..."
            open "$SCRIPT_DIR/gold_and_silver_wallet/build/macos/Build/Products/Debug/gold_and_silver_wallet.app"
        fi
        ;;
        
    ios)
        # List available iOS devices
        echo "📱 Available iOS devices:"
        flutter devices | grep -E "(mobile|tablet)" | grep -v "•" | while read line; do
            echo "  $line"
        done
        echo ""
        
        # Get device list and let user select
        DEVICES=$(flutter devices | grep -E "(mobile|tablet)" | grep -v "•" | awk '{print $NF}' | tr -d '()')
        DEVICE_COUNT=$(echo "$DEVICES" | wc -l | tr -d ' ')
        
        if [ "$DEVICE_COUNT" -eq 0 ]; then
            echo "❌ No iOS devices found. Please:"
            echo "  1. Connect your iPhone via USB"
            echo "  2. Trust this computer on your iPhone"
            echo "  3. Enable Developer Mode in Settings > Privacy & Security"
            echo "  4. Or use wireless debugging if already set up"
            exit 1
        elif [ "$DEVICE_COUNT" -eq 1 ]; then
            DEVICE_ID="$DEVICES"
            echo "📱 Using device: $DEVICE_ID"
        else
            echo "📱 Multiple devices found. Please select:"
            echo "$DEVICES" | nl -w2 -s': '
            echo ""
            read -p "Enter device number (1-$DEVICE_COUNT): " DEVICE_NUM
            
            if ! [[ "$DEVICE_NUM" =~ ^[0-9]+$ ]] || [ "$DEVICE_NUM" -lt 1 ] || [ "$DEVICE_NUM" -gt "$DEVICE_COUNT" ]; then
                echo "❌ Invalid selection. Using first device."
                DEVICE_ID=$(echo "$DEVICES" | head -1)
            else
                DEVICE_ID=$(echo "$DEVICES" | sed -n "${DEVICE_NUM}p")
            fi
            echo "📱 Selected device: $DEVICE_ID"
        fi
        
        if [ "$DEBUG" = true ]; then
            flutter run -d "$DEVICE_ID" --debug --verbose
        else
            flutter run -d "$DEVICE_ID"
        fi
        ;;
        
    ios-simulator)
        DEVICE_ID=$(flutter devices | grep "iOS" | grep -v "•" | head -1 | awk '{print $NF}' | tr -d '()')
        if [ -z "$DEVICE_ID" ]; then
            echo "Starting simulator..."
            open -a Simulator
            sleep 5
            DEVICE_ID=$(flutter devices | grep "iOS" | grep -v "•" | head -1 | awk '{print $NF}' | tr -d '()')
        fi
        if [ "$DEBUG" = true ]; then
            flutter run -d "$DEVICE_ID" --debug --verbose
        else
            flutter run -d "$DEVICE_ID"
        fi
        ;;
        
    android)
        # List available Android devices
        echo "🤖 Available Android devices:"
        flutter devices | grep -E "(mobile|tablet)" | grep -v "•" | while read line; do
            echo "  $line"
        done
        echo ""
        
        # Get device list and let user select
        DEVICES=$(flutter devices | grep -E "(mobile|tablet)" | grep -v "•" | awk '{print $NF}' | tr -d '()')
        DEVICE_COUNT=$(echo "$DEVICES" | wc -l | tr -d ' ')
        
        if [ "$DEVICE_COUNT" -eq 0 ]; then
            echo "❌ No Android devices found. Please:"
            echo "  1. Connect your Android device via USB"
            echo "  2. Enable USB Debugging in Developer Options"
            echo "  3. Trust this computer when prompted"
            echo "  4. Or start an Android emulator"
            exit 1
        elif [ "$DEVICE_COUNT" -eq 1 ]; then
            DEVICE_ID="$DEVICES"
            echo "🤖 Using device: $DEVICE_ID"
        else
            echo "🤖 Multiple devices found. Please select:"
            echo "$DEVICES" | nl -w2 -s': '
            echo ""
            read -p "Enter device number (1-$DEVICE_COUNT): " DEVICE_NUM
            
            if ! [[ "$DEVICE_NUM" =~ ^[0-9]+$ ]] || [ "$DEVICE_NUM" -lt 1 ] || [ "$DEVICE_NUM" -gt "$DEVICE_COUNT" ]; then
                echo "❌ Invalid selection. Using first device."
                DEVICE_ID=$(echo "$DEVICES" | head -1)
            else
                DEVICE_ID=$(echo "$DEVICES" | sed -n "${DEVICE_NUM}p")
            fi
            echo "🤖 Selected device: $DEVICE_ID"
        fi
        
        if [ "$DEBUG" = true ]; then
            flutter run -d "$DEVICE_ID" --debug --verbose
        else
            flutter run -d "$DEVICE_ID"
        fi
        ;;
        
    android-simulator)
        ADB_DEVICES=$(adb devices 2>/dev/null | grep "emulator" | wc -l)
        if [ "$ADB_DEVICES" -eq 0 ]; then
            echo "Starting Android emulator..."
            EMULATOR_NAME=$(emulator -list-avds 2>/dev/null | head -1)
            if [ -z "$EMULATOR_NAME" ]; then
                echo "❌ No Android emulator found. Please create one in Android Studio."
                exit 1
            fi
            emulator -avd "$EMULATOR_NAME" &
            adb wait-for-device
            sleep 5
        fi
        if [ "$DEBUG" = true ]; then
            flutter run --debug --verbose
        else
            flutter run
        fi
        ;;
        
    linux)
        flutter build linux --debug
        "$SCRIPT_DIR/gold_and_silver_wallet/build/linux/x64/debug/bundle/gold_and_silver_wallet"
        ;;
        
    *)
        echo "❌ Unknown platform: $PLATFORM"
        exit 1
        ;;
esac

echo ""
echo "🎉 Gold and Silver Wallet is running!"

