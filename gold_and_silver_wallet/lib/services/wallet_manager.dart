import 'package:flutter/foundation.dart';
import '../models/wallet_model.dart';
import '../models/account_model.dart';
import 'wallet_storage.dart';
import 'package:hd_wallet/hd_wallet.dart';

/// Wallet manager service with encrypted persistence
class WalletManager extends ChangeNotifier {
  final WalletStorage _storage = WalletStorage();
  final List<WalletModel> _wallets = [];
  final Map<String, List<AccountModel>> _accounts = {};
  
  WalletModel? _currentWallet;
  AccountModel? _currentAccount;
  String? _password; // Current session password

  List<WalletModel> get wallets => List.unmodifiable(_wallets);
  WalletModel? get currentWallet => _currentWallet;
  AccountModel? get currentAccount => _currentAccount;

  List<AccountModel> getAccountsForWallet(String walletId) {
    return _accounts[walletId] ?? [];
  }

  /// Add a new wallet
  void addWallet(WalletModel wallet) {
    _wallets.add(wallet);
    _accounts[wallet.id] = [];
    _currentWallet = wallet;
    notifyListeners();
    _saveWallets();
  }

  /// Import existing wallet
  void importWallet(WalletModel wallet) {
    _wallets.add(wallet);
    _accounts[wallet.id] = [];
    _currentWallet = wallet;
    notifyListeners();
    _saveWallets();
  }

  /// Update wallet (e.g., rename)
  void updateWallet(WalletModel updatedWallet) {
    final index = _wallets.indexWhere((w) => w.id == updatedWallet.id);
    if (index != -1) {
      _wallets[index] = updatedWallet;
      if (_currentWallet?.id == updatedWallet.id) {
        _currentWallet = updatedWallet;
      }
      notifyListeners();
      _saveWallets();
    }
  }

  /// Remove wallet
  void removeWallet(String walletId) {
    _wallets.removeWhere((w) => w.id == walletId);
    _accounts.remove(walletId);
    
    if (_currentWallet?.id == walletId) {
      _currentWallet = _wallets.isNotEmpty ? _wallets.first : null;
    }
    
    notifyListeners();
    _saveWallets();
  }

  /// Set current wallet
  void setCurrentWallet(WalletModel wallet) {
    _currentWallet = wallet;
    
    // Set first account of this wallet as current
    final accounts = _accounts[wallet.id] ?? [];
    _currentAccount = accounts.isNotEmpty ? accounts.first : null;
    
    notifyListeners();
  }

  /// Add account to wallet
  void addAccount(AccountModel account) {
    if (!_accounts.containsKey(account.walletId)) {
      _accounts[account.walletId] = [];
    }
    
    _accounts[account.walletId]!.add(account);
    
    if (_currentWallet?.id == account.walletId) {
      _currentAccount = account;
    }
    
    notifyListeners();
    _saveWallets();
  }

  /// Update account (e.g., rename)
  void updateAccount(AccountModel updatedAccount) {
    final accounts = _accounts[updatedAccount.walletId];
    if (accounts != null) {
      final index = accounts.indexWhere((a) => a.id == updatedAccount.id);
      if (index != -1) {
        accounts[index] = updatedAccount;
        if (_currentAccount?.id == updatedAccount.id) {
          _currentAccount = updatedAccount;
        }
        notifyListeners();
        _saveWallets();
      }
    }
  }

  /// Remove account
  void removeAccount(String accountId) {
    for (final accounts in _accounts.values) {
      accounts.removeWhere((a) => a.id == accountId);
    }
    
    if (_currentAccount?.id == accountId) {
      final currentWalletAccounts = _accounts[_currentWallet?.id] ?? [];
      _currentAccount = currentWalletAccounts.isNotEmpty ? currentWalletAccounts.first : null;
    }
    
    notifyListeners();
    _saveWallets();
  }

  /// Set current account
  void setCurrentAccount(AccountModel account) {
    _currentAccount = account;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _wallets.clear();
    _accounts.clear();
    _currentWallet = null;
    _currentAccount = null;
    _password = null;
    notifyListeners();
  }

  // ==================== Persistence Methods ====================

  /// Check if password is set
  Future<bool> hasPassword() => _storage.hasPassword();

  /// Set session password and load wallets
  Future<bool> unlockWithPassword(String password) async {
    try {
      if (!await _storage.verifyPassword(password)) {
        return false;
      }

      _password = password;
      await _loadWallets(password);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set initial password
  Future<void> setInitialPassword(String password) async {
    await _storage.setPassword(password);
    _password = password;
    await _saveWallets(); // Save empty state
  }

  /// Change password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (_password == null) {
      throw Exception('Not unlocked');
    }

    await _storage.changePassword(oldPassword, newPassword);
    _password = newPassword;
  }

  /// Save wallets to encrypted storage
  Future<void> _saveWallets() async {
    if (_password == null) return;

    try {
      await _storage.saveWallets(
        wallets: _wallets,
        accounts: _accounts,
        password: _password!,
      );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Load wallets from encrypted storage
  Future<void> _loadWallets(String password) async {
    try {
      final data = await _storage.loadWallets(password);
      if (data == null) return;

      _wallets.clear();
      _accounts.clear();

      final wallets = data['wallets'] as List<WalletModel>;
      final accounts = data['accounts'] as Map<String, List<AccountModel>>;

      _wallets.addAll(wallets);
      _accounts.addAll(accounts);

      if (_wallets.isNotEmpty) {
        _currentWallet = _wallets.first;
        final currentAccounts = _accounts[_currentWallet!.id] ?? [];
        _currentAccount = currentAccounts.isNotEmpty ? currentAccounts.first : null;
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to load wallets: $e');
    }
  }

  /// Lock wallet (clear session)
  void lock() {
    clear();
  }

  /// Is currently unlocked
  bool get isUnlocked => _password != null;

  /// Export encrypted backup
  Future<List<int>?> exportBackup() async {
    if (_password == null) throw Exception('Not unlocked');
    return await _storage.exportBackup(_password!);
  }


  /// Delete all data (including password)
  Future<void> deleteAllData() async {
    await _storage.deleteAll();
    clear();
  }

}

