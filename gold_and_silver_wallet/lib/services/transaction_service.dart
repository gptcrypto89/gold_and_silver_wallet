import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/network_model.dart';
import 'package:hd_wallet/hd_wallet.dart';

/// Service for managing transaction history and data
class TransactionService extends ChangeNotifier {
  final Map<String, TransactionHistory> _transactionHistories = {};
  final Map<String, List<TransactionModel>> _allTransactions = {};

  Map<String, TransactionHistory> get transactionHistories => Map.unmodifiable(_transactionHistories);
  Map<String, List<TransactionModel>> get allTransactions => Map.unmodifiable(_allTransactions);

  /// Fetch transactions for an account with pagination
  Future<TransactionHistory> fetchTransactions(
    AccountModel account, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      NetworkModel network;
      if (account.coinType.value == 0) {
        // Bitcoin
        network = NetworkModel(
          id: 'bitcoin_mainnet',
          name: 'Bitcoin Mainnet',
          type: NetworkType.bitcoin,
          rpcUrl: 'https://blockstream.info/api',
          explorerUrl: 'https://blockstream.info',
          isTestnet: false,
          chainId: 0,
          symbol: 'BTC',
          decimals: 8,
        );
      } else if (account.coinType.value == 111111) {
        // Kaspa
        network = NetworkModel(
          id: 'kaspa_mainnet',
          name: 'Kaspa Mainnet',
          type: NetworkType.kaspa,
          rpcUrl: 'https://api.kaspa.org',
          explorerUrl: 'https://explorer.kaspa.org',
          isTestnet: false,
          chainId: 111111,
          symbol: 'KAS',
          decimals: 8,
        );
      } else {
        throw Exception('Unsupported coin type');
      }

      List<TransactionModel> transactions;
      int totalCount = 0;

      if (account.coinType.value == 0) {
        // Fetch Bitcoin transactions
        final result = await _fetchBitcoinTransactions(account, network, page, pageSize);
        transactions = result['transactions'];
        totalCount = result['totalCount'];
      } else if (account.coinType.value == 111111) {
        // Fetch Kaspa transactions
        final result = await _fetchKaspaTransactions(account, network, page, pageSize);
        transactions = result['transactions'];
        totalCount = result['totalCount'];
      } else {
        transactions = [];
        totalCount = 0;
      }
      
      final hasNextPage = (page * pageSize) < totalCount;
      final hasPreviousPage = page > 1;
      
      final history = TransactionHistory(
        transactions: transactions,
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
      );
      
      // Store the history
      _transactionHistories[account.id] = history;
      
      // Update all transactions list
      if (!_allTransactions.containsKey(account.id)) {
        _allTransactions[account.id] = [];
      }
      
      // Add new transactions to the list (avoid duplicates)
      for (final transaction in transactions) {
        if (!_allTransactions[account.id]!.any((t) => t.id == transaction.id)) {
          _allTransactions[account.id]!.add(transaction);
        }
      }
      
      // Sort by timestamp (newest first)
      _allTransactions[account.id]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      notifyListeners();
      return history;
    } catch (e) {
      rethrow;
    }
  }

  /// Get transaction history for an account
  TransactionHistory? getTransactionHistory(String accountId) {
    return _transactionHistories[accountId];
  }

  /// Get all transactions for an account
  List<TransactionModel> getAllTransactions(String accountId) {
    return _allTransactions[accountId] ?? [];
  }

  /// Get recent transactions (last 10)
  List<TransactionModel> getRecentTransactions(String accountId) {
    final all = getAllTransactions(accountId);
    return all.take(10).toList();
  }

  /// Clear transaction data for an account
  void clearTransactions(String accountId) {
    _transactionHistories.remove(accountId);
    _allTransactions.remove(accountId);
    notifyListeners();
  }

  /// Clear all transaction data
  void clearAllTransactions() {
    _transactionHistories.clear();
    _allTransactions.clear();
    notifyListeners();
  }

  /// Fetch Bitcoin transactions from blockchain
  Future<Map<String, dynamic>> _fetchBitcoinTransactions(
    AccountModel account, 
    NetworkModel network, 
    int page, 
    int pageSize
  ) async {
    try {
      // Use the precalculated address from the account
      if (account.address.isEmpty) {
        return {'transactions': <TransactionModel>[], 'totalCount': 0};
      }
      
      final address = account.address;
      final url = '${network.rpcUrl}/address/$address/txs';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        
        final transactions = <TransactionModel>[];
        
        for (int i = 0; i < data.length && i < pageSize; i++) {
          final tx = data[i];
          
          // Parse Bitcoin transaction structure
          final txid = tx['txid'] as String;
          final status = tx['status'] as Map<String, dynamic>;
          final isConfirmed = status['confirmed'] as bool;
          final blockTime = status['block_time'] as int?;
          final vout = tx['vout'] as List;
          final vin = tx['vin'] as List;
          final fee = tx['fee'] as int;
          
          // Calculate total amount from outputs
          BigInt totalAmount = BigInt.zero;
          for (final output in vout) {
            totalAmount += BigInt.parse((output['value'] * 100000000).toString()); // Convert to satoshis
          }
          
          // Determine if this is a received transaction
          // This is a simplified logic - in reality, you'd need to check if any output belongs to your address
          final isReceived = vout.isNotEmpty;
          
          final transaction = TransactionModel(
            id: txid,
            accountId: account.id,
            address: address,
            coinType: account.coinType,
            type: isReceived ? TransactionType.received : TransactionType.sent,
            status: isConfirmed ? TransactionStatus.confirmed : TransactionStatus.pending,
            amount: totalAmount,
            fee: BigInt.from(fee),
            hash: txid,
            confirmations: isConfirmed ? 6 : 0,
            timestamp: blockTime != null 
                ? DateTime.fromMillisecondsSinceEpoch(blockTime * 1000)
                : DateTime.now(),
            fromAddress: vin.isNotEmpty ? 'sender_address' : address,
            toAddress: vout.isNotEmpty ? address : 'recipient_address',
            memo: null,
            decimals: 8,
          );
          
          transactions.add(transaction);
        }
        
        return {
          'transactions': transactions,
          'totalCount': data.length,
        };
      }
      
      return {'transactions': <TransactionModel>[], 'totalCount': 0};
    } catch (e) {
      return {'transactions': <TransactionModel>[], 'totalCount': 0};
    }
  }

  /// Fetch Kaspa transactions from blockchain
  Future<Map<String, dynamic>> _fetchKaspaTransactions(
    AccountModel account, 
    NetworkModel network, 
    int page, 
    int pageSize
  ) async {
    try {
      // Use the precalculated address from the account
      if (account.address.isEmpty) {
        return {'transactions': <TransactionModel>[], 'totalCount': 0};
      }
      
      final address = account.address;
      // URL encode the address for Kaspa API
      final encodedAddress = Uri.encodeComponent(address);
      
      // First, get the total transaction count
      final countUrl = '${network.rpcUrl}/addresses/$encodedAddress/transactions-count';
      final countResponse = await http.get(
        Uri.parse(countUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      int totalCount = 0;
      if (countResponse.statusCode == 200) {
        final countData = json.decode(countResponse.body);
        totalCount = countData['total'] as int? ?? 0;
      }
      
      // Calculate offset for pagination (Kaspa API uses offset/limit, not page/pageSize)
      final offset = (page - 1) * pageSize;
      final url = '${network.rpcUrl}/addresses/$encodedAddress/full-transactions?limit=$pageSize&offset=$offset&resolve_previous_outpoints=no';
      
      // Use the correct Kaspa API endpoint for full transactions
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        
        // Get current sink blue score once for all transactions
        int? currentSinkBlueScore;
        try {
          final sinkResponse = await http.get(
            Uri.parse('${network.rpcUrl}/info'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));
          
          if (sinkResponse.statusCode == 200) {
            final sinkData = json.decode(sinkResponse.body);
            currentSinkBlueScore = sinkData['sink_blue_score'] as int?;
          }
        } catch (e) {
          // Will fall back to time-based estimation
        }
        
        final transactions = <TransactionModel>[];
        
        // Process all transactions returned by the API (already paginated)
        for (int i = 0; i < data.length; i++) {
          final tx = data[i];
          
          // Parse Kaspa transaction structure
          final transactionId = tx['transaction_id'] as String;
          final isAccepted = tx['is_accepted'] as bool;
          final blockTime = tx['block_time'] as int;
          final outputs = tx['outputs'] as List;
          final inputs = tx['inputs'] as List;
          
          // Calculate amounts for this specific address
          BigInt receivedAmount = BigInt.zero;
          BigInt sentAmount = BigInt.zero;
          String? fromAddress;
          String? toAddress;
          
          // Check outputs to see if any belong to our address (received)
          for (final output in outputs) {
            final outputAddress = output['script_public_key_address'] as String?;
            if (outputAddress == address) {
              receivedAmount += BigInt.parse(output['amount'].toString());
              toAddress = address;
            }
          }
          
          // For Kaspa, we need to determine sent transactions differently
          // since previous_outpoint_address is often null in the API response
          
          // Calculate total inputs and outputs to determine transaction flow
          BigInt totalInputs = BigInt.zero;
          BigInt totalOutputs = BigInt.zero;
          
          for (final input in inputs) {
            final inputAmount = input['previous_outpoint_amount'] as String?;
            if (inputAmount != null) {
              totalInputs += BigInt.parse(inputAmount);
            }
          }
          
          for (final output in outputs) {
            totalOutputs += BigInt.parse(output['amount'].toString());
          }
          
          // Determine transaction type based on the transaction structure
          // For Kaspa, we need to be more sophisticated about this
          TransactionType type;
          BigInt amount;
          
          if (receivedAmount > BigInt.zero) {
            // We received something, so this is a received transaction
            type = TransactionType.received;
            amount = receivedAmount;
            fromAddress = null; // We don't know the sender from this data
            toAddress = address;
          } else {
            // This is a sent transaction
            // The amount sent is the total outputs minus any change back to us
            // Since we didn't receive anything, the total outputs represent what we sent
            type = TransactionType.sent;
            amount = totalOutputs;
            fromAddress = address;
            toAddress = null; // We don't know the recipient from this data
          }
          
          // Calculate fee (difference between total inputs and outputs)
          final fee = totalInputs > totalOutputs ? totalInputs - totalOutputs : BigInt.zero;
          
          // Calculate confirmations for Kaspa
          // For Kaspa, confirmations = sink blue score - accepting block's blue score
          int confirmations = 0;
          if (isAccepted) {
            final acceptingBlockBlueScore = tx['accepting_block_blue_score'] as int?;
            if (acceptingBlockBlueScore != null) {
              if (currentSinkBlueScore != null) {
                // Use accurate calculation: current sink blue score - accepting block blue score
                confirmations = (currentSinkBlueScore - acceptingBlockBlueScore).clamp(0, 1000000);
              } else {
                // Fallback to time-based estimation if sink blue score is not available
                final now = DateTime.now();
                final txTime = DateTime.fromMillisecondsSinceEpoch(blockTime);
                final timeDiff = now.difference(txTime);
                confirmations = timeDiff.inSeconds.clamp(0, 1000000);
              }
            }
          }
          
          final transaction = TransactionModel(
            id: transactionId,
            accountId: account.id,
            address: address,
            coinType: account.coinType,
            type: type,
            status: isAccepted ? TransactionStatus.confirmed : TransactionStatus.pending,
            amount: amount,
            fee: fee,
            hash: transactionId, // Use transaction_id instead of hash for Kaspa explorer
            confirmations: confirmations,
            timestamp: DateTime.fromMillisecondsSinceEpoch(blockTime),
            fromAddress: fromAddress,
            toAddress: toAddress,
            memo: null,
            decimals: 8,
          );
          
          transactions.add(transaction);
        }
        
        return {
          'transactions': transactions,
          'totalCount': totalCount,
        };
      }
      
      return {'transactions': <TransactionModel>[], 'totalCount': 0};
    } catch (e) {
      return {'transactions': <TransactionModel>[], 'totalCount': 0};
    }
  }


  /// Save transaction data to storage
  Map<String, dynamic> toJson() {
    return {
      'transactionHistories': _transactionHistories.map((key, value) => MapEntry(key, value.toJson())),
      'allTransactions': _allTransactions.map((key, value) => MapEntry(key, value.map((t) => t.toJson()).toList())),
    };
  }

  /// Load transaction data from storage
  void fromJson(Map<String, dynamic> json) {
    _transactionHistories.clear();
    _allTransactions.clear();

    // Load transaction histories
    final historiesJson = json['transactionHistories'] as Map<String, dynamic>? ?? {};
    for (final entry in historiesJson.entries) {
      _transactionHistories[entry.key] = TransactionHistory.fromJson(entry.value);
    }

    // Load all transactions
    final allTransactionsJson = json['allTransactions'] as Map<String, dynamic>? ?? {};
    for (final entry in allTransactionsJson.entries) {
      final transactionsList = entry.value as List<dynamic>;
      _allTransactions[entry.key] = transactionsList
          .map((t) => TransactionModel.fromJson(t))
          .toList();
    }

    notifyListeners();
  }
}
