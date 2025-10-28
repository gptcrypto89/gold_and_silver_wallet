import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'secp256k1_bindings.dart';

/// High-level interface for secp256k1 cryptographic operations
class Secp256k1 {
  final Secp256k1Bindings _bindings;
  late final Pointer<Void> _context;

  Secp256k1({String? libraryPath}) : _bindings = Secp256k1Bindings(libraryPath: libraryPath) {
    _context = _bindings.contextCreate(
      Secp256k1Bindings.secp256k1ContextSign |
          Secp256k1Bindings.secp256k1ContextVerify,
    );
  }

  /// Clean up resources
  void dispose() {
    _bindings.contextDestroy(_context);
  }

  /// Generate public key from private key
  /// 
  /// [privateKey] must be exactly 32 bytes
  /// [compressed] determines if the public key should be compressed (33 bytes) or uncompressed (65 bytes)
  /// 
  /// Returns the public key or null if generation failed
  Uint8List? generatePublicKey(Uint8List privateKey, {bool compressed = true}) {
    if (privateKey.length != 32) {
      throw ArgumentError('Private key must be exactly 32 bytes, got ${privateKey.length}');
    }

    // Allocate memory for private key
    final privKeyPtr = calloc<Uint8>(32);
    for (int i = 0; i < 32; i++) {
      privKeyPtr[i] = privateKey[i];
    }

    // Allocate memory for public key (64 bytes internal representation)
    final pubKeyPtr = calloc<Uint8>(64);

    try {
      // Generate public key
      final result = _bindings.ecPubkeyCreate(_context, pubKeyPtr, privKeyPtr);

      if (result != 1) {
        return null;
      }

      // Serialize public key
      final outputLen = calloc<Size>();
      outputLen.value = compressed ? 33 : 65;
      final outputPtr = calloc<Uint8>(outputLen.value);

      try {
        final serializeResult = _bindings.ecPubkeySerialize(
          _context,
          outputPtr,
          outputLen,
          pubKeyPtr,
          compressed
              ? Secp256k1Bindings.secp256k1EcCompressed
              : Secp256k1Bindings.secp256k1EcUncompressed,
        );

        if (serializeResult != 1) {
          return null;
        }

        // Copy result to Dart
        final publicKey = Uint8List(outputLen.value);
        for (int i = 0; i < outputLen.value; i++) {
          publicKey[i] = outputPtr[i];
        }

        return publicKey;
      } finally {
        calloc.free(outputPtr);
        calloc.free(outputLen);
      }
    } finally {
      calloc.free(privKeyPtr);
      calloc.free(pubKeyPtr);
    }
  }

  /// Verify that a private key is valid
  /// 
  /// Returns true if the private key can generate a valid public key
  bool verifyPrivateKey(Uint8List privateKey) {
    if (privateKey.length != 32) {
      return false;
    }
    return generatePublicKey(privateKey) != null;
  }
}

