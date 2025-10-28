import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hd_wallet/hd_wallet.dart';
import 'package:convert/convert.dart';
import '../services/wallet_manager.dart';
import '../services/security_service.dart';
import '../models/wallet_model.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'wallet_detail_screen.dart';

/// Mnemonic display screen - show generated mnemonic and save wallet
class MnemonicDisplayScreen extends StatefulWidget {
  final String mnemonic;
  final int wordCount;
  final EntropyStrategy strategy;

  const MnemonicDisplayScreen({
    super.key,
    required this.mnemonic,
    required this.wordCount,
    required this.strategy,
  });

  @override
  State<MnemonicDisplayScreen> createState() => _MnemonicDisplayScreenState();
}

class _MnemonicDisplayScreenState extends State<MnemonicDisplayScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'My Wallet');
  final TextEditingController _passphraseController = TextEditingController();
  final SecurityService _securityService = SecurityService();
  bool _confirmed = false;
  bool _obscured = true;
  bool _usePassphrase = false;
  bool _showPassphrase = false;
  bool _showBip39Seed = false;
  bool _showBip32RootKey = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  String _getBip39Seed() {
    try {
      final passphrase = _usePassphrase ? _passphraseController.text : '';
      final seed = Mnemonic.toSeed(widget.mnemonic, passphrase: passphrase);
      return hex.encode(seed);
    } catch (e) {
      return 'Error generating seed: $e';
    }
  }

  String _getBip32RootKey() {
    try {
      final passphrase = _usePassphrase ? _passphraseController.text : '';
      final hdWallet = HDWallet.fromMnemonic(widget.mnemonic, passphrase: passphrase);
      return hdWallet.masterExtendedKey;
    } catch (e) {
      return 'Error generating BIP32 root key: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.split(' ');
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
                Icons.key_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            const Text('Your Recovery Phrase'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Help',
          ),
        ],
      ),
      body: Column(
        children: [
          _securityService.buildSecurityBanner(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning
                  _buildWarning(context),
                  const SizedBox(height: AppTheme.space24),

                  // Wallet name input
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Name',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space12),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Enter a name for your wallet',
                            prefixIcon: Icon(Icons.label_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Mnemonic display
                  _buildMnemonicCard(context, words),
                  const SizedBox(height: AppTheme.space16),

                  // Toggle visibility and copy buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _obscured = !_obscured;
                            });
                          },
                          icon: Icon(_obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                          label: Text(_obscured ? 'Show Phrase' : 'Hide Phrase'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.mnemonic));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mnemonic copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy Phrase'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Optional passphrase section
                  _buildPassphraseSection(context),
                  const SizedBox(height: AppTheme.space24),

                  // BIP39 Seed display
                  _buildBip39SeedSection(context),
                  const SizedBox(height: AppTheme.space16),
                  
                  // BIP32 Root Key display
                  _buildBip32RootKeySection(context),
                  const SizedBox(height: AppTheme.space24),

                  // Confirmation checkbox
                  _buildConfirmationCheckbox(context),
                  const SizedBox(height: AppTheme.space24),

                  // Save button
                  FilledButton.icon(
                    onPressed: _confirmed ? _saveWallet : null,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save Wallet'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning(BuildContext context) {
    final theme = Theme.of(context);
    return ModernCard(
      backgroundColor: AppTheme.errorContainer,
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.onErrorContainer),
          const SizedBox(height: AppTheme.space12),
          Text(
            'IMPORTANT: Write this down!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'This is your recovery phrase. Write it down on paper and store it in a safe place. '
            'Anyone with this phrase can access your funds. '
            'If you lose it, your funds are GONE FOREVER.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicCard(BuildContext context, List<String> words) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recovery Phrase',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: Text(
                  '${widget.wordCount} words',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          _obscured
              ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_off_rounded, size: 48, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        'Recovery phrase hidden',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Determine number of columns based on screen width
                    final isDesktop = constraints.maxWidth > 800;
                    final columns = isDesktop ? 3 : 2;
                    final spacing = AppTheme.space8;
                    final totalSpacing = spacing * (columns - 1);
                    final itemWidth = (constraints.maxWidth - totalSpacing) / columns;
                    
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: words.asMap().entries.map((entry) {
                        return Container(
                          width: itemWidth,
                          padding: const EdgeInsets.all(AppTheme.space12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppTheme.radius8),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key + 1}.',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                entry.value,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildPassphraseSection(BuildContext context) {
    final theme = Theme.of(context);
    return ModernCard(
      backgroundColor: AppTheme.warningContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppTheme.onWarningContainer),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  'Optional Passphrase (BIP39)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onWarningContainer,
                  ),
                ),
              ),
              Switch(
                value: _usePassphrase,
                onChanged: (value) {
                  setState(() {
                    _usePassphrase = value;
                  });
                },
                activeColor: AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Add an extra word for additional security. '
            'Warning: You must remember this passphrase!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onWarningContainer,
            ),
          ),
          if (_usePassphrase) ...[
            const SizedBox(height: AppTheme.space16),
            TextField(
              controller: _passphraseController,
              obscureText: !_showPassphrase,
              decoration: InputDecoration(
                labelText: 'Passphrase',
                hintText: 'Enter additional passphrase',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_showPassphrase ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () {
                    setState(() {
                      _showPassphrase = !_showPassphrase;
                    });
                  },
                ),
              ),
              onChanged: (_) {
                setState(() {}); // Update BIP39 seed and BIP32 root key when passphrase changes
              },
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              '⚠️ Losing this passphrase means losing access to your funds!',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBip39SeedSection(BuildContext context) {
    final seed = _getBip39Seed();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ModernCard(
      backgroundColor: AppTheme.successContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_rounded, color: AppTheme.onSuccessContainer),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  'BIP39 Seed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSuccessContainer,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_showBip39Seed ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                onPressed: () {
                  setState(() {
                    _showBip39Seed = !_showBip39Seed;
                  });
                },
                tooltip: _showBip39Seed ? 'Hide seed' : 'Show seed',
              ),
              if (_showBip39Seed)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: seed));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('BIP39 seed copied to clipboard')),
                    );
                  },
                  tooltip: 'Copy seed',
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'This is the 512-bit seed derived from your mnemonic${_usePassphrase ? " and passphrase" : ""}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onSuccessContainer,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: _showBip39Seed ? colorScheme.surface : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppTheme.radius8),
              border: Border.all(
                color: _showBip39Seed ? colorScheme.outline : colorScheme.outlineVariant,
              ),
            ),
            child: _showBip39Seed
                ? SelectableText(
                    seed,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_off_rounded, size: 32, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'BIP39 seed hidden',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBip32RootKeySection(BuildContext context) {
    final rootKey = _getBip32RootKey();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ModernCard(
      backgroundColor: AppTheme.primaryGoldSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: AppTheme.primaryGold),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  'BIP32 Root Key',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_showBip32RootKey ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                onPressed: () {
                  setState(() {
                    _showBip32RootKey = !_showBip32RootKey;
                  });
                },
                tooltip: _showBip32RootKey ? 'Hide root key' : 'Show root key',
              ),
              if (_showBip32RootKey)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: rootKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('BIP32 root key copied to clipboard')),
                    );
                  },
                  tooltip: 'Copy root key',
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'This is the master private key derived from your mnemonic${_usePassphrase ? " and passphrase" : ""}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryGold,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: _showBip32RootKey ? colorScheme.surface : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppTheme.radius8),
              border: Border.all(
                color: _showBip32RootKey ? colorScheme.outline : colorScheme.outlineVariant,
              ),
            ),
            child: _showBip32RootKey
                ? SelectableText(
                    rootKey,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_off_rounded, size: 32, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'BIP32 root key hidden',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCheckbox(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ModernCard(
      child: CheckboxListTile(
        value: _confirmed,
        onChanged: (value) {
          setState(() {
            _confirmed = value ?? false;
          });
        },
        title: Text(
          'I have written down my recovery phrase',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _usePassphrase 
              ? 'I understand I need both the phrase AND passphrase to recover'
              : 'I understand that I am responsible for keeping it safe',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: colorScheme.primary,
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recovery Phrase Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recovery Phrase:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Write down your recovery phrase on paper'),
              Text('• Store it in a safe, secure location'),
              Text('• Never share it with anyone'),
              Text('• Anyone with this phrase can access your funds'),
              SizedBox(height: 16),
              Text(
                'Passphrase:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Optional additional security layer'),
              Text('• Must be remembered along with the phrase'),
              Text('• If forgotten, funds cannot be recovered'),
              SizedBox(height: 16),
              Text(
                'BIP39 Seed:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Technical representation of your phrase'),
              Text('• Used internally by the wallet'),
              Text('• Can be copied for advanced users'),
              SizedBox(height: 16),
              Text(
                'BIP32 Root Key:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Master private key derived from your phrase'),
              Text('• Used to generate all wallet addresses'),
              Text('• Most sensitive key - keep extremely secure'),
              Text('• Required for advanced wallet recovery'),
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

  void _saveWallet() {
    final passphrase = _usePassphrase ? _passphraseController.text : '';
    
    final wallet = WalletModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isEmpty ? 'My Wallet' : _nameController.text.trim(),
      mnemonic: widget.mnemonic,
      passphrase: passphrase,
      createdAt: DateTime.now(),
      wordCount: widget.wordCount,
    );

    final walletManager = context.read<WalletManager>();
    walletManager.addWallet(wallet);

    // Navigate to wallet detail screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => WalletDetailScreen(wallet: wallet),
      ),
      (route) => route.isFirst, // Keep only the home screen in the stack
    );
  }
}

