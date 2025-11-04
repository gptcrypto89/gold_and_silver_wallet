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
  final TextEditingController _diceController = TextEditingController();
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _diceAndCardController = TextEditingController();
  
  String? _error;
  bool _isGenerating = false;

  @override
  void dispose() {
    _diceController.dispose();
    _cardController.dispose();
    _diceAndCardController.dispose();
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
      case EntropyStrategy.diceRolls:
        return 'Dice Rolls';
      case EntropyStrategy.cardShuffle:
        return 'Card Shuffle';
      case EntropyStrategy.diceAndCard:
        return 'Dice & Card Hybrid';
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
      case EntropyStrategy.diceRolls:
        final minRolls = EntropySource.minDiceRolls(EntropySource.bitsFromWordCount(widget.wordCount));
        instructions = 'Roll a 6-sided dice at least $minRolls times and enter the results (1-6).\n\nExample: 1 4 2 6 3 5 1 2...';
        icon = Icons.casino_rounded;
        color = AppTheme.success;
        break;
      case EntropyStrategy.cardShuffle:
        instructions = 'Shuffle a standard 52-card deck thoroughly (7+ riffle shuffles recommended).\n\nRecord the final order as two-letter codes: [Rank][Suit].\n\nRanks: A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K\nSuits: S (Spades), D (Diamonds), C (Clubs), H (Hearts)\n\nExample: AS,7D,KC,2H,QH,9C,JD,...\n\nEnter all 52 cards in order, comma-separated.';
        icon = Icons.style_rounded;
        color = AppTheme.secondarySilver;
        break;
      case EntropyStrategy.diceAndCard:
        instructions = 'Combine card shuffle and dice rolls for maximum security.\n\nStep 1: Shuffle a 52-card deck and record the order (e.g., AS,7D,KC,2H,...)\nStep 2: Roll a 6-sided die 20-50 times and record the sequence (e.g., 3,6,2,1,4,5,...)\n\nEnter in format: cards|dice\n\nExample: AS,7D,KC,2H,QH,9C,JD,...|3,6,2,1,4,5,2,6,3,1,...';
        icon = Icons.auto_awesome_rounded;
        color = AppTheme.primaryGold;
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
      
      case EntropyStrategy.diceRolls:
        return ModernCard(
          child: TextField(
            controller: _diceController,
            decoration: const InputDecoration(
              labelText: 'Dice Rolls',
              hintText: '1 4 2 6 3 5 1 2 4 6...',
              prefixIcon: Icon(Icons.casino_rounded),
              helperText: 'Enter dice values (1-6), space or comma-separated',
            ),
            keyboardType: TextInputType.number,
            maxLines: 5,
          ),
        );
      
      case EntropyStrategy.cardShuffle:
        return ModernCard(
          child: TextField(
            controller: _cardController,
            decoration: const InputDecoration(
              labelText: 'Card Sequence',
              hintText: 'AS,7D,KC,2H,QH,9C,JD,AH,3S,5D,...',
              prefixIcon: Icon(Icons.style_rounded),
              helperText: 'Enter all 52 cards in format [Rank][Suit], comma-separated',
            ),
            maxLines: 8,
            textCapitalization: TextCapitalization.characters,
          ),
        );
      
      case EntropyStrategy.diceAndCard:
        return ModernCard(
          child: TextField(
            controller: _diceAndCardController,
            decoration: const InputDecoration(
              labelText: 'Cards and Dice',
              hintText: 'AS,7D,KC,2H,QH,9C,JD,...|3,6,2,1,4,5,2,6,3,1,...',
              prefixIcon: Icon(Icons.auto_awesome_rounded),
              helperText: 'Format: cards|dice (52 cards separated by |, then dice rolls)',
            ),
            maxLines: 10,
            textCapitalization: TextCapitalization.characters,
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
      case EntropyStrategy.diceRolls:
        helpText = 'Roll a physical 6-sided dice and enter the results. This provides true randomness. Each roll gives approximately 2.585 bits of entropy.';
        break;
      case EntropyStrategy.cardShuffle:
        helpText = 'Shuffle a standard 52-card deck thoroughly (7+ riffle shuffles recommended) and record the final order. Each card provides approximately 5.7 bits of entropy. The full deck provides ~225 bits, which is more than enough for any mnemonic length.';
        break;
      case EntropyStrategy.diceAndCard:
        helpText = 'Combines card shuffling and dice rolling for maximum security. First, shuffle a 52-card deck and record the order. Then, roll a 6-sided die 20-50 times and record those results. Enter both in the format: "cards|dice". This hybrid approach provides excellent entropy from independent physical sources.';
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

        case EntropyStrategy.cardShuffle:
          final cardText = _cardController.text.trim();
          if (cardText.isEmpty) {
            throw ArgumentError('Please enter card sequence');
          }
          mnemonic = Mnemonic.fromCardShuffle(cardText, wordCount: widget.wordCount);
          break;

        case EntropyStrategy.diceAndCard:
          final combinedText = _diceAndCardController.text.trim();
          if (combinedText.isEmpty) {
            throw ArgumentError('Please enter cards and dice in format: cards|dice');
          }
          mnemonic = Mnemonic.fromDiceAndCard(combinedText, wordCount: widget.wordCount);
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

