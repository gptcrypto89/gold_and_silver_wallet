import 'package:hd_wallet/hd_wallet.dart';

/// Network types for different cryptocurrencies
enum NetworkType {
  bitcoin,
  kaspa,
}

/// Network configuration for different cryptocurrencies
class NetworkModel {
  final String id;
  final String name;
  final NetworkType type;
  final String rpcUrl;
  final String? explorerUrl;
  final bool isTestnet;
  final int chainId;
  final String symbol;
  final int decimals;
  final String? apiKey; // For services that require API keys

  NetworkModel({
    required this.id,
    required this.name,
    required this.type,
    required this.rpcUrl,
    this.explorerUrl,
    this.isTestnet = false,
    required this.chainId,
    required this.symbol,
    required this.decimals,
    this.apiKey,
  });

  /// Get the corresponding CoinType for this network
  CoinType get coinType {
    switch (type) {
      case NetworkType.bitcoin:
        return CoinType.bitcoin;
      case NetworkType.kaspa:
        return CoinType.kaspa;
    }
  }

  /// Get network display name with testnet indicator
  String get displayName {
    return isTestnet ? '$name (Testnet)' : name;
  }

  /// Get network color based on type
  String get colorHex {
    switch (type) {
      case NetworkType.bitcoin:
        return isTestnet ? '#F7931A' : '#F7931A'; // Bitcoin orange
      case NetworkType.kaspa:
        return isTestnet ? '#C0C0C0' : '#C0C0C0'; // Silver
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rpcUrl': rpcUrl,
      'explorerUrl': explorerUrl,
      'isTestnet': isTestnet,
      'chainId': chainId,
      'symbol': symbol,
      'decimals': decimals,
      'apiKey': apiKey,
    };
  }

  factory NetworkModel.fromJson(Map<String, dynamic> json) {
    return NetworkModel(
      id: json['id'],
      name: json['name'],
      type: NetworkType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NetworkType.bitcoin,
      ),
      rpcUrl: json['rpcUrl'],
      explorerUrl: json['explorerUrl'],
      isTestnet: json['isTestnet'] ?? false,
      chainId: json['chainId'],
      symbol: json['symbol'],
      decimals: json['decimals'],
      apiKey: json['apiKey'],
    );
  }

  NetworkModel copyWith({
    String? id,
    String? name,
    NetworkType? type,
    String? rpcUrl,
    String? explorerUrl,
    bool? isTestnet,
    int? chainId,
    String? symbol,
    int? decimals,
    String? apiKey,
  }) {
    return NetworkModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rpcUrl: rpcUrl ?? this.rpcUrl,
      explorerUrl: explorerUrl ?? this.explorerUrl,
      isTestnet: isTestnet ?? this.isTestnet,
      chainId: chainId ?? this.chainId,
      symbol: symbol ?? this.symbol,
      decimals: decimals ?? this.decimals,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NetworkModel(id: $id, name: $name, type: $type, rpcUrl: $rpcUrl, isTestnet: $isTestnet)';
  }
}

/// Predefined network configurations
class NetworkPresets {
  static final List<NetworkModel> bitcoinNetworks = [
    // Bitcoin Mainnet
    NetworkModel(
      id: 'bitcoin_mainnet',
      name: 'Bitcoin Mainnet',
      type: NetworkType.bitcoin,
      rpcUrl: 'https://blockstream.info/api',
      explorerUrl: 'https://blockstream.info',
      isTestnet: false,
      chainId: 0,
      symbol: 'BTC',
      decimals: 8,
    ),
  ];

  static final List<NetworkModel> kaspaNetworks = [
    // Kaspa Mainnet
    NetworkModel(
      id: 'kaspa_mainnet',
      name: 'Kaspa Mainnet',
      type: NetworkType.kaspa,
      rpcUrl: 'https://api.kaspa.org',
      explorerUrl: 'https://explorer.kaspa.org',
      isTestnet: false,
      chainId: 111111,
      symbol: 'KAS',
      decimals: 8,
    ),
  ];

  static List<NetworkModel> getAllNetworks() {
    return [...bitcoinNetworks, ...kaspaNetworks];
  }

  static List<NetworkModel> getNetworksByType(NetworkType type) {
    switch (type) {
      case NetworkType.bitcoin:
        return bitcoinNetworks;
      case NetworkType.kaspa:
        return kaspaNetworks;
    }
  }

  static NetworkModel? getDefaultNetwork(NetworkType type) {
    final networks = getNetworksByType(type);
    return networks.isNotEmpty ? networks.first : null;
  }
}
