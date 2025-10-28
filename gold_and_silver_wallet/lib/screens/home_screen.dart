import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_manager.dart';
import '../services/network_service.dart';
import '../models/wallet_model.dart';
import '../models/account_model.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/animated_fab.dart';
import 'package:hd_wallet/hd_wallet.dart';
import 'create_wallet_screen.dart';
import 'import_wallet_screen.dart';
import 'wallet_detail_screen.dart';
import 'settings_screen.dart';
import '../services/security_service.dart';

/// Home screen - wallet list and management
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<WalletManager, NetworkService>(
      builder: (context, walletManager, networkService, child) {
        final wallets = walletManager.wallets;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
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
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                const Text('Bitcoin is Gold, Kaspa is Silver'),
              ],
            ),
            actions: [
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
          body: wallets.isEmpty
              ? _buildEmptyState(context)
              : _buildWalletList(context, wallets, walletManager, networkService),
          floatingActionButton: _buildFloatingActionButtons(context, wallets),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space48),
          EmptyStateCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Welcome to Bitcoin is Gold, Kaspa is Silver',
            subtitle: 'Create your first wallet to start managing your Bitcoin and Kaspa accounts securely',
            actionText: 'Create Wallet',
            onAction: () async {
              final security = SecurityService();
              final canProceed = await security.showSecurityWarningDialog(context);
              if (!context.mounted || !canProceed) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateWalletScreen(),
                ),
              );
            },
            accentColor: AppTheme.primaryGold,
          ),
          const SizedBox(height: AppTheme.space24),
          ModernCard(
            backgroundColor: AppTheme.secondarySilverSurface,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondarySilver,
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Existing Wallet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            'Already have a recovery phrase? Import your wallet to get started.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final security = SecurityService();
                      final canProceed = await security.showSecurityWarningDialog(context);
                      if (!context.mounted || !canProceed) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImportWalletScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Import Wallet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondarySilver,
                      side: BorderSide(color: AppTheme.secondarySilver, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletList(BuildContext context, List<WalletModel> wallets, 
      WalletManager walletManager, NetworkService networkService) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.space16),
      itemCount: wallets.length,
      itemBuilder: (context, index) {
          final wallet = wallets[index];
          final accounts = walletManager.getAccountsForWallet(wallet.id);
          
          return WalletCard(
            title: wallet.name,
            subtitle: '${wallet.wordCount} words • ${accounts.length} accounts',
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGoldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              child: Center(
                child: Text(
                  wallet.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editWalletName(context, wallet, walletManager);
                } else if (value == 'delete') {
                  _confirmDeleteWallet(context, wallet, walletManager);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.blue),
                      SizedBox(width: AppTheme.space8),
                      Text('Edit Name'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: AppTheme.space8),
                      Text('Delete Wallet'),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
            onTap: () {
              walletManager.setCurrentWallet(wallet);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletDetailScreen(wallet: wallet),
                ),
              );
            },
            hasPassphrase: wallet.hasPassphrase,
            accountCount: accounts.length,
            createdAt: wallet.createdAt,
            accentColor: AppTheme.primaryGold,
          );
        },
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context, List<WalletModel> wallets) {
    if (wallets.isEmpty) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop layout - side by side
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedFAB(
                onPressed: () async {
                  final security = SecurityService();
                  final canProceed = await security.showSecurityWarningDialog(context);
                  if (!context.mounted || !canProceed) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWalletScreen(),
                    ),
                  );
                },
                icon: Icons.add_rounded,
                label: 'Create Wallet',
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                isExtended: true,
              ),
              const SizedBox(width: AppTheme.space12),
              AnimatedFAB(
                onPressed: () async {
                  final security = SecurityService();
                  final canProceed = await security.showSecurityWarningDialog(context);
                  if (!context.mounted || !canProceed) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImportWalletScreen(),
                    ),
                  );
                },
                icon: Icons.download_rounded,
                label: 'Import Wallet',
                backgroundColor: AppTheme.secondarySilver,
                foregroundColor: Colors.white,
                isExtended: true,
              ),
            ],
          );
        } else {
          // Mobile layout - speed dial
          return SpeedDialFAB(
            mainIcon: Icons.add_rounded,
            backgroundColor: AppTheme.primaryGold,
            foregroundColor: Colors.white,
            items: [
              SpeedDialItem(
                icon: Icons.add_rounded,
                label: 'Create Wallet',
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                onPressed: () async {
                  final security = SecurityService();
                  final canProceed = await security.showSecurityWarningDialog(context);
                  if (!context.mounted || !canProceed) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWalletScreen(),
                    ),
                  );
                },
              ),
              SpeedDialItem(
                icon: Icons.download_rounded,
                label: 'Import Wallet',
                backgroundColor: AppTheme.secondarySilver,
                foregroundColor: Colors.white,
                onPressed: () async {
                  final security = SecurityService();
                  final canProceed = await security.showSecurityWarningDialog(context);
                  if (!context.mounted || !canProceed) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImportWalletScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }


  void _editWalletName(BuildContext context, WalletModel wallet, WalletManager manager) {
    final controller = TextEditingController(text: wallet.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Wallet Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Wallet Name',
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
              if (newName.isNotEmpty && newName != wallet.name) {
                final updatedWallet = WalletModel(
                  id: wallet.id,
                  name: newName,
                  mnemonic: wallet.mnemonic,
                  passphrase: wallet.passphrase,
                  createdAt: wallet.createdAt,
                  wordCount: wallet.wordCount,
                );
                manager.updateWallet(updatedWallet);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wallet name updated')),
                );
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _confirmDeleteWallet(BuildContext context, WalletModel wallet, WalletManager manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Wallet?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${wallet.name}"?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ This action cannot be undone!\n\n'
              'Make sure you have your recovery phrase saved before deleting.',
              style: TextStyle(color: Colors.red),
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
              final networkService = context.read<NetworkService>();
              
              // Remove wallet from manager
              manager.removeWallet(wallet.id);
              
              // Clear all balances for this wallet
              networkService.clearBalancesForWallet(wallet.id);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Wallet "${wallet.name}" deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

}

