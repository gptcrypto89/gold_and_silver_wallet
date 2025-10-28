import 'dart:ffi';
import 'dart:io';

// Type definitions for secp256k1 C library
typedef Secp256k1ContextCreateNative = Pointer<Void> Function(Uint32 flags);
typedef Secp256k1ContextCreate = Pointer<Void> Function(int flags);

typedef Secp256k1ContextDestroyNative = Void Function(Pointer<Void> ctx);
typedef Secp256k1ContextDestroy = void Function(Pointer<Void> ctx);

typedef Secp256k1EcPubkeyCreateNative = Int32 Function(
  Pointer<Void> ctx,
  Pointer<Uint8> pubkey,
  Pointer<Uint8> seckey,
);
typedef Secp256k1EcPubkeyCreate = int Function(
  Pointer<Void> ctx,
  Pointer<Uint8> pubkey,
  Pointer<Uint8> seckey,
);

typedef Secp256k1EcPubkeySerializeNative = Int32 Function(
  Pointer<Void> ctx,
  Pointer<Uint8> output,
  Pointer<Size> outputlen,
  Pointer<Uint8> pubkey,
  Uint32 flags,
);
typedef Secp256k1EcPubkeySerialize = int Function(
  Pointer<Void> ctx,
  Pointer<Uint8> output,
  Pointer<Size> outputlen,
  Pointer<Uint8> pubkey,
  int flags,
);

typedef Secp256k1EcdsaSignNative = Int32 Function(
  Pointer<Void> ctx,
  Pointer<Uint8> sig,
  Pointer<Uint8> msg32,
  Pointer<Uint8> seckey,
  Pointer<Void> noncefp,
  Pointer<Void> ndata,
);
typedef Secp256k1EcdsaSign = int Function(
  Pointer<Void> ctx,
  Pointer<Uint8> sig,
  Pointer<Uint8> msg32,
  Pointer<Uint8> seckey,
  Pointer<Void> noncefp,
  Pointer<Void> ndata,
);

typedef Secp256k1EcdsaVerifyNative = Int32 Function(
  Pointer<Void> ctx,
  Pointer<Uint8> sig,
  Pointer<Uint8> msg32,
  Pointer<Uint8> pubkey,
);
typedef Secp256k1EcdsaVerify = int Function(
  Pointer<Void> ctx,
  Pointer<Uint8> sig,
  Pointer<Uint8> msg32,
  Pointer<Uint8> pubkey,
);

/// FFI bindings for secp256k1 library
class Secp256k1Bindings {
  late final DynamicLibrary _lib;
  late final Secp256k1ContextCreate contextCreate;
  late final Secp256k1ContextDestroy contextDestroy;
  late final Secp256k1EcPubkeyCreate ecPubkeyCreate;
  late final Secp256k1EcPubkeySerialize ecPubkeySerialize;
  late final Secp256k1EcdsaSign ecdsaSign;
  late final Secp256k1EcdsaVerify ecdsaVerify;

  // secp256k1 constants
  static const int secp256k1ContextSign = 0x0101;
  static const int secp256k1ContextVerify = 0x0201;
  static const int secp256k1EcCompressed = 0x0102;
  static const int secp256k1EcUncompressed = 0x0002;

  Secp256k1Bindings({String? libraryPath}) {
    _lib = _loadLibrary(libraryPath);
    _bindFunctions();
  }

  DynamicLibrary _loadLibrary(String? customPath) {
    if (customPath != null) {
      return DynamicLibrary.open(customPath);
    }

    if (Platform.isMacOS) {
      // Try multiple paths for macOS (all relative)
      final possiblePaths = [
        // App bundle Frameworks directory (production)
        '@executable_path/../Frameworks/libsecp256k1.dylib',
        // Development path (relative to package)
        '../secp256k1_wrapper/native/macos/libsecp256k1.dylib',
        '../../secp256k1_wrapper/native/macos/libsecp256k1.dylib',
        '../../../secp256k1_wrapper/native/macos/libsecp256k1.dylib',
        // Current directory
        'libsecp256k1.dylib',
        // System paths (fallback)
        '/opt/homebrew/lib/libsecp256k1.dylib',
        '/usr/local/lib/libsecp256k1.dylib',
      ];

      for (final path in possiblePaths) {
        try {
          return DynamicLibrary.open(path);
        } catch (e) {
          continue;
        }
      }
      throw UnsupportedError(
        'Could not load libsecp256k1.dylib for macOS. Tried: ${possiblePaths.join(", ")}',
      );
    } else if (Platform.isIOS) {
      return DynamicLibrary.open('libsecp256k1.dylib');
    } else if (Platform.isAndroid) {
      return DynamicLibrary.open('libsecp256k1.so');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libsecp256k1.so');
    } else if (Platform.isWindows) {
      // Try multiple paths for Windows
      final possiblePaths = [
        'secp256k1.dll',
        'libsecp256k1.dll',
        './secp256k1.dll',
        './libsecp256k1.dll',
      ];
      
      for (final path in possiblePaths) {
        try {
          return DynamicLibrary.open(path);
        } catch (e) {
          continue;
        }
      }
      throw UnsupportedError(
        'Could not load secp256k1.dll for Windows. Tried: ${possiblePaths.join(", ")}',
      );
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
  }

  void _bindFunctions() {
    contextCreate = _lib
        .lookup<NativeFunction<Secp256k1ContextCreateNative>>(
            'secp256k1_context_create')
        .asFunction();

    contextDestroy = _lib
        .lookup<NativeFunction<Secp256k1ContextDestroyNative>>(
            'secp256k1_context_destroy')
        .asFunction();

    ecPubkeyCreate = _lib
        .lookup<NativeFunction<Secp256k1EcPubkeyCreateNative>>(
            'secp256k1_ec_pubkey_create')
        .asFunction();

    ecPubkeySerialize = _lib
        .lookup<NativeFunction<Secp256k1EcPubkeySerializeNative>>(
            'secp256k1_ec_pubkey_serialize')
        .asFunction();

    ecdsaSign = _lib
        .lookup<NativeFunction<Secp256k1EcdsaSignNative>>(
            'secp256k1_ecdsa_sign')
        .asFunction();

    ecdsaVerify = _lib
        .lookup<NativeFunction<Secp256k1EcdsaVerifyNative>>(
            'secp256k1_ecdsa_verify')
        .asFunction();
  }
}

