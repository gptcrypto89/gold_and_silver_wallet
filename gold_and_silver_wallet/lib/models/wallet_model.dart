/// Wallet model for managing multiple wallets
class WalletModel {
  final String id;
  final String name;
  final String mnemonic;
  final String passphrase; // BIP39 passphrase (empty string if none)
  final DateTime createdAt;
  final int wordCount;

  WalletModel({
    required this.id,
    required this.name,
    required this.mnemonic,
    this.passphrase = '',
    required this.createdAt,
    required this.wordCount,
  });

  /// Check if wallet uses a passphrase
  bool get hasPassphrase => passphrase.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mnemonic': mnemonic,
      'passphrase': passphrase,
      'createdAt': createdAt.toIso8601String(),
      'wordCount': wordCount,
    };
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      name: json['name'],
      mnemonic: json['mnemonic'],
      passphrase: json['passphrase'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      wordCount: json['wordCount'] ?? 24,
    );
  }
}

