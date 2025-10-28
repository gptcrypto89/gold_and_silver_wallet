#!/bin/bash

# Gold and Silver Wallet - Release Build Script
# Builds optimized release executables for specified platform
# Usage: ./release.sh --platform=<macos|ios|android|linux|windows> [--version=<version>] [--build-number=<number>] [--skip-build] [--bundle] [--sign]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLATFORM=""
VERSION=""
BUILD_NUMBER=""
SKIP_BUILD=false
BUNDLE=false
SIGN=false
OUTPUT_DIR=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --platform=*)
            PLATFORM="${arg#*=}"
            shift
            ;;
        --version=*)
            VERSION="${arg#*=}"
            shift
            ;;
        --build-number=*)
            BUILD_NUMBER="${arg#*=}"
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --bundle)
            BUNDLE=true
            shift
            ;;
        --sign)
            SIGN=true
            shift
            ;;
        --output=*)
            OUTPUT_DIR="${arg#*=}"
            shift
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: ./release.sh --platform=<macos|ios|android|linux|windows> [--version=<version>] [--build-number=<number>] [--skip-build] [--bundle] [--sign] [--output=<dir>]"
            exit 1
            ;;
    esac
done

# Check if platform is provided
if [ -z "$PLATFORM" ]; then
    echo "❌ Error: Platform not specified"
    echo "Usage: ./release.sh --platform=<macos|ios|android|linux|windows> [--version=<version>] [--build-number=<number>] [--skip-build] [--bundle] [--sign] [--output=<dir>]"
    echo ""
    echo "Available platforms:"
    echo "  - macos              : Build macOS release app"
    echo "  - ios                : Build iOS release app"
    echo "  - android            : Build Android release APK/AAB"
    echo "  - linux              : Build Linux release executable"
    echo "  - windows            : Build Windows release executable"
    echo ""
    echo "Options:"
    echo "  --version=<version>  : Set app version (default: from pubspec.yaml)"
    echo "  --build-number=<num>  : Set build number (default: auto-increment)"
    echo "  --skip-build          : Skip building native libraries (if already built)"
    echo "  --bundle              : Create distribution bundle/installer"
    echo "  --sign                : Code sign the release (macOS/iOS only)"
    echo "  --output=<dir>        : Output directory (default: ./releases/)"
    exit 1
fi

# Set default output directory
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$SCRIPT_DIR/releases"
fi

echo "🚀 Gold and Silver Wallet Release Build"
echo "======================================"
echo "Platform: $PLATFORM"
echo "Output: $OUTPUT_DIR"
echo ""

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

# Get version info
if [ -z "$VERSION" ]; then
    VERSION=$(grep "^version:" "$SCRIPT_DIR/gold_and_silver_wallet/pubspec.yaml" | sed 's/version: //' | sed 's/+.*//')
fi

if [ -z "$BUILD_NUMBER" ]; then
    BUILD_NUMBER=$(grep "^version:" "$SCRIPT_DIR/gold_and_silver_wallet/pubspec.yaml" | sed 's/.*+//')
    BUILD_NUMBER=$((BUILD_NUMBER + 1))
fi

echo "📱 App Version: $VERSION"
echo "🔢 Build Number: $BUILD_NUMBER"
echo ""

# Build native libraries if needed
if [ "$SKIP_BUILD" = false ]; then
    echo "🔧 Building secp256k1 native libraries for release..."
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
    
    cd "$SECP256K1_DIR"
    
    # Generate configure script if needed
    if [ ! -f "configure" ]; then
        echo "🔨 Generating build configuration..."
        ./autogen.sh
    fi
    
    # Common configuration for release
    COMMON_FLAGS="--enable-module-recovery --disable-tests --disable-benchmark --disable-exhaustive-tests"
    
    # Build for the target platform
    case $PLATFORM in
        macos)
            if [ ! -f "$WRAPPER_DIR/macos/libsecp256k1.dylib" ]; then
                echo "🍎 Building for macOS release..."
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
            
        ios)
            if [ ! -f "$WRAPPER_DIR/ios-device/libsecp256k1.dylib" ]; then
                echo "📱 Building for iOS Device release..."
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
            else
                echo "✓ iOS Device library already exists"
            fi
            ;;
            
        android)
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
            
            echo "🤖 Building for Android release..."
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
                echo "🐧 Building for Linux release..."
                ./configure $COMMON_FLAGS --prefix="$SCRIPT_DIR/build/linux"
                make clean > /dev/null 2>&1
                make -j$(nproc)
                make install
                mkdir -p "$WRAPPER_DIR/linux"
                cp "$SCRIPT_DIR/build/linux/lib/libsecp256k1.so" "$WRAPPER_DIR/linux/"
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

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "📱 Building Gold and Silver Wallet release for $PLATFORM..."
echo ""

