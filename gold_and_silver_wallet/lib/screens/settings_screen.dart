import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_manager.dart';
import '../services/encrypted_storage.dart';
import '../services/network_service.dart';
import '../models/network_model.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'package:hd_wallet/hd_wallet.dart';

/// Settings screen - app configuration and password management
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletManager = context.watch<WalletManager>();
    final networkService = context.watch<NetworkService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAppInfo(context),
            const SizedBox(height: AppTheme.space24),
            _buildNetworkSection(context, networkService),
            const SizedBox(height: AppTheme.space24),
            _buildSecuritySection(context, walletManager),
            const SizedBox(height: AppTheme.space24),
            _buildDangerSection(context, walletManager),
            const SizedBox(height: AppTheme.space24),
            _buildLogoutSection(context, walletManager),
            const SizedBox(height: AppTheme.space32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return ModernCard(
      backgroundColor: AppTheme.primaryGoldSurface,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGoldGradient,
              borderRadius: BorderRadius.circular(AppTheme.radius16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'Bitcoin is Gold, Kaspa is Silver',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'BIP39 • BIP32 • BIP44 Standard',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSection(BuildContext context, NetworkService networkService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network Configuration',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Configure Bitcoin and Kaspa network connections',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        _buildNetworkCard(
          context,
          'Bitcoin Network',
          networkService.getSelectedNetwork(CoinType.bitcoin)?.displayName ?? 'Not configured',
          Icons.monetization_on_rounded,
          AppTheme.primaryGold,
          () => _showNetworkSelectionDialog(context, CoinType.bitcoin, networkService),
        ),
        const SizedBox(height: AppTheme.space12),
        _buildNetworkCard(
          context,
          'Kaspa Network',
          networkService.getSelectedNetwork(CoinType.kaspa)?.displayName ?? 'Not configured',
          Icons.account_balance_wallet_rounded,
          AppTheme.secondarySilver,
          () => _showNetworkSelectionDialog(context, CoinType.kaspa, networkService),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context, WalletManager walletManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Manage your wallet security settings',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        _buildActionCard(
          context,
          'Change Password',
          'Update your master password',
          Icons.lock_rounded,
          AppTheme.primaryGold,
          () => _showChangePasswordDialog(context, walletManager),
        ),
      ],
    );
  }

  Widget _buildDangerSection(BuildContext context, WalletManager walletManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.error,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Irreversible actions that will permanently delete data',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        _buildActionCard(
          context,
          'Delete All Data',
          'Permanently delete all wallets and password',
          Icons.delete_forever_rounded,
          AppTheme.error,
          () => _confirmDeleteAll(context, walletManager),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildLogoutSection(BuildContext context, WalletManager walletManager) {
    return _buildActionCard(
      context,
      'Logout',
      'Return to password screen',
      Icons.logout_rounded,
      AppTheme.warning,
      () => _confirmLogout(context, walletManager),
    );
  }

  Widget _buildNetworkCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ModernCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radius8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {bool isDestructive = false}) {
    return ModernCard(
      onTap: onTap,
      backgroundColor: isDestructive ? AppTheme.errorContainer : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDestructive ? AppTheme.error : color,
              borderRadius: BorderRadius.circular(AppTheme.radius8),
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.white : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppTheme.onErrorContainer : null,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDestructive ? AppTheme.onErrorContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDestructive ? AppTheme.onErrorContainer : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Network Configuration:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Bitcoin Network: Choose mainnet or testnet for Bitcoin'),
              Text('• Kaspa Network: Choose mainnet or testnet for Kaspa'),
              SizedBox(height: 16),
              Text(
                'Security:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Change Password: Update your master password'),
              SizedBox(height: 16),
              Text(
                'Danger Zone:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Delete All Data: Permanently removes all wallets'),
              Text('• This action cannot be undone!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WalletManager manager) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showOldPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: !showOldPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(showOldPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => showOldPassword = !showOldPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(showNewPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => showNewPassword = !showNewPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(error!, style: TextStyle(color: Colors.red[700])),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                oldPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => error = null);

                try {
                  final oldPassword = oldPasswordController.text;
                  final newPassword = newPasswordController.text;
                  final confirmPassword = confirmPasswordController.text;

                  if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                    throw Exception('All fields are required');
                  }

                  if (newPassword.length < 8) {
                    throw Exception('New password must be at least 8 characters');
                  }

                  if (newPassword != confirmPassword) {
                    throw Exception('New passwords do not match');
                  }

                  // Change password
                  await manager.changePassword(oldPassword, newPassword);

                  if (!dialogContext.mounted) return;
                  
                  oldPasswordController.dispose();
                  newPasswordController.dispose();
                  confirmPasswordController.dispose();
                  Navigator.pop(dialogContext);
                  
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  setState(() => error = e.toString().replaceAll('Exception: ', ''));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WalletManager manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will need to enter your password again to access your wallets.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              manager.lock();
              Navigator.pop(context);
              // Navigate to home screen
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }


  void _showNetworkSelectionDialog(BuildContext context, CoinType coinType, NetworkService networkService) {
    final availableNetworks = networkService.getAvailableNetworks(coinType);
    final currentSelection = networkService.getSelectedNetwork(coinType);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              coinType.value == 0 ? Icons.monetization_on : Icons.account_balance_wallet,
              color: coinType.value == 0 ? AppTheme.primaryGold : AppTheme.secondarySilver,
            ),
            const SizedBox(width: 8),
            Text('${coinType.name.toUpperCase()} Network'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableNetworks.map((network) {
              final isSelected = currentSelection?.id == network.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected ? Colors.blue[50] : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Colors.blue : Colors.grey,
                    child: Icon(
                      isSelected ? Icons.check : Icons.radio_button_unchecked,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    network.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RPC: ${network.rpcUrl}'),
                      if (network.explorerUrl != null)
                        Text('Explorer: ${network.explorerUrl}'),
                      Text(
                        network.isTestnet ? 'Test Network' : 'Main Network',
                        style: TextStyle(
                          color: network.isTestnet ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    networkService.setSelectedNetwork(coinType, network);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${coinType.name.toUpperCase()} network updated to ${network.displayName}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, WalletManager manager) {
    final passwordController = TextEditingController();
    bool showPassword = false;
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete All Data?'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ THIS ACTION CANNOT BE UNDONE!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This will permanently delete:\n'
                  '• All wallets and accounts\n'
                  '• Your master password\n'
                  '• All encrypted data\n\n'
                  'Make sure you have saved all recovery phrases!',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Enter your master password to confirm:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    hintText: 'Master Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => showPassword = !showPassword),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(error!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordController.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => error = null);
                
                final password = passwordController.text;
                if (password.isEmpty) {
                  setState(() => error = 'Please enter your password');
                  return;
                }
                
                try {
                  // Verify password
                  final storage = EncryptedStorage();
                  final isValid = await storage.verifyPassword(password);
                  
                  if (!isValid) {
                    setState(() => error = 'Incorrect password');
                    return;
                  }
                  
                  // Password is correct, delete all data
                  await manager.deleteAllData();
                  passwordController.dispose();
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  
                  // Navigate to home screen which will show password setup
                  Navigator.of(dialogContext).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                } catch (e) {
                  setState(() => error = 'Error: ${e.toString()}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All Data'),
            ),
          ],
        ),
      ),
    );
  }
}

