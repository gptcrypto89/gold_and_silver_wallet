import 'package:flutter/material.dart';
import 'package:hd_wallet/hd_wallet.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'mnemonic_display_screen.dart';

/// Entropy input screen - generate or input entropy based on selected strategy
class EntropyInputScreen extends StatefulWidget {
  final EntropyStrategy strategy;
  final int wordCount;

  const EntropyInputScreen({
    super.key,
    required this.strategy,
    required this.wordCount,
  });

  @override
  State<EntropyInputScreen> createState() => _EntropyInputScreenState();
}

class _EntropyInputScreenState extends State<EntropyInputScreen> {
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _diceController = TextEditingController();
  final TextEditingController _numbersController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  
  String? _error;
  bool _isGenerating = false;

  @override
  void dispose() {
    _hexController.dispose();
    _diceController.dispose();
    _numbersController.dispose();
    _textController.dispose();
    super.dispose();
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
                gradient: AppTheme.primaryGoldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Text(_getTitle()),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructions(context),
            const SizedBox(height: AppTheme.space24),
            _buildInputWidget(context),
            if (_error != null) ...[
              const SizedBox(height: AppTheme.space16),
              _buildError(context),
            ],
            const SizedBox(height: AppTheme.space24),
            _buildGenerateButton(context),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.strategy) {
      case EntropyStrategy.systemRandom:
        return 'System Random';
      case EntropyStrategy.hexInput:
        return 'Hex Input';
      case EntropyStrategy.diceRolls:
        return 'Dice Rolls';
      case EntropyStrategy.numbers:
        return 'Custom Numbers';
      case EntropyStrategy.textInput:
        return 'Text Input';
    }
  }

  Widget _buildInstructions(BuildContext context) {
    String instructions;
    IconData icon;
    Color color;

    switch (widget.strategy) {
      case EntropyStrategy.systemRandom:
        instructions = 'Click the button below to generate a secure random mnemonic using your system\'s cryptographic random number generator.';
        icon = Icons.shuffle_rounded;
        color = AppTheme.primaryGold;
        break;
      case EntropyStrategy.hexInput:
        final bytes = EntropySource.bitsFromWordCount(widget.wordCount) ~/ 8;
        instructions = 'Enter exactly $bytes bytes (${ bytes * 2} hex characters) of entropy.\n\nExample: a1b2c3d4e5f6...';
        icon = Icons.edit_rounded;
        color = AppTheme.secondarySilver;
        break;
      case EntropyStrategy.diceRolls:
        final minRolls = EntropySource.minDiceRolls(EntropySource.bitsFromWordCount(widget.wordCount));
        instructions = 'Roll a 6-sided dice at least $minRolls times and enter the results (1-6).\n\nExample: 1 4 2 6 3 5 1 2...';
        icon = Icons.casino_rounded;
        color = AppTheme.success;
        break;
      case EntropyStrategy.numbers:
        final minNumbers = EntropySource.minNumbers(EntropySource.bitsFromWordCount(widget.wordCount));
        instructions = 'Enter at least $minNumbers numbers (0-255), separated by spaces or commas.\n\nExample: 42 156 78 201...';
        icon = Icons.pin_rounded;
        color = AppTheme.warning;
        break;
      case EntropyStrategy.textInput:
        final minLength = EntropySource.minTextLength(EntropySource.bitsFromWordCount(widget.wordCount));
        instructions = 'Enter at least $minLength characters of text (passwords, phrases, etc.).\n\nUse mixed case, numbers, and symbols for better entropy.\n\nExample: MySecurePass123! or "The quick brown fox jumps over the lazy dog"';
        icon = Icons.text_fields_rounded;
        color = AppTheme.error;
        break;
    }

    return ModernCard(
      backgroundColor: color.withOpacity(0.1),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: AppTheme.space12),
          Text(
            instructions,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Target: ${widget.wordCount} words (${EntropySource.bitsFromWordCount(widget.wordCount)} bits)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputWidget(BuildContext context) {
    switch (widget.strategy) {
      case EntropyStrategy.systemRandom:
        return const SizedBox.shrink();
      
      case EntropyStrategy.hexInput:
        return ModernCard(
          child: TextField(
            controller: _hexController,
            decoration: const InputDecoration(
              labelText: 'Hex Entropy',
              hintText: 'a1b2c3d4e5f6...',
              prefixIcon: Icon(Icons.edit_rounded),
              helperText: 'Enter hex characters (0-9, a-f)',
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.none,
          ),
        );
      
      case EntropyStrategy.diceRolls:
        return ModernCard(
          child: TextField(
            controller: _diceController,
            decoration: const InputDecoration(
              labelText: 'Dice Rolls',
              hintText: '1 4 2 6 3 5 1 2 4 6...',
              prefixIcon: Icon(Icons.casino_rounded),
              helperText: 'Enter dice values (1-6), space-separated',
            ),
            keyboardType: TextInputType.number,
            maxLines: 5,
          ),
        );
      
      case EntropyStrategy.numbers:
        return ModernCard(
          child: TextField(
            controller: _numbersController,
            decoration: const InputDecoration(
              labelText: 'Custom Numbers',
              hintText: '42, 156, 78, 201, 133...',
              prefixIcon: Icon(Icons.pin_rounded),
              helperText: 'Enter numbers (0-255), space or comma-separated',
            ),
            keyboardType: TextInputType.number,
            maxLines: 5,
          ),
        );
      
      case EntropyStrategy.textInput:
        return ModernCard(
          child: TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Text Input',
              hintText: 'MySecurePass123! or "The quick brown fox..."',
              prefixIcon: Icon(Icons.text_fields_rounded),
              helperText: 'Enter text with mixed case, numbers, and symbols',
            ),
            maxLines: 5,
            textCapitalization: TextCapitalization.none,
          ),
        );
    }
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

  Widget _buildGenerateButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isGenerating ? null : _generateMnemonic,
      icon: _isGenerating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.arrow_forward_rounded),
      label: Text(_isGenerating ? 'Generating...' : 'Generate Mnemonic'),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    String helpText;
    switch (widget.strategy) {
      case EntropyStrategy.systemRandom:
        helpText = 'Uses your device\'s secure random number generator to create cryptographically secure entropy.';
        break;
      case EntropyStrategy.hexInput:
        helpText = 'Enter hexadecimal characters (0-9, a-f) to provide your own entropy source.';
        break;
      case EntropyStrategy.diceRolls:
        helpText = 'Roll a physical 6-sided dice and enter the results. This provides true randomness.';
        break;
      case EntropyStrategy.numbers:
        helpText = 'Enter random numbers (0-255) from any source to create entropy.';
        break;
      case EntropyStrategy.textInput:
        helpText = 'Enter any text (passwords, phrases, etc.) to generate entropy from text content.';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getTitle()} Help'),
        content: Text(helpText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateMnemonic() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      String mnemonic;

      switch (widget.strategy) {
        case EntropyStrategy.systemRandom:
          mnemonic = Mnemonic.generate(wordCount: widget.wordCount);
          break;

        case EntropyStrategy.hexInput:
          final hex = _hexController.text.trim();
          if (hex.isEmpty) {
            throw ArgumentError('Please enter hex entropy');
          }
          mnemonic = Mnemonic.fromHex(hex, wordCount: widget.wordCount);
          break;

        case EntropyStrategy.diceRolls:
          final diceText = _diceController.text.trim();
          if (diceText.isEmpty) {
            throw ArgumentError('Please enter dice rolls');
          }
          final rolls = diceText
              .split(RegExp(r'[\s,]+'))
              .where((s) => s.isNotEmpty)
              .map((s) => int.parse(s))
              .toList();
          mnemonic = Mnemonic.fromDiceRolls(rolls, wordCount: widget.wordCount);
          break;

        case EntropyStrategy.numbers:
          final numbersText = _numbersController.text.trim();
          if (numbersText.isEmpty) {
            throw ArgumentError('Please enter numbers');
          }
          final numbers = numbersText
              .split(RegExp(r'[\s,]+'))
              .where((s) => s.isNotEmpty)
              .map((s) => int.parse(s))
              .toList();
          mnemonic = Mnemonic.fromNumbers(numbers, wordCount: widget.wordCount);
          break;

        case EntropyStrategy.textInput:
          final text = _textController.text.trim();
          if (text.isEmpty) {
            throw ArgumentError('Please enter text');
          }
          mnemonic = Mnemonic.fromText(text, wordCount: widget.wordCount);
          break;
      }

      if (!mounted) return;

      // Navigate to mnemonic display screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MnemonicDisplayScreen(
            mnemonic: mnemonic,
            wordCount: widget.wordCount,
            strategy: widget.strategy,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '').replaceAll('ArgumentError: ', '');
        _isGenerating = false;
      });
    }
  }
}

