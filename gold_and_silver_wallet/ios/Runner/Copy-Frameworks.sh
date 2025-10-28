#!/bin/bash
# Copy secp256k1 library to iOS app bundle

FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
SOURCE_LIB="${SRCROOT}/../../secp256k1_wrapper/native/ios/libsecp256k1.dylib"

echo "Copying secp256k1 library to iOS app bundle..."
echo "Source: ${SOURCE_LIB}"
echo "Destination: ${FRAMEWORKS_DIR}"

# Create Frameworks directory if it doesn't exist
mkdir -p "${FRAMEWORKS_DIR}"

# Copy the library
if [ -f "${SOURCE_LIB}" ]; then
    cp "${SOURCE_LIB}" "${FRAMEWORKS_DIR}/"
    echo "✅ Library copied successfully"
    
    # Update install name for iOS
    install_name_tool -id "@rpath/libsecp256k1.dylib" "${FRAMEWORKS_DIR}/libsecp256k1.dylib"
    echo "✅ Library install name updated"
else
    echo "⚠️ Warning: ${SOURCE_LIB} not found"
    exit 1
fi

