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

/// Import wallet screen - import existing mnemonic
class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(text: 'Imported Wallet');
  final TextEditingController _passphraseController = TextEditingController();
  final SecurityService _securityService = SecurityService();
  String? _error;
  bool _isImporting = false;
  bool _usePassphrase = false;
  bool _showPassphrase = false;
  bool _showBip39Seed = false;
  bool _showBip32RootKey = false;

  @override
  void dispose() {
    _mnemonicController.dispose();
    _nameController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  String _getBip39Seed() {
    try {
      final mnemonic = _mnemonicController.text.trim().toLowerCase();
      if (mnemonic.isEmpty || !Mnemonic.validate(mnemonic)) {
        return 'Enter a valid mnemonic to see the seed';
      }
      final passphrase = _usePassphrase ? _passphraseController.text : '';
      final seed = Mnemonic.toSeed(mnemonic, passphrase: passphrase);
      return hex.encode(seed);
    } catch (e) {
      return 'Error generating seed: $e';
    }
  }

  String _getBip32RootKey() {
    try {
      final mnemonic = _mnemonicController.text.trim().toLowerCase();
      if (mnemonic.isEmpty || !Mnemonic.validate(mnemonic)) {
        return 'Enter a valid mnemonic to see the root key';
      }
      final passphrase = _usePassphrase ? _passphraseController.text : '';
      final hdWallet = HDWallet.fromMnemonic(mnemonic, passphrase: passphrase);
      return hdWallet.masterExtendedKey;
    } catch (e) {
      return 'Error generating BIP32 root key: $e';
    }
  }

  bool _isMnemonicValid() {
    final mnemonic = _mnemonicController.text.trim().toLowerCase();
    return mnemonic.isNotEmpty && Mnemonic.validate(mnemonic);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                gradient: AppTheme.secondarySilverGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            const Text('Import Wallet'),
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
                  // Header
                  ModernCard(
                    backgroundColor: AppTheme.secondarySilverSurface,
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppTheme.secondarySilverGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radius20),
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          'Import Existing Wallet',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondarySilver,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'Enter your recovery phrase to restore your wallet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.secondarySilver,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Wallet name
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
                  const SizedBox(height: AppTheme.space16),

                  // Mnemonic input
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recovery Phrase',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'Enter 12, 15, 18, 21, or 24 words separated by spaces',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space12),
                        TextField(
                          controller: _mnemonicController,
                          decoration: const InputDecoration(
                            labelText: 'word1 word2 word3...',
                            prefixIcon: Icon(Icons.key_rounded),
                          ),
                          maxLines: 6,
                          textCapitalization: TextCapitalization.none,
                          onChanged: (_) {
                            setState(() {}); // Update BIP39 seed and BIP32 root key when mnemonic changes
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Optional passphrase
                  ModernCard(
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
                                'Optional Passphrase',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
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
                          'Add an extra word for additional security. Warning: You must remember this passphrase!',
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
                              hintText: 'Enter passphrase if wallet was created with one',
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
                        ],
                      ],
                    ),
                  ),
                  
                  // BIP39 Seed display (only show if mnemonic is valid)
                  if (_isMnemonicValid()) ...[
                    const SizedBox(height: AppTheme.space24),
                    _buildBip39SeedSection(context),
                    const SizedBox(height: AppTheme.space16),
                    
                    // BIP32 Root Key display
                    _buildBip32RootKeySection(context),
                  ],
                  
                  if (_error != null) ...[
                    const SizedBox(height: AppTheme.space16),
                    _buildError(context),
                  ],
                  const SizedBox(height: AppTheme.space24),

                  // Import button
                  FilledButton.icon(
                    onPressed: _isImporting ? null : _importWallet,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(_isImporting ? 'Importing...' : 'Import Wallet'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondarySilver,
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Wallet Help'),
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
              Text('• Enter your 12, 15, 18, 21, or 24 word recovery phrase'),
              Text('• Words should be separated by spaces'),
              Text('• Make sure all words are spelled correctly'),
              SizedBox(height: 16),
              Text(
                'Passphrase:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Only needed if your wallet was created with a passphrase'),
              Text('• This is an additional security layer'),
              Text('• If you forget it, you cannot access your funds'),
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

  Future<void> _importWallet() async {
    setState(() {
      _isImporting = true;
      _error = null;
    });

    try {
      final mnemonic = _mnemonicController.text.trim().toLowerCase();
      
      if (mnemonic.isEmpty) {
        throw ArgumentError('Please enter a recovery phrase');
      }

      // Validate mnemonic
      if (!Mnemonic.validate(mnemonic)) {
        throw ArgumentError('Invalid recovery phrase. Please check your words and try again.');
      }

      final words = mnemonic.split(RegExp(r'\s+'));
      final wordCount = words.length;
      final passphrase = _usePassphrase ? _passphraseController.text : '';

      // Create wallet
      final wallet = WalletModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim().isEmpty ? 'Imported Wallet' : _nameController.text.trim(),
        mnemonic: mnemonic,
        passphrase: passphrase,
        createdAt: DateTime.now(),
        wordCount: wordCount,
      );

      if (!mounted) return;

      final walletManager = context.read<WalletManager>();
      walletManager.importWallet(wallet);

      // Navigate to wallet detail screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WalletDetailScreen(wallet: wallet),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '').replaceAll('ArgumentError: ', '');
        _isImporting = false;
      });
    }
  }
}

