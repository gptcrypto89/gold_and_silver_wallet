import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'home_screen.dart';

/// Password unlock screen - shown when app starts with existing password
class PasswordUnlockScreen extends StatefulWidget {
  const PasswordUnlockScreen({super.key});

  @override
  State<PasswordUnlockScreen> createState() => _PasswordUnlockScreenState();
}

class _PasswordUnlockScreenState extends State<PasswordUnlockScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isUnlocking = false;
  String? _error;
  int _attemptCount = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Info
              ModernCard(
                backgroundColor: AppTheme.primaryGoldSurface,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGoldGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radius20),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      'Bitcoin is Gold, Kaspa is Silver',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Version 1.0.0',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Standard BIP39 • BIP32 • BIP44',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Subtitle
              Text(
                'Enter your master password to unlock your wallets',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space48),

              // Password field
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  autofocus: true,
                  onSubmitted: (_) => _unlock(),
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: AppTheme.space16),
                SizedBox(
                  width: 400,
                  child: _buildError(context),
                ),
              ],

              const SizedBox(height: AppTheme.space32),

              // Unlock button
              SizedBox(
                width: 400,
                child: FilledButton(
                  onPressed: _isUnlocking ? null : _unlock,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
                  ),
                  child: _isUnlocking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Unlock',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: AppTheme.space24),

              // Security note
              SizedBox(
                width: 400,
                child: ModernCard(
                  backgroundColor: AppTheme.secondarySilverSurface,
                  child: Column(
                    children: [
                      Icon(Icons.security_rounded, color: AppTheme.secondarySilver, size: 32),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        '🔒 Your Wallets Are Encrypted',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondarySilver,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        'All wallet data is encrypted with AES-256.\n'
                        'Your master password is never stored - only used to derive encryption keys.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondarySilver,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              if (_attemptCount > 2) ...[
                const SizedBox(height: AppTheme.space16),
                SizedBox(
                  width: 400,
                  child: ModernCard(
                    backgroundColor: AppTheme.warningContainer,
                    child: Column(
                      children: [
                        Icon(Icons.help_outline_rounded, color: AppTheme.onWarningContainer),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'Forgot Your Password?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onWarningContainer,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'Without the password, you cannot access your wallets.\n'
                          'Make sure you have your recovery phrases saved!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.onWarningContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return ModernCard(
      backgroundColor: AppTheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.onErrorContainer),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppTheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unlock() async {
    setState(() {
      _error = null;
      _isUnlocking = true;
    });

    try {
      final password = _passwordController.text;

      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }

      // Attempt to unlock
      final walletManager = context.read<WalletManager>();
      final success = await walletManager.unlockWithPassword(password);

      if (!success) {
        _attemptCount++;
        throw Exception('Incorrect password');
      }

      if (!mounted) return;

      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isUnlocking = false;
      });
    }
  }
}

