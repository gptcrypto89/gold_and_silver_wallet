#!/bin/bash

# Copy secp256k1 library to app bundle Frameworks directory
# This runs automatically during build

set -e

FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
PROJECT_DIR_PARENT="${PROJECT_DIR}/../.."
LIB_SOURCE="${PROJECT_DIR_PARENT}/secp256k1_wrapper/native/macos/libsecp256k1.dylib"

echo "Bundling secp256k1 library..."

# Create Frameworks directory if it doesn't exist
mkdir -p "${FRAMEWORKS_DIR}"

if [ -f "$LIB_SOURCE" ]; then
    # Copy the library
    cp "$LIB_SOURCE" "${FRAMEWORKS_DIR}/"
    
    # Fix install name for the library
    install_name_tool -id "@executable_path/../Frameworks/libsecp256k1.dylib" "${FRAMEWORKS_DIR}/libsecp256k1.dylib"
    
    echo "✅ Successfully bundled libsecp256k1.dylib"
else
    echo "⚠️  Warning: libsecp256k1.dylib not found at $LIB_SOURCE"
    echo "    Please run ./setup_secp256k1.sh first"
    exit 1
fi
