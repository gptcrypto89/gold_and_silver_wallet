import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/network_model.dart';
import '../models/balance_model.dart';
import '../models/account_model.dart';
import 'package:hd_wallet/hd_wallet.dart';

/// Service for managing network configurations and balance fetching
class NetworkService extends ChangeNotifier {
  final Map<String, NetworkModel> _networks = {};
  final Map<String, BalanceModel> _balances = {};
  final Map<String, NetworkModel> _selectedNetworks = {}; // coinType -> selected network

  Map<String, NetworkModel> get networks => Map.unmodifiable(_networks);
  Map<String, BalanceModel> get balances => Map.unmodifiable(_balances);
  Map<String, NetworkModel> get selectedNetworks => Map.unmodifiable(_selectedNetworks);

  /// Initialize with default networks
  void initializeDefaultNetworks() {
    // Add all predefined networks
    for (final network in NetworkPresets.getAllNetworks()) {
      _networks[network.id] = network;
    }

    // Set default selected networks
    _selectedNetworks[CoinType.bitcoin.name] = NetworkPresets.getDefaultNetwork(NetworkType.bitcoin)!;
    _selectedNetworks[CoinType.kaspa.name] = NetworkPresets.getDefaultNetwork(NetworkType.kaspa)!;

    notifyListeners();
  }

  /// Add a custom network
  void addNetwork(NetworkModel network) {
    _networks[network.id] = network;
    notifyListeners();
  }

  /// Update an existing network
  void updateNetwork(NetworkModel network) {
    _networks[network.id] = network;
    notifyListeners();
  }

  /// Remove a network
  void removeNetwork(String networkId) {
    _networks.remove(networkId);
    notifyListeners();
  }

  /// Set selected network for a coin type
  void setSelectedNetwork(CoinType coinType, NetworkModel network) {
    _selectedNetworks[coinType.name] = network;
    notifyListeners();
  }

  /// Get selected network for a coin type
  NetworkModel? getSelectedNetwork(CoinType coinType) {
    return _selectedNetworks[coinType.name];
  }

  /// Get networks for a specific coin type
  List<NetworkModel> getNetworksForCoin(CoinType coinType) {
    final networkType = _getNetworkTypeFromCoinType(coinType);
    return _networks.values
        .where((network) => network.type == networkType)
        .toList();
  }

  /// Get available networks for a coin type (including testnet if available)
  List<NetworkModel> getAvailableNetworks(CoinType coinType) {
    final networks = getNetworksForCoin(coinType);
    return networks;
  }

  /// Fetch balance for an account
  Future<BalanceModel?> fetchBalance(AccountModel account) async {
    try {
      final selectedNetwork = getSelectedNetwork(account.coinType);
      if (selectedNetwork == null) {
        return null;
      }

      // Use the precalculated address from the account
      if (account.address.isEmpty) {
        return null;
      }
      
      // Fetch balance from network using the stored address
      final balance = await _fetchBalanceFromNetwork(account.address, selectedNetwork, account.id);
      
      if (balance != null) {
        _balances[account.id] = balance;
        notifyListeners();
      }
      
      return balance;
    } catch (e) {
      return null;
    }
  }

  /// Fetch balances for multiple accounts
  Future<Map<String, BalanceModel>> fetchBalances(List<AccountModel> accounts) async {
    final results = <String, BalanceModel>{};
    
    for (final account in accounts) {
      try {
        final balance = await fetchBalance(account);
        if (balance != null) {
          results[account.id] = balance;
        }
      } catch (e) {
        // Silent error handling
      }
    }
    
    return results;
  }

  /// Get balance for a specific account
  BalanceModel? getBalanceForAccount(String accountId) {
    return _balances[accountId];
  }

  /// Get balance summary for all accounts
  BalanceSummary getBalanceSummary() {
    return BalanceSummary(
      balances: Map.from(_balances),
      lastUpdated: DateTime.now(),
    );
  }

  /// Clear all balances
  void clearBalances() {
    _balances.clear();
    notifyListeners();
  }

  /// Clear balance for a specific account
  void clearBalanceForAccount(String accountId) {
    _balances.remove(accountId);
    notifyListeners();
  }

  /// Clear balances for all accounts in a wallet
  void clearBalancesForWallet(String walletId) {
    _balances.removeWhere((accountId, balance) => accountId.startsWith(walletId));
    notifyListeners();
  }