# Build release based on platform
case $PLATFORM in
    macos)
        echo "🍎 Building macOS release..."
        
        # Build the app
        flutter build macos --release \
            --build-name="$VERSION" \
            --build-number="$BUILD_NUMBER" \
            --dart-define=FLUTTER_WEB_USE_SKIA=true \
            --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
            --tree-shake-icons \
            --obfuscate \
            --split-debug-info="$OUTPUT_DIR/debug-info"
        
        # Bundle library
        APP_FRAMEWORKS="$SCRIPT_DIR/gold_and_silver_wallet/build/macos/Build/Products/Release/gold_and_silver_wallet.app/Contents/Frameworks"
        LIB_SOURCE="$SCRIPT_DIR/secp256k1_wrapper/native/macos/libsecp256k1.dylib"
        
        if [ -f "$LIB_SOURCE" ]; then
            mkdir -p "$APP_FRAMEWORKS"
            cp "$LIB_SOURCE" "$APP_FRAMEWORKS/"
            install_name_tool -id "@executable_path/../Frameworks/libsecp256k1.dylib" "$APP_FRAMEWORKS/libsecp256k1.dylib"
            echo "✓ Native library bundled successfully"
        else
            echo "⚠️  Warning: Native library not found at $LIB_SOURCE"
        fi
        
        # Copy to output directory
        cp -R "$SCRIPT_DIR/gold_and_silver_wallet/build/macos/Build/Products/Release/gold_and_silver_wallet.app" "$OUTPUT_DIR/"
        
        # Code signing
        if [ "$SIGN" = true ]; then
            echo "🔐 Code signing macOS app..."
            codesign --force --deep --sign - "$OUTPUT_DIR/gold_and_silver_wallet.app"
            echo "✓ App signed"
        fi
        
        # Create DMG if bundling
        if [ "$BUNDLE" = true ]; then
            echo "📦 Creating DMG installer..."
            DMG_NAME="GoldAndSilverWallet-$VERSION-macos.dmg"
            hdiutil create -volname "Gold and Silver Wallet" -srcfolder "$OUTPUT_DIR/gold_and_silver_wallet.app" -ov -format UDZO "$OUTPUT_DIR/$DMG_NAME"
            echo "✓ DMG created: $DMG_NAME"
        fi
        
        echo "✓ macOS release built: $OUTPUT_DIR/gold_and_silver_wallet.app"
        ;;
        
    ios)
        echo "📱 Building iOS release..."
        
        # Build the app
        flutter build ios --release \
            --build-name="$VERSION" \
            --build-number="$BUILD_NUMBER" \
            --dart-define=FLUTTER_WEB_USE_SKIA=true \
            --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
            --tree-shake-icons \
            --obfuscate \
            --split-debug-info="$OUTPUT_DIR/debug-info"
        
        # Copy to output directory
        cp -R "$SCRIPT_DIR/gold_and_silver_wallet/build/ios/iphoneos/Runner.app" "$OUTPUT_DIR/"
        
        # Code signing
        if [ "$SIGN" = true ]; then
            echo "🔐 Code signing iOS app..."
            codesign --force --deep --sign - "$OUTPUT_DIR/Runner.app"
            echo "✓ App signed"
        fi
        
        # Create IPA if bundling
        if [ "$BUNDLE" = true ]; then
            echo "📦 Creating IPA..."
            IPA_NAME="GoldAndSilverWallet-$VERSION.ipa"
            mkdir -p "$OUTPUT_DIR/Payload"
            cp -R "$OUTPUT_DIR/Runner.app" "$OUTPUT_DIR/Payload/"
            cd "$OUTPUT_DIR"
            zip -r "$IPA_NAME" Payload/
            rm -rf Payload/
            cd "$SCRIPT_DIR/gold_and_silver_wallet"
            echo "✓ IPA created: $IPA_NAME"
        fi
        
        echo "✓ iOS release built: $OUTPUT_DIR/Runner.app"
        ;;
        
    android)
        echo "🤖 Building Android release..."
        
        # Build APK
        flutter build apk --release \
            --build-name="$VERSION" \
            --build-number="$BUILD_NUMBER" \
            --dart-define=FLUTTER_WEB_USE_SKIA=true \
            --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
            --tree-shake-icons \
            --obfuscate \
            --split-debug-info="$OUTPUT_DIR/debug-info"
        
        # Copy APK
        cp "$SCRIPT_DIR/gold_and_silver_wallet/build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/GoldAndSilverWallet-$VERSION.apk"
        
        # Build AAB if bundling
        if [ "$BUNDLE" = true ]; then
            echo "📦 Building Android App Bundle..."
            flutter build appbundle --release \
                --build-name="$VERSION" \
                --build-number="$BUILD_NUMBER" \
                --dart-define=FLUTTER_WEB_USE_SKIA=true \
                --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
                --tree-shake-icons \
                --obfuscate \
                --split-debug-info="$OUTPUT_DIR/debug-info"
            
            cp "$SCRIPT_DIR/gold_and_silver_wallet/build/app/outputs/bundle/release/app-release.aab" "$OUTPUT_DIR/GoldAndSilverWallet-$VERSION.aab"
            echo "✓ AAB created: GoldAndSilverWallet-$VERSION.aab"
        fi
        
        echo "✓ Android release built: $OUTPUT_DIR/GoldAndSilverWallet-$VERSION.apk"
        ;;
        
    linux)
        echo "🐧 Building Linux release..."
        
        # Build the app
        flutter build linux --release \
            --build-name="$VERSION" \
            --build-number="$BUILD_NUMBER" \
            --dart-define=FLUTTER_WEB_USE_SKIA=true \
            --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
            --tree-shake-icons \
            --obfuscate \
            --split-debug-info="$OUTPUT_DIR/debug-info"
        
        # Copy executable
        cp "$SCRIPT_DIR/gold_and_silver_wallet/build/linux/x64/release/bundle/gold_and_silver_wallet" "$OUTPUT_DIR/GoldAndSilverWallet-$VERSION-linux"
        chmod +x "$OUTPUT_DIR/GoldAndSilverWallet-$VERSION-linux"
        
        # Create AppImage if bundling
        if [ "$BUNDLE" = true ]; then
            echo "📦 Creating AppImage..."
            APPIMAGE_NAME="GoldAndSilverWallet-$VERSION-linux.AppImage"
            
            # Create AppDir structure
            APPDIR="$OUTPUT_DIR/GoldAndSilverWallet.AppDir"
            mkdir -p "$APPDIR"
            
            # Copy app files
            cp -R "$SCRIPT_DIR/gold_and_silver_wallet/build/linux/x64/release/bundle/"* "$APPDIR/"
            
            # Create AppRun script
            cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
