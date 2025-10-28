import 'package:hd_wallet/hd_wallet.dart';
import 'dart:math';

/// Transaction types
enum TransactionType {
  sent,
  received,
  pending,
}

/// Transaction status
enum TransactionStatus {
  confirmed,
  pending,
  failed,
}

/// Transaction model for displaying transaction history
class TransactionModel {
  final String id;
  final String accountId;
  final String address;
  final CoinType coinType;
  final TransactionType type;
  final TransactionStatus status;
  final BigInt amount; // Amount in satoshis/smallest unit
  final BigInt fee; // Fee in satoshis/smallest unit
  final String? hash;
  final int confirmations;
  final DateTime timestamp;
  final String? fromAddress;
  final String? toAddress;
  final String? memo;
  final int decimals;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.address,
    required this.coinType,
    required this.type,
    required this.status,
    required this.amount,
    required this.fee,
    this.hash,
    required this.confirmations,
    required this.timestamp,
    this.fromAddress,
    this.toAddress,
    this.memo,
    required this.decimals,
  });

  /// Get amount in main units (e.g., BTC, KAS)
  double get amountInMainUnits {
    return amount / BigInt.from(pow(10, decimals));
  }

  /// Get fee in main units
  double get feeInMainUnits {
    return fee / BigInt.from(pow(10, decimals));
  }

  /// Get formatted amount string
  String get formattedAmount {
    final mainUnits = amountInMainUnits;
    final symbol = coinType.symbol;
    
    if (mainUnits == 0) return '0 $symbol';
    
    final prefix = type == TransactionType.sent ? '-' : '+';
    
    if (mainUnits < 0.000001) {
      return '$prefix${mainUnits.toStringAsFixed(8)} $symbol';
    } else if (mainUnits < 0.01) {
      return '$prefix${mainUnits.toStringAsFixed(6)} $symbol';
    } else if (mainUnits < 1) {
      return '$prefix${mainUnits.toStringAsFixed(4)} $symbol';
    } else {
      return '$prefix${mainUnits.toStringAsFixed(2)} $symbol';
    }
  }

  /// Get formatted fee string
  String get formattedFee {
    final mainUnits = feeInMainUnits;
    final symbol = coinType.symbol;
    
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

  /// Check if transaction is confirmed
  bool get isConfirmed => status == TransactionStatus.confirmed;

  /// Check if transaction is pending
  bool get isPending => status == TransactionStatus.pending;

  /// Check if transaction failed
  bool get isFailed => status == TransactionStatus.failed;

  /// Get transaction type display name
  String get typeDisplayName {
    switch (type) {
      case TransactionType.sent:
        return 'Sent';
      case TransactionType.received:
        return 'Received';
      case TransactionType.pending:
        return 'Pending';
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.confirmed:
        return 'Confirmed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case TransactionStatus.confirmed:
        return 'green';
      case TransactionStatus.pending:
        return 'orange';
      case TransactionStatus.failed:
        return 'red';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'address': address,
      'coinTypeValue': coinType.value,
      'type': type.name,
      'status': status.name,
      'amount': amount.toString(),
      'fee': fee.toString(),
      'hash': hash,
      'confirmations': confirmations,
      'timestamp': timestamp.toIso8601String(),
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'memo': memo,
      'decimals': decimals,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      accountId: json['accountId'],
      address: json['address'],
      coinType: _coinTypeFromValue(json['coinTypeValue']),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.pending,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      amount: BigInt.parse(json['amount']),
      fee: BigInt.parse(json['fee']),
      hash: json['hash'],
      confirmations: json['confirmations'],
      timestamp: DateTime.parse(json['timestamp']),
      fromAddress: json['fromAddress'],
      toAddress: json['toAddress'],
      memo: json['memo'],
      decimals: json['decimals'],
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

  TransactionModel copyWith({
    String? id,
    String? accountId,
    String? address,
    CoinType? coinType,
    TransactionType? type,
    TransactionStatus? status,
    BigInt? amount,
    BigInt? fee,
    String? hash,
    int? confirmations,
    DateTime? timestamp,
    String? fromAddress,
    String? toAddress,
    String? memo,
    int? decimals,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      address: address ?? this.address,
      coinType: coinType ?? this.coinType,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      hash: hash ?? this.hash,
      confirmations: confirmations ?? this.confirmations,
      timestamp: timestamp ?? this.timestamp,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      memo: memo ?? this.memo,
      decimals: decimals ?? this.decimals,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, amount: $formattedAmount, status: $status)';
  }
}

/// Transaction history with pagination
class TransactionHistory {
  final List<TransactionModel> transactions;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;

  TransactionHistory({
    required this.transactions,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  /// Get total pages
  int get totalPages => (totalCount / pageSize).ceil();

  /// Check if there are any transactions
  bool get isEmpty => transactions.isEmpty;

  /// Check if there are transactions
  bool get isNotEmpty => transactions.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'totalCount': totalCount,
      'currentPage': currentPage,
      'pageSize': pageSize,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }

  factory TransactionHistory.fromJson(Map<String, dynamic> json) {
    final transactionsList = json['transactions'] as List<dynamic>;
    final transactions = transactionsList
        .map((t) => TransactionModel.fromJson(t))
        .toList();

    return TransactionHistory(
      transactions: transactions,
      totalCount: json['totalCount'],
      currentPage: json['currentPage'],
      pageSize: json['pageSize'],
      hasNextPage: json['hasNextPage'],
      hasPreviousPage: json['hasPreviousPage'],
    );
  }
}