  /// Clear orphaned balances (balances for accounts that no longer exist)
  void clearOrphanedBalances(List<String> existingAccountIds) {
    final existingIds = Set<String>.from(existingAccountIds);
    _balances.removeWhere((accountId, balance) => !existingIds.contains(accountId));
    notifyListeners();
  }




  /// Private helper methods
  NetworkType _getNetworkTypeFromCoinType(CoinType coinType) {
    switch (coinType.value) {
      case 0:
        return NetworkType.bitcoin;
      case 111111:
        return NetworkType.kaspa;
      default:
        return NetworkType.bitcoin;
    }
  }

  String _generateAddressForAccount(AccountModel account, HDWallet hdWallet) {
    try {
      // Use the account's derivation path if available, otherwise use standard BIP44 path
      final derivationPath = account.derivationPath.isNotEmpty 
          ? account.derivationPath 
          : "m/44'/${account.coinType.value}'/${account.accountIndex}'/0/0";
      
      final walletAccount = hdWallet.deriveAccountFromPath(derivationPath, account.coinType);
      
      return walletAccount.address;
    } catch (e) {
      // Fallback to a placeholder if address generation fails
      return 'placeholder_address_${account.id}';
    }
  }

  Future<BalanceModel?> _fetchBalanceFromNetwork(String address, NetworkModel network, String accountId) async {
    try {
      if (network.type == NetworkType.bitcoin) {
        return await _fetchBitcoinBalance(address, network, accountId);
      } else if (network.type == NetworkType.kaspa) {
        return await _fetchKaspaBalance(address, network, accountId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<BalanceModel?> _fetchBitcoinBalance(String address, NetworkModel network, String accountId) async {
    try {
      final url = '${network.rpcUrl}/address/$address';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final balance = BigInt.parse(data['chain_stats']['funded_txo_sum'].toString());
        
        return BalanceModel(
          accountId: accountId,
          coinType: network.coinType,
          networkId: network.id,
          address: address,
          balance: balance,
          decimals: network.decimals,
          symbol: network.symbol,
          lastUpdated: DateTime.now(),
          isConfirmed: true,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<BalanceModel?> _fetchKaspaBalance(String address, NetworkModel network, String accountId) async {
    try {
      // URL encode the address for Kaspa API
      final encodedAddress = Uri.encodeComponent(address);
      final url = '${network.rpcUrl}/addresses/$encodedAddress/balance';
      
      // Add retry mechanism for network issues
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'GoldAndSilverWallet/1.0',
            },
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final balance = BigInt.parse(data['balance'].toString());
            
            return BalanceModel(
              accountId: accountId,
              coinType: network.coinType,
              networkId: network.id,
              address: address,
              balance: balance,
              decimals: network.decimals,
              symbol: network.symbol,
              lastUpdated: DateTime.now(),
              isConfirmed: true,
            );
          } else {
            if (attempt < 3) {
              await Future.delayed(Duration(seconds: attempt * 2));
              continue;
            }
          }
        } catch (e) {
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save network configurations to storage
  Map<String, dynamic> toJson() {
    return {
      'networks': _networks.map((key, value) => MapEntry(key, value.toJson())),
      'selectedNetworks': _selectedNetworks.map((key, value) => MapEntry(key, value.toJson())),
      'balances': _balances.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Load network configurations from storage
  void fromJson(Map<String, dynamic> json) {
    _networks.clear();
    _selectedNetworks.clear();
    _balances.clear();

    // Load networks
    final networksJson = json['networks'] as Map<String, dynamic>? ?? {};
    for (final entry in networksJson.entries) {
      _networks[entry.key] = NetworkModel.fromJson(entry.value);
    }

    // Load selected networks
    final selectedNetworksJson = json['selectedNetworks'] as Map<String, dynamic>? ?? {};
    for (final entry in selectedNetworksJson.entries) {
      _selectedNetworks[entry.key] = NetworkModel.fromJson(entry.value);
    }

    // Load balances
    final balancesJson = json['balances'] as Map<String, dynamic>? ?? {};
    for (final entry in balancesJson.entries) {
      _balances[entry.key] = BalanceModel.fromJson(entry.value);
    }

    notifyListeners();
  }
}
