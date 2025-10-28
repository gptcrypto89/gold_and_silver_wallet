import 'package:hd_wallet/hd_wallet.dart';


/// Account model for managing multiple accounts within a wallet
class AccountModel {
  final String id;
  final String walletId;
  final String name;
  final CoinType coinType;
  final int accountIndex;
  final String derivationPath;
  final SignatureType signatureType;
  final String address; // Precalculated address for this account

  AccountModel({
    required this.id,
    required this.walletId,
    required this.name,
    required this.coinType,
    required this.accountIndex,
    required this.derivationPath,
    required this.signatureType,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'name': name,
      'coinTypeValue': coinType.value,
      'accountIndex': accountIndex,
      'derivationPath': derivationPath,
      'signatureType': signatureType.name,
      'address': address,
    };
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      walletId: json['walletId'],
      name: json['name'],
      coinType: _coinTypeFromValue(json['coinTypeValue']),
      accountIndex: json['accountIndex'],
      derivationPath: json['derivationPath'],
      signatureType: _signatureTypeFromString(json['signatureType'] ?? 'schnorr'),
      address: json['address'] ?? '', // Handle backward compatibility
    );
  }

  static CoinType _coinTypeFromValue(int value) {
    switch (value) {
      case 0:
        return CoinType.bitcoin;
      case 2:
        return CoinType.litecoin;
      case 3:
        return CoinType.dogecoin;
      case 145:
        return CoinType.bitcoinCash;
      case 111111:
        return CoinType.kaspa;
      default:
        return CoinType.bitcoin;
    }
  }

  static SignatureType _signatureTypeFromString(String signatureType) {
    switch (signatureType.toLowerCase()) {
      case 'schnorr':
        return SignatureType.schnorr;
      case 'ecdsa':
        return SignatureType.ecdsa;
      default:
        return SignatureType.schnorr;
    }
  }

  /// Get available signature types for a specific coin type
  /// 
  /// All coin types support both Schnorr and ECDSA signature types:
  /// - Schnorr: Used by standard wallets, Ledger, Kaspium, Kasware
  /// - ECDSA: Used by Tangem hardware wallets
  static List<SignatureType> getAvailableSignatureTypes(CoinType coinType) {
    return [SignatureType.schnorr, SignatureType.ecdsa];
  }

  /// Get signature type display name
  String get signatureTypeDisplayName {
    switch (signatureType) {
      case SignatureType.schnorr:
        return 'Schnorr';
      case SignatureType.ecdsa:
        return 'ECDSA';
    }
  }

  /// Get signature type description
  String get signatureTypeDescription {
    switch (signatureType) {
      case SignatureType.schnorr:
        return 'Schnorr signatures (Standard, Ledger, Kaspium, Kasware)';
      case SignatureType.ecdsa:
        return 'ECDSA signatures (Tangem hardware wallets)';
    }
  }
}

