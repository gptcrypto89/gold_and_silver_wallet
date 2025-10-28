# CMakeLists.txt for secp256k1 native library integration

cmake_minimum_required(VERSION 3.10)

project(gold_and_silver_wallet)

# Define the path to secp256k1 native libraries
set(SECP256K1_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../secp256k1_wrapper/native/android/jniLibs")

# Add pre-built secp256k1 library
add_library(secp256k1 SHARED IMPORTED)
set_target_properties(secp256k1 PROPERTIES
    IMPORTED_LOCATION "${SECP256K1_LIB_DIR}/${ANDROID_ABI}/libsecp256k1.so"
)

# Make sure the library is included in the APK
install(FILES "${SECP256K1_LIB_DIR}/${ANDROID_ABI}/libsecp256k1.so"
    DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/${ANDROID_ABI}"
)

