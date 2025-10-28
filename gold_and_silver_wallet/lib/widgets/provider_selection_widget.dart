import 'package:flutter/material.dart';
import '../models/account_model.dart';
import 'package:hd_wallet/hd_wallet.dart';

/// Widget for selecting signature type during account creation
class SignatureTypeSelectionWidget extends StatefulWidget {
  final CoinType coinType;
  final SignatureType? initialSignatureType;
  final Function(SignatureType) onSignatureTypeChanged;

  const SignatureTypeSelectionWidget({
    Key? key,
    required this.coinType,
    this.initialSignatureType,
    required this.onSignatureTypeChanged,
  }) : super(key: key);

  @override
  State<SignatureTypeSelectionWidget> createState() => _SignatureTypeSelectionWidgetState();
}

class _SignatureTypeSelectionWidgetState extends State<SignatureTypeSelectionWidget> {
  late SignatureType _selectedSignatureType;

  @override
  void initState() {
    super.initState();
    final availableSignatureTypes = AccountModel.getAvailableSignatureTypes(widget.coinType);
    _selectedSignatureType = widget.initialSignatureType ?? availableSignatureTypes.first;
    // Defer the callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSignatureTypeChanged(_selectedSignatureType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableSignatureTypes = AccountModel.getAvailableSignatureTypes(widget.coinType);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signature Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the signature type for compatibility with other wallets.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        ...availableSignatureTypes.map((signatureType) => _buildSignatureTypeOption(signatureType)),
      ],
    );
  }

  Widget _buildSignatureTypeOption(SignatureType signatureType) {
    final isSelected = _selectedSignatureType == signatureType;
    final account = AccountModel(
      id: '',
      walletId: '',
      name: '',
      coinType: widget.coinType,
      accountIndex: 0,
      derivationPath: '',
      signatureType: signatureType,
      address: '', // Placeholder for display
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSignatureType = signatureType;
          });
          // Use a microtask to defer the callback
          Future.microtask(() => widget.onSignatureTypeChanged(signatureType));
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.signatureTypeDisplayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.signatureTypeDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget to show signature type information in account details
class SignatureTypeInfoWidget extends StatelessWidget {
  final AccountModel account;

  const SignatureTypeInfoWidget({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.blue[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signature Type: ${account.signatureTypeDisplayName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontSize: 12,
                  ),
                ),
                Text(
                  account.signatureTypeDescription,
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
