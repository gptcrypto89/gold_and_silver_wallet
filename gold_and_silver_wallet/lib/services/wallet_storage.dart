import '../models/wallet_model.dart';
import '../models/account_model.dart';
import 'encrypted_storage.dart';

/// Wallet storage service - handles serialization and persistence
class WalletStorage {
  final EncryptedStorage _storage = EncryptedStorage();

  /// Check if password is configured
  Future<bool> hasPassword() => _storage.hasPassword();

  /// Set initial password
  Future<void> setPassword(String password) => _storage.setPassword(password);

  /// Verify password
  Future<bool> verifyPassword(String password) => _storage.verifyPassword(password);

  /// Change password
  Future<void> changePassword(String oldPassword, String newPassword) =>
      _storage.changePassword(oldPassword, newPassword);

  /// Save wallets and accounts
  Future<void> saveWallets({
    required List<WalletModel> wallets,
    required Map<String, List<AccountModel>> accounts,
    required String password,
  }) async {
    final data = {
      'version': 1,
      'wallets': wallets.map((w) => w.toJson()).toList(),
      'accounts': accounts.map((key, value) => MapEntry(
            key,
            value.map((a) => a.toJson()).toList(),
          )),
      'savedAt': DateTime.now().toIso8601String(),
    };

    await _storage.saveData(data, password);
  }

  /// Load wallets and accounts
  Future<Map<String, dynamic>?> loadWallets(String password) async {
    try {
      final data = await _storage.loadData(password);
      if (data == null) return null;

      // Parse wallets
      final walletsData = data['wallets'] as List<dynamic>?;
      final wallets = walletsData?.map((w) => WalletModel.fromJson(w as Map<String, dynamic>)).toList() ?? [];

      // Parse accounts
      final accountsData = data['accounts'] as Map<String, dynamic>?;
      final accounts = <String, List<AccountModel>>{};
      
      if (accountsData != null) {
        accountsData.forEach((key, value) {
          final accountsList = (value as List<dynamic>)
              .map((a) => AccountModel.fromJson(a as Map<String, dynamic>))
              .toList();
          accounts[key] = accountsList;
        });
      }

      return {
        'wallets': wallets,
        'accounts': accounts,
      };
    } catch (e) {
      throw Exception('Failed to load wallets: $e');
    }
  }

  /// Delete all data
  Future<void> deleteAll() => _storage.deleteAll();

  /// Export backup
  Future<List<int>?> exportBackup(String password) async {
    final backup = await _storage.exportBackup(password);
    return backup?.toList();
  }

  /// Import backup
  Future<void> importBackup(List<int> backupData, String password) async {
    await _storage.importBackup(backupData as dynamic, password);
  }
}

