# Gold and Silver Wallet - Release Build Guide

This guide explains how to use the `release.sh` script to build optimized release executables for different platforms.

## Quick Start

```bash
# Build macOS release
./release.sh --platform=macos

# Build iOS release with custom version
./release.sh --platform=ios --version=1.2.0 --build-number=5

# Build Android release with bundle
./release.sh --platform=android --bundle

# Build Linux release with AppImage
./release.sh --platform=linux --bundle

# Build Windows release with installer
./release.sh --platform=windows --bundle
```

## Supported Platforms

| Platform | Output | Bundle Option |
|-----------|--------|---------------|
| `macos` | `.app` file | DMG installer |
| `ios` | `.app` file | IPA archive |
| `android` | APK file | AAB (Android App Bundle) |
| `linux` | Executable | AppImage |
| `windows` | Executable folder | NSIS installer |

## Command Line Options

### Required Options

- `--platform=<platform>` - Target platform (macos, ios, android, linux, windows)

### Optional Options

- `--version=<version>` - App version (default: from pubspec.yaml)
- `--build-number=<number>` - Build number (default: auto-increment)
- `--skip-build` - Skip building native libraries (if already built)
- `--bundle` - Create distribution bundle/installer
- `--sign` - Code sign the release (macOS/iOS only)
- `--output=<dir>` - Output directory (default: ./releases/)

## Release Optimizations

The release script automatically applies the following optimizations:

### Flutter Optimizations
- **Release Mode**: Full optimization with no debug overhead
- **Code Obfuscation**: Protects source code from reverse engineering
- **Tree Shaking**: Removes unused code to reduce app size
- **Icon Tree Shaking**: Removes unused icons
- **Debug Info Splitting**: Separates debug symbols for smaller binaries

### Native Library Optimizations
- **Optimized Build**: Native libraries built with release flags
- **Architecture Specific**: Builds for target platform architecture
- **Size Optimization**: Strips debug symbols from native libraries

## Platform-Specific Details

### macOS
- Creates a `.app` bundle with native library included
- Supports code signing with `--sign` flag
- Creates DMG installer with `--bundle` flag
- Output: `gold_and_silver_wallet.app`

### iOS
- Creates a `.app` bundle for iOS devices
- Supports code signing with `--sign` flag
- Creates IPA archive with `--bundle` flag
- Output: `Runner.app` or `GoldAndSilverWallet-<version>.ipa`

### Android
- Creates APK file by default
- Creates AAB (Android App Bundle) with `--bundle` flag
- Supports multiple architectures (arm64-v8a, armeabi-v7a, x86_64, x86)
- Output: `GoldAndSilverWallet-<version>.apk` or `.aab`

### Linux
- Creates standalone executable
- Creates AppImage with `--bundle` flag (requires appimagetool)
- Output: `GoldAndSilverWallet-<version>-linux` or `.AppImage`

### Windows
- Creates executable folder with all dependencies
- Creates NSIS installer with `--bundle` flag (requires NSIS)
- Output: `GoldAndSilverWallet-<version>-windows/` or `.exe` installer

## Prerequisites

### All Platforms
- Flutter SDK (automatically cloned if not found)
- Git (for cloning dependencies)

### macOS/iOS
- Xcode command line tools
- Code signing certificates (for `--sign` option)

### Android
- Android NDK (automatically detected from common locations)
- Android Studio (for NDK installation)

### Linux
- appimagetool (for AppImage creation with `--bundle`)
- Standard build tools (gcc, make, etc.)

### Windows
- NSIS (for installer creation with `--bundle`)
- Windows build tools

## Output Structure

```
releases/
├── GoldAndSilverWallet-1.0.0-macos.dmg          # macOS DMG
├── GoldAndSilverWallet-1.0.0.ipa                # iOS IPA
├── GoldAndSilverWallet-1.0.0.apk                 # Android APK
├── GoldAndSilverWallet-1.0.0.aab                # Android AAB
├── GoldAndSilverWallet-1.0.0-linux.AppImage     # Linux AppImage
├── GoldAndSilverWallet-1.0.0-windows-installer.exe # Windows installer
└── debug-info/                                   # Debug symbols
```

## Troubleshooting

### Common Issues

1. **Flutter not found**: The script automatically clones Flutter if not found
2. **Native library build fails**: Ensure you have the required build tools
3. **Code signing fails**: Check your certificates and keychain access
4. **Bundle creation fails**: Install the required tools (appimagetool, NSIS)

### Debug Information

- Debug symbols are saved to `debug-info/` directory
- Use `--skip-build` to skip native library compilation if already built
- Check the output directory for all generated files

## Examples

### Basic Release Builds
```bash
# Simple macOS release
./release.sh --platform=macos

# Android release with custom version
./release.sh --platform=android --version=2.0.0 --build-number=10
```

### Distribution-Ready Builds
```bash
# macOS with DMG installer
./release.sh --platform=macos --bundle

# iOS with IPA and code signing
./release.sh --platform=ios --bundle --sign

# Android with AAB for Play Store
./release.sh --platform=android --bundle

# Linux with AppImage
./release.sh --platform=linux --bundle

# Windows with NSIS installer
./release.sh --platform=windows --bundle
```

### Custom Output Directory
```bash
# Build to custom directory
./release.sh --platform=macos --output=/path/to/custom/releases
```

## Security Notes

- Code obfuscation is automatically applied to protect your source code
- Native libraries are optimized for release
- Debug information is separated for security
- Use `--sign` flag for code signing on macOS/iOS

## Performance

- Release builds are significantly smaller than debug builds
- Native libraries are optimized for performance
- Tree shaking removes unused code
- App startup time is optimized

For more information, see the main project README or contact the development team.
