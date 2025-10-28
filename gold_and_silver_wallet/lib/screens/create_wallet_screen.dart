import 'package:flutter/material.dart';
import 'package:hd_wallet/hd_wallet.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'entropy_input_screen.dart';
import '../services/security_service.dart';

/// Modern create wallet screen with improved UX
class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen>
    with TickerProviderStateMixin {
  int _selectedWordCount = 24;
  EntropyStrategy _selectedStrategy = EntropyStrategy.systemRandom;
  final SecurityService _securityService = SecurityService();
  
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Column(
        children: [
          _securityService.buildSecurityBanner(context),
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.space24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: AppTheme.space32),
                          _buildEntropySection(),
                          const SizedBox(height: AppTheme.space24),
                          _buildWordCountSection(),
                          const SizedBox(height: AppTheme.space32),
                          _buildCreateButton(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGoldGradient,
            borderRadius: BorderRadius.circular(AppTheme.radius20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: const Icon(
            Icons.add_circle_outline_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        Text(
          'Create Your Wallet',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Choose your entropy source and mnemonic length to generate a secure wallet',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEntropySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Choose Entropy Source',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Select how you want to generate the random data for your wallet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        _buildStrategyCard(
          EntropyStrategy.systemRandom,
          'System Random',
          'Use cryptographically secure random number generator',
          Icons.shuffle_rounded,
          AppTheme.primaryGold,
          'Recommended',
          true,
        ),
        const SizedBox(height: AppTheme.space12),
        _buildStrategyCard(
          EntropyStrategy.hexInput,
          'Hex Input',
          'Provide your own hexadecimal entropy',
          Icons.edit_rounded,
          AppTheme.secondarySilver,
          'Advanced',
          false,
        ),
        const SizedBox(height: AppTheme.space12),
        _buildStrategyCard(
          EntropyStrategy.diceRolls,
          'Dice Rolls',
          'Generate entropy using physical dice (most secure)',
          Icons.casino_rounded,
          AppTheme.success,
          'Most Secure',
          false,
        ),
        const SizedBox(height: AppTheme.space12),
        _buildStrategyCard(
          EntropyStrategy.numbers,
          'Custom Numbers',
          'Use any source of random numbers',
          Icons.pin_rounded,
          AppTheme.warning,
          'Custom',
          false,
        ),
        const SizedBox(height: AppTheme.space12),
        _buildStrategyCard(
          EntropyStrategy.textInput,
          'Text Input',
          'Use passwords, phrases, or any text for entropy',
          Icons.text_fields_rounded,
          AppTheme.error,
          'Experimental',
          false,
        ),
      ],
    );
  }

  Widget _buildWordCountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Mnemonic Length',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Choose the number of words in your recovery phrase',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        _buildWordCountCard(12, '12 words', 'Less secure, easier to remember'),
        const SizedBox(height: AppTheme.space8),
        _buildWordCountCard(15, '15 words', 'Medium security'),
        const SizedBox(height: AppTheme.space8),
        _buildWordCountCard(18, '18 words', 'High security'),
        const SizedBox(height: AppTheme.space8),
        _buildWordCountCard(21, '21 words', 'Very high security'),
        const SizedBox(height: AppTheme.space8),
        _buildWordCountCard(24, '24 words', 'Maximum security (recommended)'),
      ],
    );
  }

  Widget _buildStrategyCard(
    EntropyStrategy strategy,
    String title,
    String description,
    IconData icon,
    Color color,
    String badge,
    bool isRecommended,
  ) {
    final isSelected = _selectedStrategy == strategy;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ModernCard(
      onTap: () {
        setState(() {
          _selectedStrategy = strategy;
        });
      },
      backgroundColor: isSelected 
          ? color.withOpacity(0.1) 
          : colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius16),
          border: isSelected 
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space8,
                              vertical: AppTheme.space4,
                            ),
                            decoration: BoxDecoration(
                              color: isRecommended 
                                  ? AppTheme.successContainer 
                                  : colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppTheme.radius8),
                            ),
                            child: Text(
                              badge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isRecommended 
                                    ? AppTheme.onSuccessContainer 
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordCountCard(int wordCount, String title, String description) {
    final isSelected = _selectedWordCount == wordCount;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ModernCard(
      onTap: () {
        setState(() {
          _selectedWordCount = wordCount;
        });
      },
      backgroundColor: isSelected 
          ? AppTheme.primaryGold.withOpacity(0.1) 
          : colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius16),
          border: isSelected 
              ? Border.all(color: AppTheme.primaryGold, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryGold : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: Center(
                  child: Text(
                    wordCount.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
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
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.primaryGold : null,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryGold,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return FilledButton.icon(
      onPressed: _createWallet,
      icon: const Icon(Icons.arrow_forward_rounded),
      label: const Text('Create Wallet'),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space32,
          vertical: AppTheme.space16,
        ),
      ),
    );
  }

  void _createWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntropyInputScreen(
          strategy: _selectedStrategy,
          wordCount: _selectedWordCount,
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wallet Creation Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Entropy Sources:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• System Random: Uses your device\'s secure random number generator'),
              Text('• Hex Input: You provide hexadecimal entropy'),
              Text('• Dice Rolls: Most secure - use physical dice'),
              Text('• Custom Numbers: Any random number source'),
              Text('• Text Input: Use passwords or phrases'),
              SizedBox(height: 16),
              Text(
                'Mnemonic Length:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• More words = more security but harder to remember'),
              Text('• 24 words is recommended for maximum security'),
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
}