exec "${HERE}/gold_and_silver_wallet" "$@"
EOF
            chmod +x "$APPDIR/AppRun"
            
            # Create desktop file
            cat > "$APPDIR/gold-and-silver-wallet.desktop" << EOF
[Desktop Entry]
Name=Gold and Silver Wallet
Comment=Cryptocurrency wallet for gold and silver
Exec=gold_and_silver_wallet
Icon=gold_and_silver_wallet
Type=Application
Categories=Finance;
EOF
            
            # Create AppImage using appimagetool if available
            if command -v appimagetool &> /dev/null; then
                appimagetool "$APPDIR" "$OUTPUT_DIR/$APPIMAGE_NAME"
                rm -rf "$APPDIR"
                echo "✓ AppImage created: $APPIMAGE_NAME"
            else
                echo "⚠️  appimagetool not found. Install it to create AppImage."
                echo "   Download from: https://github.com/AppImage/AppImageKit/releases"
            fi
        fi
        
        echo "✓ Linux release built: $OUTPUT_DIR/GoldAndSilverWallet-$VERSION-linux"
        ;;
        
    windows)
        echo "🪟 Building Windows release..."
        
        # Build the app
        flutter build windows --release \
            --build-name="$VERSION" \
            --build-number="$BUILD_NUMBER" \
            --dart-define=FLUTTER_WEB_USE_SKIA=true \
            --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
            --tree-shake-icons \
            --obfuscate \
            --split-debug-info="$OUTPUT_DIR/debug-info"
        
        # Copy executable
        cp -R "$SCRIPT_DIR/gold_and_silver_wallet/build/windows/x64/runner/Release/" "$OUTPUT_DIR/GoldAndSilverWallet-$VERSION-windows/"
        
        # Create NSIS installer if bundling
        if [ "$BUNDLE" = true ]; then
            echo "📦 Creating Windows installer..."
            INSTALLER_NAME="GoldAndSilverWallet-$VERSION-windows-installer.exe"
            
            # Create NSIS script
            cat > "$OUTPUT_DIR/installer.nsi" << EOF
