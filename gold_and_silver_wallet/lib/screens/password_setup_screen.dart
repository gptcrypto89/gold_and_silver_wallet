import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'home_screen.dart';

/// Initial password setup screen
class PasswordSetupScreen extends StatefulWidget {
  const PasswordSetupScreen({super.key});

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isCreating = false;
  String? _error;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.longDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.space32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAppInfo(),
                      const SizedBox(height: AppTheme.space32),
                      _buildPasswordForm(),
                      const SizedBox(height: AppTheme.space24),
                      _buildSecurityNotes(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return ModernCard(
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Standard BIP39 • BIP32 • BIP44',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Master Password',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'This password will encrypt all your wallets and sensitive data',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space32),
          
          // Password field
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Master Password',
              hintText: 'Enter a strong password',
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
          const SizedBox(height: AppTheme.space16),

          // Confirm password field
          TextField(
            controller: _confirmController,
            obscureText: !_showConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () {
                  setState(() {
                    _showConfirm = !_showConfirm;
                  });
                },
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                border: Border.all(color: AppTheme.error),
                borderRadius: BorderRadius.circular(AppTheme.radius8),
              ),
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
            ),
          ],

          const SizedBox(height: AppTheme.space24),

          // Create button
          FilledButton.icon(
            onPressed: _isCreating ? null : _createPassword,
            icon: _isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(_isCreating ? 'Creating...' : 'Create Password'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotes() {
    return ModernCard(
      backgroundColor: AppTheme.warningContainer,
      child: Column(
        children: [
          Icon(Icons.security_rounded, color: AppTheme.onWarningContainer, size: 32),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Important Security Notes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.onWarningContainer,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSecurityNote('This password encrypts all your wallets'),
              _buildSecurityNote('Choose a strong, unique password'),
              _buildSecurityNote('Store it securely - there is NO recovery!'),
              _buildSecurityNote('Never share it with anyone'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: AppTheme.onWarningContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.onWarningContainer,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPassword() async {
    setState(() {
      _error = null;
      _isCreating = true;
    });

    try {
      final password = _passwordController.text;
      final confirm = _confirmController.text;

      // Validation
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }

      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }

      if (password != confirm) {
        throw Exception('Passwords do not match');
      }

      // Set password
      final walletManager = context.read<WalletManager>();
      await walletManager.setInitialPassword(password);

      if (!mounted) return;

      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isCreating = false;
      });
    }
  }
}

