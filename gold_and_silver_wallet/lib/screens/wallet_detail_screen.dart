import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:hd_wallet/hd_wallet.dart';
import '../models/wallet_model.dart';
import '../models/account_model.dart';
import '../models/balance_model.dart';
import '../services/wallet_manager.dart';
import '../services/network_service.dart';
import '../services/encrypted_storage.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/animated_fab.dart';
import '../widgets/provider_selection_widget.dart';
import 'account_view_screen.dart';
import 'settings_screen.dart';

/// Wallet detail screen - manage accounts and view wallet info
class WalletDetailScreen extends StatefulWidget {
  final WalletModel wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late HDWallet _hdWallet;
  final SecurityService _securityService = SecurityService();
  
  // Auto-refresh timer
  Timer? _balanceRefreshTimer;

  @override
  void initState() {
    super.initState();
    _hdWallet = HDWallet.fromMnemonic(
      widget.wallet.mnemonic,
      passphrase: widget.wallet.passphrase,
    );
    _fetchAllBalancesOnOpen();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _balanceRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh balances every 45 seconds
    _balanceRefreshTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (mounted) {
        _autoRefreshBalances();
      }
    });
  }

  void _autoRefreshBalances() async {
    try {
      final walletManager = context.read<WalletManager>();
      final networkService = context.read<NetworkService>();
      final accounts = walletManager.getAccountsForWallet(widget.wallet.id);
      
      if (accounts.isNotEmpty) {
        await networkService.fetchBalances(accounts);
      }
    } catch (e) {
      // Silent error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGoldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                widget.wallet.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showWalletInfo,
            tooltip: 'Wallet Info',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer2<WalletManager, NetworkService>(
        builder: (context, walletManager, networkService, child) {
          final accounts = walletManager.getAccountsForWallet(widget.wallet.id);

          return Column(
            children: [
              // Wallet summary card
              _buildWalletSummary(walletManager, networkService),
              
              // Accounts list
              Expanded(
                child: accounts.isEmpty
                    ? _buildEmptyAccounts()
                    : _buildAccountsList(accounts, networkService),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildWalletSummary(WalletManager walletManager, NetworkService networkService) {
    final accountCount = walletManager.getAccountsForWallet(widget.wallet.id).length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGoldGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                ),
                child: Center(
                  child: Text(
                    widget.wallet.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.wallet.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      '$accountCount account${accountCount != 1 ? 's' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'recovery') {
                    _showRecoveryPhraseDialog();
                  } else if (value == 'scan') {
                    _scanWallet();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'recovery',
                    child: Row(
                      children: [
                        Icon(Icons.key_rounded, color: Colors.blue),
                        SizedBox(width: AppTheme.space8),
                        Text('View Recovery Phrase'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'scan',
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: Colors.purple),
                        SizedBox(width: AppTheme.space8),
                        Text('Scan Wallet'),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      '${widget.wallet.wordCount} words',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              if (widget.wallet.hasPassphrase) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space12,
                    vertical: AppTheme.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radius8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: AppTheme.onSuccessContainer,
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        'Protected',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.onSuccessContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyAccounts() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: EmptyStateCard(
        icon: Icons.account_circle_outlined,
        title: 'No Accounts Yet',
        subtitle: 'Add a Bitcoin or Kaspa account to start managing addresses and balances',
        actionText: 'Create Account',
        onAction: () => _createAccount(CoinType.bitcoin),
        accentColor: AppTheme.primaryGold,
      ),
    );
  }

  Widget _buildAccountsList(List<AccountModel> accounts, NetworkService networkService) {
    return RefreshIndicator(
      onRefresh: () => _refreshAllBalances(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.space16),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          return _buildAccountCard(account, networkService);
        },
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop layout - side by side
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedFAB(
                onPressed: () => _createAccount(CoinType.bitcoin),
                icon: Icons.add_rounded,
                label: 'Create Gold Account',
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black87,
                isExtended: true,
              ),
              const SizedBox(width: AppTheme.space12),
              AnimatedFAB(
                onPressed: () => _createAccount(CoinType.kaspa),
                icon: Icons.add_rounded,
                label: 'Create Silver Account',
                backgroundColor: AppTheme.silverPrimary,
                foregroundColor: Colors.black87,
                isExtended: true,
              ),
            ],
          );
        } else {
          // Mobile layout - speed dial
          return SpeedDialFAB(
            mainIcon: Icons.add_rounded,
            backgroundColor: AppTheme.goldPrimary,
            foregroundColor: Colors.black87,
            items: [
              SpeedDialItem(
                icon: Icons.monetization_on_rounded,
                label: 'Gold Account',
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black87,
                onPressed: () => _createAccount(CoinType.bitcoin),
              ),
              SpeedDialItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Silver Account',
                backgroundColor: AppTheme.silverPrimary,
                foregroundColor: Colors.black87,
                onPressed: () => _createAccount(CoinType.kaspa),
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _refreshAllBalances() async {
    try {
      final walletManager = context.read<WalletManager>();
      final networkService = context.read<NetworkService>();
      final accounts = walletManager.getAccountsForWallet(widget.wallet.id);
      
      if (accounts.isNotEmpty) {
        await networkService.fetchBalances(accounts);
      }
    } catch (e) {
      // Silent error handling
    }
  }

  Widget _buildAccountCard(AccountModel account, NetworkService networkService) {
    final coinColor = _getCoinColor(account.coinType);
    final accountType = account.coinType.value == 0 ? 'Gold' : 'Silver';
    final balance = networkService.getBalanceForAccount(account.id);
    
    return AccountCard(
      name: account.name,
      type: accountType,
      balance: balance?.formattedBalance ?? '0.00 ${account.coinType.symbol}',
      derivationPath: _getAccountDerivationPath(account.derivationPath),
      signatureType: account.signatureTypeDisplayName,
      accentColor: coinColor,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddressViewScreen(
              wallet: widget.wallet,
              account: account,
            ),
          ),
        );
      },
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            _editAccount(account);
          } else if (value == 'delete') {
            _confirmDeleteAccount(account);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.blue),
                SizedBox(width: AppTheme.space8),
                Text('Edit Account'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: AppTheme.space8),
                Text('Delete Account'),
              ],
            ),
          ),
        ],
        child: Icon(Icons.more_vert_rounded, color: coinColor),
      ),
    );
  }

  Color _getCoinColor(CoinType coinType) {
    switch (coinType.value) {
      case 0:
        return const Color(0xFFD4AF37); // Gold - Bitcoin
      case 111111:
        return const Color(0xFFC0C0C0); // Silver - Kaspa
      default:
        return Colors.grey;
    }
  }

  String _getAccountDerivationPath(String fullPath) {
    // Remove the address part (last two segments) from the derivation path
    // e.g., "m/44'/0'/0'/0/0" becomes "m/44'/0'/0'"
    final parts = fullPath.split('/');
    if (parts.length >= 4) {
      return parts.take(parts.length - 2).join('/');
    }
    return fullPath;
  }

  void _createAccount(CoinType coinType) async {
    final canProceed = await _securityService.showSecurityWarningDialog(context);
    if (!mounted || !canProceed) return;

    showDialog(
      context: context,
      builder: (context) => _CreateAccountDialog(
        wallet: widget.wallet,
        hdWallet: _hdWallet,
        coinType: coinType,
      ),
    );
  }

  void _scanWallet() {
    showDialog(
      context: context,
      builder: (context) => _ScanWalletDialog(
        wallet: widget.wallet,
        hdWallet: _hdWallet,
      ),
    );
  }

  void _editAccountName(AccountModel account) {
    final controller = TextEditingController(text: account.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Account Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Account Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != account.name) {
                // Validate the new name
                String? validationError = null;
                final walletManager = context.read<WalletManager>();
                final existingAccounts = walletManager.getAccountsForWallet(widget.wallet.id);
                
                // Check for duplicate account name (excluding current account)
                for (final existingAccount in existingAccounts) {
                  if (existingAccount.id != account.id && 
                      existingAccount.name.toLowerCase() == newName.toLowerCase()) {
                    validationError = 'Account name "$newName" already exists. Please choose a different name.';
                    break;
                  }
                }
                if (validationError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(validationError),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                final updatedAccount = AccountModel(
                  id: account.id,
                  walletId: account.walletId,
                  name: newName,
                  coinType: account.coinType,
                  accountIndex: account.accountIndex,
                  derivationPath: account.derivationPath,
                  signatureType: account.signatureType,
                  address: account.address, // Keep the same address
                );
                context.read<WalletManager>().updateAccount(updatedAccount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account name updated')),
                );
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _editAccount(AccountModel account) {
    final nameController = TextEditingController(text: account.name);
    final indexController = TextEditingController(text: account.accountIndex.toString());
    SignatureType selectedSignatureType = account.signatureType;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Account'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      // Trigger validation update
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: indexController,
                  decoration: const InputDecoration(
                    labelText: 'Account Index',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                    helperText: 'BIP44 account index',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final newName = nameController.text.trim();
                    if (newName.isEmpty) return const SizedBox.shrink();
                    
                    final walletManager = context.read<WalletManager>();
                    final existingAccounts = walletManager.getAccountsForWallet(widget.wallet.id);
                    
                    // Check for duplicate account name (excluding current account)
                    bool hasNameConflict = false;
                    for (final existingAccount in existingAccounts) {
                      if (existingAccount.id != account.id && 
                          existingAccount.name.toLowerCase() == newName.toLowerCase()) {
                        hasNameConflict = true;
                        break;
                      }
                    }
                    
                    if (hasNameConflict) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningContainer,
                          border: Border.all(color: AppTheme.warning),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, size: 16, color: AppTheme.onWarningContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Account name already exists',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.onWarningContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
                SignatureTypeSelectionWidget(
                  coinType: account.coinType,
                  initialSignatureType: selectedSignatureType,
                  onSignatureTypeChanged: (signatureType) {
                    setState(() {
                      selectedSignatureType = signatureType;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                indexController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                final newIndex = int.tryParse(indexController.text) ?? account.accountIndex;
                
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account name cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Validate changes
                String? validationError = null;
                final walletManager = context.read<WalletManager>();
                final existingAccounts = walletManager.getAccountsForWallet(widget.wallet.id);
                
                // Check for duplicate account name (excluding current account)
                for (final existingAccount in existingAccounts) {
                  if (existingAccount.id != account.id && 
                      existingAccount.name.toLowerCase() == newName.toLowerCase()) {
                    validationError = 'Account name "$newName" already exists. Please choose a different name.';
                    break;
                  }
                }
                
                // Only check for duplicate names - allow same derivation path, index, and signature type
                
                if (validationError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(validationError),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                // Update account
                final updatedAccount = AccountModel(
                  id: account.id,
                  walletId: account.walletId,
                  name: newName,
                  coinType: account.coinType,
                  accountIndex: newIndex,
                  derivationPath: "m/44'/${account.coinType.value}'/$newIndex'/0/0",
                  signatureType: selectedSignatureType,
                  address: account.address, // Keep existing address for now
                );
                
                walletManager.updateAccount(updatedAccount);
                
                nameController.dispose();
                indexController.dispose();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(AccountModel account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Text('Delete Account?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete "${account.name}"?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will remove the account from your wallet. '
              'You can recreate it later with the same recovery phrase.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final walletManager = context.read<WalletManager>();
              final networkService = context.read<NetworkService>();
              
              // Remove account from wallet manager
              walletManager.removeAccount(account.id);
              
              // Clear balance for this account
              networkService.clearBalanceForAccount(account.id);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account "${account.name}" deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRecoveryPhraseDialog() async {
    // Check if device is offline before showing recovery phrase
    final canProceed = await _securityService.showSecurityWarningDialog(context);
    
    if (!canProceed || !mounted) return;
    
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => const _PasswordDialog(),
    );
    
    if (result != null && result.isNotEmpty) {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      try {
        final storage = EncryptedStorage();
        final isValid = await storage.verifyPassword(result);
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        
        if (isValid) {
          _showRecoveryPhraseAfterAuth();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRecoveryPhraseAfterAuth() {
    bool isVisible = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.key, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Recovery Phrase'),
              const Spacer(),
              Chip(
                label: Text('${widget.wallet.wordCount} words'),
                backgroundColor: AppTheme.primaryGoldSurface,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      border: Border.all(color: AppTheme.error),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppTheme.onErrorContainer, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Keep this phrase secure and private!',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isVisible ? AppTheme.primaryGoldSurface : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isVisible ? AppTheme.primaryGold : Colors.grey[400]!,
                      ),
                    ),
                    child: isVisible
                        ? SelectableText(
                            widget.wallet.mnemonic,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off, size: 32, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Recovery phrase hidden',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            isVisible = !isVisible;
                          });
                        },
                        icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
                        label: Text(isVisible ? 'Hide' : 'Show'),
                      ),
                      if (isVisible)
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.wallet.mnemonic));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recovery phrase copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wallet Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', widget.wallet.name),
            _buildInfoRow('Word Count', '${widget.wallet.wordCount} words'),
            _buildInfoRow('Passphrase', widget.wallet.hasPassphrase ? '✓ Protected' : 'None'),
            _buildInfoRow('Created', _formatDate(widget.wallet.createdAt)),
            _buildInfoRow('ID', widget.wallet.id),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _fetchAllBalancesOnOpen() async {
    try {
      final walletManager = context.read<WalletManager>();
      final networkService = context.read<NetworkService>();
      final accounts = walletManager.getAccountsForWallet(widget.wallet.id);
      
      // Clear orphaned balances first - defer notification to avoid setState during build
      final accountIds = accounts.map((a) => a.id).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        networkService.clearOrphanedBalances(accountIds);
      });
      
      if (accounts.isNotEmpty) {
        await networkService.fetchBalances(accounts);
      }
    } catch (e) {
      // Don't show error to user on automatic fetch
    }
  }

}

/// Dialog for creating a new account
class _CreateAccountDialog extends StatefulWidget {
  final WalletModel wallet;
  final HDWallet hdWallet;
  final CoinType coinType;

  const _CreateAccountDialog({
    required this.wallet,
    required this.hdWallet,
    required this.coinType,
  });

  @override
  State<_CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<_CreateAccountDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _indexController = TextEditingController(text: '0');
  int _accountIndex = 0;
  SignatureType _selectedSignatureType = SignatureType.schnorr;

  @override
  void initState() {
    super.initState();
    // Set default name based on coin type
    final accountType = widget.coinType.value == 0 ? 'Gold' : 'Silver';
    _nameController.text = '$accountType Account';
    
    // Initialize signature type with the first available signature type
    final availableSignatureTypes = AccountModel.getAvailableSignatureTypes(widget.coinType);
    _selectedSignatureType = availableSignatureTypes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _indexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountType = widget.coinType.value == 0 ? 'Gold' : 'Silver';
    final coinName = widget.coinType.name;
    final coinSymbol = widget.coinType.symbol;
    final accountColor = widget.coinType.value == 0 
        ? const Color(0xFFD4AF37) // Gold
        : const Color(0xFFC0C0C0); // Silver
    final foregroundColor = Colors.black87;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return AlertDialog(
          title: constraints.maxWidth > 400
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accountColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.coinType.symbol,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Create $accountType Account'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accountColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.coinType.symbol,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Create $accountType Account'),
                ],
              ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight * 0.8,
              maxWidth: constraints.maxWidth > 600 ? 500 : constraints.maxWidth * 0.9,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accountColor.withOpacity(0.1),
                border: Border.all(color: accountColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: accountColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$coinName ($coinSymbol)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'BIP44 Standard Derivation',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g., My Gold Account',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _indexController,
              decoration: const InputDecoration(
                labelText: 'Account Index',
                hintText: '0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                helperText: 'BIP44 account index (usually 0)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _accountIndex = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Path: m/44\'/${widget.coinType.value}\'/$_accountIndex\'/0/0',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildValidationStatus(),
            const SizedBox(height: 16),
            SignatureTypeSelectionWidget(
              coinType: widget.coinType,
              initialSignatureType: _selectedSignatureType,
              onSignatureTypeChanged: (signatureType) {
                if (mounted) {
                  setState(() {
                    _selectedSignatureType = signatureType;
                  });
                }
              },
            ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _createAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: accountColor,
                foregroundColor: foregroundColor,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }


  String? _validateAccountCreation(String name, String derivationPath) {
    final walletManager = context.read<WalletManager>();
    final existingAccounts = walletManager.getAccountsForWallet(widget.wallet.id);
    
    // Check for duplicate account name
    for (final account in existingAccounts) {
      if (account.name.toLowerCase() == name.toLowerCase()) {
        return 'Account name "$name" already exists. Please choose a different name.';
      }
    }
    
    // Only check for duplicate names - allow same derivation path, index, and signature type
    
    // Only check for duplicate names - allow same derivation path, index, signature type, and address
    
    return null; // No validation errors
  }


  Widget _buildValidationStatus() {
    final name = _nameController.text.trim().isEmpty
        ? '${widget.coinType.value == 0 ? 'Gold' : 'Silver'} Account'
        : _nameController.text.trim();
    final derivationPath = "m/44'/${widget.coinType.value}'/$_accountIndex'/0/0";
    
    // Check for potential conflicts
    final walletManager = context.read<WalletManager>();
    final existingAccounts = walletManager.getAccountsForWallet(widget.wallet.id);
    
    bool hasNameConflict = false;
    
    String conflictingAccountName = '';
    for (final account in existingAccounts) {
      if (account.name.toLowerCase() == name.toLowerCase()) {
        hasNameConflict = true;
        conflictingAccountName = account.name;
        break;
      }
    }
    
    // Only show conflicts for duplicate names
    if (hasNameConflict) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.warningContainer,
          border: Border.all(color: AppTheme.warning),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, size: 16, color: AppTheme.onWarningContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Account name "$conflictingAccountName" already exists',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onWarningContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.successContainer,
        border: Border.all(color: AppTheme.success),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: AppTheme.onSuccessContainer),
          const SizedBox(width: 8),
          Text(
            'Account configuration is valid',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.onSuccessContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _createAccount() {
    final accountType = widget.coinType.value == 0 ? 'Gold' : 'Silver';
    final name = _nameController.text.trim().isEmpty
        ? '$accountType Account'
        : _nameController.text.trim();

    final derivationPath = "m/44'/${widget.coinType.value}'/$_accountIndex'/0/0";

    // Validate account creation
    final validationError = _validateAccountCreation(name, derivationPath);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Precalculate the address using the HD wallet
    String address;
    try {
      // Use signature type for address generation
      final account = widget.hdWallet.deriveAccountFromPath(derivationPath, widget.coinType, signatureType: _selectedSignatureType);
      address = account.address;
      } catch (e) {
        // Fallback to placeholder if address generation fails
        address = 'address_${widget.coinType.symbol}_${_accountIndex}';
      }

    final accountModel = AccountModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      walletId: widget.wallet.id,
      name: name,
      coinType: widget.coinType,
      accountIndex: _accountIndex,
      derivationPath: derivationPath,
      signatureType: _selectedSignatureType,
      address: address,
    );

    final walletManager = context.read<WalletManager>();
    final networkService = context.read<NetworkService>();
    
    // Add account to wallet manager
    walletManager.addAccount(accountModel);
    
    // Fetch balance for the new account
    networkService.fetchBalance(accountModel);
    
    Navigator.pop(context);
  }
}

/// Password dialog for recovery phrase authentication
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.red),
          SizedBox(width: 8),
          Text('Enter Password'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your application password to view the recovery phrase.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => Navigator.pop(context, _passwordController.text),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _passwordController.text),
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

/// Dialog for scanning wallet to discover existing accounts
class _ScanWalletDialog extends StatefulWidget {
  final WalletModel wallet;
  final HDWallet hdWallet;

  const _ScanWalletDialog({
    required this.wallet,
    required this.hdWallet,
  });

  @override
  State<_ScanWalletDialog> createState() => _ScanWalletDialogState();
}

class _ScanWalletDialogState extends State<_ScanWalletDialog> {
  bool _isScanning = false;
  String _currentStatus = '';
  int _totalScans = 0;
  int _completedScans = 0;
  int _foundAccounts = 0;
  List<AccountModel> _discoveredAccounts = [];
  bool _scanCompleted = false;
  
  // User input controllers
  final TextEditingController _accountIndexesController = TextEditingController(text: '2');
  final TextEditingController _addressIndexesController = TextEditingController(text: '3');

  @override
  void dispose() {
    _accountIndexesController.dispose();
    _addressIndexesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.search, color: Colors.purple),
          const SizedBox(width: 8),
          const Text('Scan Wallet'),
          const Spacer(),
          if (_isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (!_scanCompleted) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGoldSurface,
                  border: Border.all(color: AppTheme.primaryGold),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Wallet Discovery',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will scan multiple account indexes, address indexes, and signature types to discover existing accounts with balances.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Input fields for scan parameters
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _accountIndexesController,
                      decoration: InputDecoration(
                        labelText: 'Account Indexes',
                        hintText: '2',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        helperText: 'Number of account indexes to scan (0 to N-1)',
                        errorText: _getAccountIndexError(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() {}), // Trigger rebuild for validation
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _addressIndexesController,
                      decoration: InputDecoration(
                        labelText: 'Address Indexes',
                        hintText: '3',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                        helperText: 'Number of address indexes to scan (0 to N-1)',
                        errorText: _getAddressIndexError(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() {}), // Trigger rebuild for validation
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final accountCount = int.tryParse(_accountIndexesController.text) ?? 2;
                  final addressCount = int.tryParse(_addressIndexesController.text) ?? 3;
                  final totalScans = accountCount * addressCount * 2 * 2; // 2 coin types, 2 signature types (Schnorr + ECDSA)
                  
                  return Text(
                    'Will scan: Account indexes 0-${accountCount - 1}, Address indexes 0-${addressCount - 1}, Schnorr + ECDSA signature types ($totalScans total scans)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_isScanning) ...[
                LinearProgressIndicator(
                  value: _totalScans > 0 ? _completedScans / _totalScans : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondarySilver),
                ),
                const SizedBox(height: 8),
                Text(
                  'Progress: $_completedScans / $_totalScans',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentStatus,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                if (_foundAccounts > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Found $_foundAccounts account${_foundAccounts != 1 ? 's' : ''} with balances',
                    style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ] else ...[
              // Scan completed
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _foundAccounts > 0 ? AppTheme.successContainer : AppTheme.warningContainer,
                  border: Border.all(color: _foundAccounts > 0 ? AppTheme.success : AppTheme.warning),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _foundAccounts > 0 ? Icons.check_circle : Icons.info,
                          color: _foundAccounts > 0 ? AppTheme.onSuccessContainer : AppTheme.onWarningContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _foundAccounts > 0 ? 'Scan Complete!' : 'No Accounts Found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _foundAccounts > 0 ? AppTheme.onSuccessContainer : AppTheme.onWarningContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _foundAccounts > 0 
                          ? 'Found $_foundAccounts account${_foundAccounts != 1 ? 's' : ''} with balances. They will be added to your wallet.'
                          : 'No accounts with balances were found in the scanned range.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_discoveredAccounts.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Discovered Accounts:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(_discoveredAccounts.map((account) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCoinColor(account.coinType).withOpacity(0.1),
                    border: Border.all(color: _getCoinColor(account.coinType).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getCoinColor(account.coinType),
                        radius: 16,
                        child: Text(
                          account.coinType.symbol,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${account.coinType.name} • ${account.signatureTypeDisplayName}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _getAccountDerivationPath(account.derivationPath),
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))),
              ],
            ],
          ],
        ),
        ),
      ),
      actions: [
        if (!_scanCompleted) ...[
          TextButton(
            onPressed: _isScanning ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isScanning || _getAccountIndexError() != null || _getAddressIndexError() != null ? null : _startScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondarySilver,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Scan'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_foundAccounts > 0)
            ElevatedButton(
              onPressed: _addDiscoveredAccounts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
              child: const Text('Add Accounts'),
            ),
        ],
      ],
    );
  }

  Color _getCoinColor(CoinType coinType) {
    switch (coinType.value) {
      case 0:
        return const Color(0xFFD4AF37); // Gold - Bitcoin
      case 111111:
        return const Color(0xFFC0C0C0); // Silver - Kaspa
      default:
        return Colors.grey;
    }
  }

  String _getAccountDerivationPath(String fullPath) {
    // Remove the address part (last two segments) from the derivation path
    // e.g., "m/44'/0'/0'/0/0" becomes "m/44'/0'/0'"
    final parts = fullPath.split('/');
    if (parts.length >= 4) {
      return parts.take(parts.length - 2).join('/');
    }
    return fullPath;
  }

  String? _getAccountIndexError() {
    final value = int.tryParse(_accountIndexesController.text);
    if (value == null || value < 1 || value > 20) {
      return 'Enter 1-20';
    }
    return null;
  }

  String? _getAddressIndexError() {
    final value = int.tryParse(_addressIndexesController.text);
    if (value == null || value < 1 || value > 20) {
      return 'Enter 1-20';
    }
    return null;
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanCompleted = false;
      _discoveredAccounts.clear();
      _foundAccounts = 0;
      _completedScans = 0;
    });

    try {
      final walletManager = context.read<WalletManager>();
      final networkService = context.read<NetworkService>();
      final existingAccounts = walletManager.getAccountsForWallet(widget.wallet.id);
      final existingAddresses = existingAccounts.map((a) => a.address).toSet();

      // Get user input values
      final accountCount = int.tryParse(_accountIndexesController.text) ?? 2;
      final addressCount = int.tryParse(_addressIndexesController.text) ?? 3;
      
      // Validate input
      if (accountCount < 1 || accountCount > 20) {
        setState(() {
          _isScanning = false;
          _scanCompleted = true;
          _currentStatus = 'Invalid account count. Please enter 1-20.';
        });
        return;
      }
      
      if (addressCount < 1 || addressCount > 20) {
        setState(() {
          _isScanning = false;
          _scanCompleted = true;
          _currentStatus = 'Invalid address count. Please enter 1-20.';
        });
        return;
      }
      
      // Generate index arrays based on user input
      final accountIndexes = List.generate(accountCount, (i) => i);
      final addressIndexes = List.generate(addressCount, (i) => i);
      const coinTypes = [CoinType.bitcoin, CoinType.kaspa];
      
      int totalScans = 0;
      for (final coinType in coinTypes) {
        // Only scan Schnorr and ECDSA signature types
        final signatureTypes = [SignatureType.schnorr, SignatureType.ecdsa];
        totalScans += accountIndexes.length * addressIndexes.length * signatureTypes.length;
      }
      
      setState(() {
        _totalScans = totalScans;
      });

      final discoveredAccounts = <AccountModel>[];

      for (final coinType in coinTypes) {
        // Only scan Schnorr and ECDSA signature types
        final signatureTypes = [SignatureType.schnorr, SignatureType.ecdsa];
        
        for (final accountIndex in accountIndexes) {
          for (final addressIndex in addressIndexes) {
            for (final signatureType in signatureTypes) {
              if (!mounted) return;

              setState(() {
                _currentStatus = 'Scanning ${coinType.name} account $accountIndex, address $addressIndex, ${signatureType.name}...';
              });

              try {
                // Generate derivation path
                final derivationPath = "m/44'/${coinType.value}'/$accountIndex'/$addressIndex/$addressIndex";
                
                // Use signature type for address generation
                final account = widget.hdWallet.deriveAccountFromPath(
                  derivationPath, 
                  coinType, 
                  signatureType: signatureType
                );
                
                // Skip if address already exists
                if (existingAddresses.contains(account.address)) {
                  setState(() {
                    _completedScans++;
                  });
                  continue;
                }

                // Check balance for this address
                final balance = await _checkAddressBalance(account.address, coinType);
                
                if (balance != null && balance.isPositive) {
                  // Found an account with balance
                  final accountModel = AccountModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString() + '_${account.address}',
                    walletId: widget.wallet.id,
                    name: '${coinType.value == 0 ? 'Gold' : 'Silver'} Account $accountIndex',
                    coinType: coinType,
                    accountIndex: accountIndex,
                    derivationPath: derivationPath,
                    signatureType: signatureType,
                    address: account.address,
                  );
                  
                  discoveredAccounts.add(accountModel);
                  
                  setState(() {
                    _foundAccounts++;
                    _discoveredAccounts = List.from(discoveredAccounts);
                  });
                }
              } catch (e) {
                // Skip this combination if address generation fails
              }

              setState(() {
                _completedScans++;
              });

              // Small delay to prevent overwhelming the network
              await Future.delayed(const Duration(milliseconds: 100));
            }
          }
        }
      }

      setState(() {
        _isScanning = false;
        _scanCompleted = true;
        _currentStatus = 'Scan completed';
      });

    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanCompleted = true;
        _currentStatus = 'Scan failed: ${e.toString()}';
      });
    }
  }

  Future<BalanceModel?> _checkAddressBalance(String address, CoinType coinType) async {
    try {
      if (coinType.value == 0) {
        // Bitcoin balance check
        final response = await http.get(
          Uri.parse('https://blockstream.info/api/address/$address'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final balance = BigInt.parse(data['chain_stats']['funded_txo_sum'].toString());
          
          return BalanceModel(
            accountId: 'temp',
            coinType: coinType,
            networkId: 'bitcoin_mainnet',
            address: address,
            balance: balance,
            decimals: 8,
            symbol: 'BTC',
            lastUpdated: DateTime.now(),
            isConfirmed: true,
          );
        }
      } else if (coinType.value == 111111) {
        // Kaspa balance check
        final encodedAddress = Uri.encodeComponent(address);
        final response = await http.get(
          Uri.parse('https://api.kaspa.org/addresses/$encodedAddress/balance'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'GoldAndSilverWallet/1.0',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final balance = BigInt.parse(data['balance'].toString());
          
          return BalanceModel(
            accountId: 'temp',
            coinType: coinType,
            networkId: 'kaspa_mainnet',
            address: address,
            balance: balance,
            decimals: 8,
            symbol: 'KAS',
            lastUpdated: DateTime.now(),
            isConfirmed: true,
          );
        }
      }
    } catch (e) {
      // Silent error handling for network issues
    }
    
    return null;
  }

  void _addDiscoveredAccounts() {
    final walletManager = context.read<WalletManager>();
    final networkService = context.read<NetworkService>();
    
    for (final account in _discoveredAccounts) {
      walletManager.addAccount(account);
      networkService.fetchBalance(account);
    }
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_foundAccounts account${_foundAccounts != 1 ? 's' : ''} to your wallet'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