!define APPNAME "Gold and Silver Wallet"
!define COMPANYNAME "Gold and Silver Wallet"
!define DESCRIPTION "Cryptocurrency wallet for gold and silver"
!define VERSIONMAJOR $VERSION
!define VERSIONMINOR 0
!define VERSIONBUILD $BUILD_NUMBER

!define HELPURL "https://github.com/your-repo/gold-and-silver-wallet"
!define UPDATEURL "https://github.com/your-repo/gold-and-silver-wallet"
!define ABOUTURL "https://github.com/your-repo/gold-and-silver-wallet"
!define INSTALLSIZE 50000

RequestExecutionLevel admin
InstallDir "\$PROGRAMFILES\\\${APPNAME}"

Name "\${APPNAME}"
Icon "\${NSISDIR}\\Contrib\\Graphics\\Icons\\modern-install.ico"
outFile "$INSTALLER_NAME"

!include LogicLib.nsh

page directory
page instfiles

!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop \$0
\${If} \$0 != "admin"
    messageBox mb_iconstop "Administrator rights required!"
    setErrorLevel 740
    quit
\${EndIf}
!macroend

function .onInit
    setShellVarContext all
    !insertmacro VerifyUserIsAdmin
functionEnd

section "install"
    setOutPath \$INSTDIR
    file /r "GoldAndSilverWallet-$VERSION-windows\\*"
    writeUninstaller "\$INSTDIR\\uninstall.exe"
    
    createDirectory "\$SMPROGRAMS\\\${APPNAME}"
    createShortCut "\$SMPROGRAMS\\\${APPNAME}\\\${APPNAME}.lnk" "\$INSTDIR\\gold_and_silver_wallet.exe" "" "\$INSTDIR\\gold_and_silver_wallet.exe"
    createShortCut "\$DESKTOP\\\${APPNAME}.lnk" "\$INSTDIR\\gold_and_silver_wallet.exe" "" "\$INSTDIR\\gold_and_silver_wallet.exe"
sectionEnd

section "uninstall"
    delete "\$INSTDIR\\uninstall.exe"
    delete "\$SMPROGRAMS\\\${APPNAME}\\\${APPNAME}.lnk"
    delete "\$DESKTOP\\\${APPNAME}.lnk"
    rmDir "\$SMPROGRAMS\\\${APPNAME}"
    rmDir /r "\$INSTDIR"
sectionEnd
EOF
            
            # Create installer using NSIS if available
            if command -v makensis &> /dev/null; then
                cd "$OUTPUT_DIR"
                makensis installer.nsi
                rm installer.nsi
                echo "✓ Windows installer created: $INSTALLER_NAME"
            else
                echo "⚠️  NSIS not found. Install it to create Windows installer."
                echo "   Download from: https://nsis.sourceforge.io/Download"
                rm installer.nsi
            fi
        fi
        
        echo "✓ Windows release built: $OUTPUT_DIR/GoldAndSilverWallet-$VERSION-windows/"
        ;;
        
    *)
        echo "❌ Unknown platform: $PLATFORM"
        exit 1
        ;;
esac

echo ""
echo "🎉 Release build completed successfully!"
echo "📁 Output directory: $OUTPUT_DIR"
echo ""

# Show file sizes
echo "📊 Release file sizes:"
find "$OUTPUT_DIR" -type f -name "*$VERSION*" -exec ls -lh {} \; | while read line; do
    echo "  $line"
done

echo ""
echo "✅ Gold and Silver Wallet $VERSION release is ready!"
