import 'package:hd_wallet/hd_wallet.dart';
import 'dart:math';

/// Balance information for an account
class BalanceModel {
  final String accountId;
  final CoinType coinType;
  final String networkId;
  final String address;
  final BigInt balance; // Balance in satoshis/smallest unit
  final int decimals;
  final String symbol;
  final DateTime lastUpdated;
  final bool isConfirmed;

  BalanceModel({
    required this.accountId,
    required this.coinType,
    required this.networkId,
    required this.address,
    required this.balance,
    required this.decimals,
    required this.symbol,
    required this.lastUpdated,
    this.isConfirmed = true,
  });

  /// Get balance in main units (e.g., BTC, KAS)
  double get balanceInMainUnits {
    return balance / BigInt.from(pow(10, decimals));
  }

  /// Get formatted balance string
  String get formattedBalance {
    final mainUnits = balanceInMainUnits;
    if (mainUnits == 0) return '0 $symbol';
    
    if (mainUnits < 0.000001) {
      return '${mainUnits.toStringAsFixed(8)} $symbol';
    } else if (mainUnits < 0.01) {
      return '${mainUnits.toStringAsFixed(6)} $symbol';
    } else if (mainUnits < 1) {
      return '${mainUnits.toStringAsFixed(4)} $symbol';
    } else {
      return '${mainUnits.toStringAsFixed(2)} $symbol';
    }
  }

  /// Get balance in satoshis/smallest unit as string
  String get balanceString {
    return balance.toString();
  }

  /// Check if balance is zero
  bool get isEmpty => balance == BigInt.zero;

  /// Check if balance is positive
  bool get isPositive => balance > BigInt.zero;

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'coinTypeValue': coinType.value,
      'networkId': networkId,
      'address': address,
      'balance': balance.toString(),
      'decimals': decimals,
      'symbol': symbol,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isConfirmed': isConfirmed,
    };
  }

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    return BalanceModel(
      accountId: json['accountId'],
      coinType: _coinTypeFromValue(json['coinTypeValue']),
      networkId: json['networkId'],
      address: json['address'],
      balance: BigInt.parse(json['balance']),
      decimals: json['decimals'],
      symbol: json['symbol'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isConfirmed: json['isConfirmed'] ?? true,
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

  BalanceModel copyWith({
    String? accountId,
    CoinType? coinType,
    String? networkId,
    String? address,
    BigInt? balance,
    int? decimals,
    String? symbol,
    DateTime? lastUpdated,
    bool? isConfirmed,
  }) {
    return BalanceModel(
      accountId: accountId ?? this.accountId,
      coinType: coinType ?? this.coinType,
      networkId: networkId ?? this.networkId,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      decimals: decimals ?? this.decimals,
      symbol: symbol ?? this.symbol,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BalanceModel &&
        other.accountId == accountId &&
        other.networkId == networkId &&
        other.address == address;
  }

  @override
  int get hashCode => Object.hash(accountId, networkId, address);

  @override
  String toString() {
    return 'BalanceModel(accountId: $accountId, balance: $formattedBalance, lastUpdated: $lastUpdated)';
  }
}

/// Balance summary for multiple accounts
class BalanceSummary {
  final Map<String, BalanceModel> balances; // accountId -> balance
  final DateTime lastUpdated;

  BalanceSummary({
    required this.balances,
    required this.lastUpdated,
  });

  /// Get total balance for a specific coin type
  double getTotalBalanceForCoin(CoinType coinType) {
    double total = 0;
    for (final balance in balances.values) {
      if (balance.coinType == coinType) {
        total += balance.balanceInMainUnits;
      }
    }
    return total;
  }

  /// Get balance for a specific account
  BalanceModel? getBalanceForAccount(String accountId) {
    return balances[accountId];
  }

  /// Get all balances for a specific coin type
  List<BalanceModel> getBalancesForCoin(CoinType coinType) {
    return balances.values
        .where((balance) => balance.coinType == coinType)
        .toList();
  }

  /// Check if any balance is available
  bool get hasAnyBalance {
    return balances.values.any((balance) => balance.isPositive);
  }

  /// Get formatted total balance for a coin type
  String getFormattedTotalBalance(CoinType coinType) {
    final total = getTotalBalanceForCoin(coinType);
    final symbol = coinType.symbol;
    
    if (total == 0) return '0 $symbol';
    
    if (total < 0.000001) {
      return '${total.toStringAsFixed(8)} $symbol';
    } else if (total < 0.01) {
      return '${total.toStringAsFixed(6)} $symbol';
    } else if (total < 1) {
      return '${total.toStringAsFixed(4)} $symbol';
    } else {
      return '${total.toStringAsFixed(2)} $symbol';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'balances': balances.map((key, value) => MapEntry(key, value.toJson())),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory BalanceSummary.fromJson(Map<String, dynamic> json) {
    final balancesMap = <String, BalanceModel>{};
    final balancesJson = json['balances'] as Map<String, dynamic>;
    
    for (final entry in balancesJson.entries) {
      balancesMap[entry.key] = BalanceModel.fromJson(entry.value);
    }
    
    return BalanceSummary(
      balances: balancesMap,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
