import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hd_wallet/hd_wallet.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wallet_model.dart';
import '../models/account_model.dart';
import '../models/balance_model.dart';
import '../models/transaction_model.dart';
import '../services/network_service.dart';
import '../services/transaction_service.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

/// Address view screen - view addresses and QR codes for an account
class AddressViewScreen extends StatefulWidget {
  final WalletModel wallet;
  final AccountModel account;

  const AddressViewScreen({
    super.key,
    required this.wallet,
    required this.account,
  });

  @override
  State<AddressViewScreen> createState() => _AddressViewScreenState();
}

class _AddressViewScreenState extends State<AddressViewScreen> {
  late HDWallet _hdWallet;
  final SecurityService _securityService = SecurityService();
  int _addressIndex = 0;
  String? _currentAddress;
  String? _currentPublicKey;
  bool _isLoading = true;
  
  // Transaction pagination
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _isLoadingTransactions = false;
  TransactionHistory? _transactionHistory;
  
  // Auto-refresh timers
  Timer? _balanceRefreshTimer;
  Timer? _transactionRefreshTimer;

  @override
  void initState() {
    super.initState();
    _hdWallet = HDWallet.fromMnemonic(
      widget.wallet.mnemonic,
      passphrase: widget.wallet.passphrase,
    );
    _deriveAddress();
    _loadTransactions();
    _fetchBalanceOnOpen();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _balanceRefreshTimer?.cancel();
    _transactionRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh balance every 30 seconds
    _balanceRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _autoRefreshBalance();
      }
    });
    
    // Auto-refresh transactions every 60 seconds
    _transactionRefreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _autoRefreshTransactions();
      }
    });
  }

  void _autoRefreshBalance() async {
    try {
      // Create a temporary account model for the current address
      final tempAccount = AccountModel(
        id: '${widget.account.id}_$_addressIndex',
        walletId: widget.account.walletId,
        name: '${widget.account.name} (Index $_addressIndex)',
        coinType: widget.account.coinType,
        accountIndex: widget.account.accountIndex,
        derivationPath: "m/44'/${widget.account.coinType.value}'/${widget.account.accountIndex}'/0/$_addressIndex",
        signatureType: widget.account.signatureType,
        address: _currentAddress ?? '',
      );
      
      final networkService = context.read<NetworkService>();
      await networkService.fetchBalance(tempAccount);
    } catch (e) {
      // Silent error handling
    }
  }

  void _autoRefreshTransactions() async {
    try {
      // Create a temporary account model for the current address
      final tempAccount = AccountModel(
        id: '${widget.account.id}_$_addressIndex',
        walletId: widget.account.walletId,
        name: '${widget.account.name} (Index $_addressIndex)',
        coinType: widget.account.coinType,
        accountIndex: widget.account.accountIndex,
        derivationPath: "m/44'/${widget.account.coinType.value}'/${widget.account.accountIndex}'/0/$_addressIndex",
        signatureType: widget.account.signatureType,
        address: _currentAddress ?? '',
      );
      
      final transactionService = context.read<TransactionService>();
      final history = await transactionService.fetchTransactions(
        tempAccount,
        page: _currentPage,
        pageSize: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _transactionHistory = history;
        });
      }
    } catch (e) {
      // Silent error handling
    }
  }

  void _deriveAddress() {
    setState(() {
      _isLoading = true;
    });

    try {
      final path = "m/44'/${widget.account.coinType.value}'/${widget.account.accountIndex}'/0/$_addressIndex";
      
      // Use signature type for address generation
      final account = _hdWallet.deriveAccountFromPath(path, widget.account.coinType, signatureType: widget.account.signatureType);

      setState(() {
        _currentAddress = account.address;
        _currentPublicKey = _bytesToHex(account.publicKey);
        _isLoading = false;
      });
      
      // Update balance and transactions for the new address
      _updateBalanceAndTransactions();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deriving address: $e')),
      );
    }
  }

  Future<void> _updateBalanceAndTransactions() async {
    try {
      // Reset pagination when address changes
      setState(() {
        _currentPage = 1;
        _transactionHistory = null;
      });
      
      // Create a temporary account model for the current address
      final tempAccount = AccountModel(
        id: '${widget.account.id}_$_addressIndex',
        walletId: widget.account.walletId,
        name: '${widget.account.name} (Index $_addressIndex)',
        coinType: widget.account.coinType,
        accountIndex: widget.account.accountIndex,
        derivationPath: "m/44'/${widget.account.coinType.value}'/${widget.account.accountIndex}'/0/$_addressIndex",
        signatureType: widget.account.signatureType,
        address: _currentAddress ?? '',
      );
      
      // Fetch balance for the new address
      final networkService = context.read<NetworkService>();
      await networkService.fetchBalance(tempAccount);
      
      // Force UI refresh to show the new balance
      if (mounted) {
        setState(() {
          // This will trigger a rebuild and show the new balance
        });
      }
      
      // Fetch transactions for the new address
      final transactionService = context.read<TransactionService>();
      final history = await transactionService.fetchTransactions(
        tempAccount,
        page: _currentPage,
        pageSize: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _transactionHistory = history;
        });
      }
    } catch (e) {
      // Silent error handling
    }
  }

  String _bytesToHex(dynamic bytes) {
    if (bytes is List<int>) {
      return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    }
    return bytes.toString();
  }

  /// Get explorer URL for an address
  String _getAddressExplorerUrl(String address, CoinType coinType) {
    switch (coinType.value) {
      case 0: // Bitcoin
        return 'https://blockstream.info/address/$address';
      case 111111: // Kaspa
        return 'https://explorer.kaspa.org/addresses/$address';
      default:
        return '';
    }
  }

  /// Get explorer URL for a transaction
  String _getTransactionExplorerUrl(String transactionHash, CoinType coinType) {
    switch (coinType.value) {
      case 0: // Bitcoin
        return 'https://blockstream.info/tx/$transactionHash';
      case 111111: // Kaspa
        return 'https://explorer.kaspa.org/txs/$transactionHash';
      default:
        return '';
    }
  }

  /// Open URL in external browser
  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account.name),
        backgroundColor: _getCoinColor(widget.account.coinType),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshBalance(context),
            tooltip: 'Refresh Balance',
          ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Account info card with balance
                  _buildAccountInfoCard(context),
                  const SizedBox(height: 16),

                  // Public Information section (Address Index, Address/QR, Public Key)
                  _buildPublicInformationSection(),
                  const SizedBox(height: 16),

                  // Transaction history
                  _buildTransactionHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountInfoCard(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        // Use the correct account ID for the current address index
        final currentAccountId = '${widget.account.id}_$_addressIndex';
        final balance = networkService.getBalanceForAccount(currentAccountId);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getCoinColor(widget.account.coinType),
                      child: Text(
                        widget.account.coinType.symbol.substring(0, 1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.account.coinType.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.account.coinType.symbol,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Full Derivation Path for current address
                _buildDerivationPathContent(),
                const SizedBox(height: 16),
                
                // Balance display
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading balance for address index $_addressIndex...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (balance != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: balance.isPositive ? Colors.green[50] : Colors.grey[100],
                      border: Border.all(
                        color: balance.isPositive ? Colors.green[300]! : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          balance.isPositive ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
                          color: balance.isPositive ? Colors.green[700] : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                balance.formattedBalance,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: balance.isPositive ? Colors.green[800] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Address explorer button
                        IconButton(
                          icon: Icon(
                            Icons.open_in_browser,
                            size: 18,
                            color: _getCoinColor(widget.account.coinType),
                          ),
                          onPressed: _currentAddress != null ? () {
                            final url = _getAddressExplorerUrl(_currentAddress!, widget.account.coinType);
                            if (url.isNotEmpty) {
                              _openUrl(url);
                            }
                          } : null,
                          tooltip: 'View Address in Explorer',
                        ),
                        if (balance.lastUpdated != null)
                          Row(
                            children: [
                              Text(
                                'Updated: ${_formatTime(balance.lastUpdated)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.autorenew, size: 8, color: Colors.blue[700]),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Auto',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Balance not available. Tap refresh to fetch balance.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublicInformationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Address
            _buildAddressContent(),
            const SizedBox(height: 20),
            
            // QR Code
            _buildQRCodeContent(),
            const SizedBox(height: 20),
            
            // Public Key
            _buildPublicKeyContent(),
          ],
        ),
      ),
    );
  }


  Widget _buildAddressContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_currentAddress != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SelectableText(
                  _currentAddress!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _currentAddress!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Address copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }

  Widget _buildQRCodeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'QR Code',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_currentAddress != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final qrSize = (constraints.maxWidth * 0.8).clamp(150.0, 200.0);
                    return QrImageView(
                      data: _currentAddress!,
                      version: QrVersions.auto,
                      size: qrSize,
                      backgroundColor: Colors.white,
                    );
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }

  Widget _buildPublicKeyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Public Key',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_currentPublicKey != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SelectableText(
                  _currentPublicKey!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _currentPublicKey!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Public key copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }

  String _getAccountDerivationPath(String fullPath) {
    // Remove the address part (last two segments) from the derivation path
    // e.g., "m/44'/0'/0'/0/0" becomes "m/44'/0'/0'"
    final parts = fullPath.split('/');
    if (parts.length >= 4) {
      return parts.take(parts.length - 2).join('/');
    }
    return fullPath;
  }

  Widget _buildDerivationPathContent() {
    // Generate the derivation path for the current address index
    final derivationPath = "m/44'/${widget.account.coinType.value}'/${widget.account.accountIndex}'/0/$_addressIndex";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Derivation Path',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _addressIndex > 0
                  ? () {
                      setState(() {
                        _addressIndex--;
                      });
                      _deriveAddress();
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 32,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SelectableText(
                      derivationPath,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: derivationPath));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Derivation path copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _addressIndex++;
                });
                _deriveAddress();
              },
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 32,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressIndexSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address Index',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _addressIndex > 0
                      ? () {
                          setState(() {
                            _addressIndex--;
                          });
                          _deriveAddress();
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 32,
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    '$_addressIndex',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _addressIndex++;
                    });
                    _deriveAddress();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 32,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "m/44'/${widget.account.coinType.value}'/${widget.account.accountIndex}'/0/$_addressIndex",
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildAddressAndQRCode() {
    final coinColor = _getCoinColor(widget.account.coinType);
    
    return Card(
      color: coinColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: coinColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Address & QR Code',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.open_in_browser, color: coinColor),
                      onPressed: _currentAddress != null ? () {
                        final url = _getAddressExplorerUrl(_currentAddress!, widget.account.coinType);
                        if (url.isNotEmpty) {
                          _openUrl(url);
                        }
                      } : null,
                      tooltip: 'View in Explorer',
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: coinColor),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _currentAddress ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Address copied to clipboard')),
                        );
                      },
                      tooltip: 'Copy Address',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Address text
            SelectableText(
              _currentAddress ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // QR Code
            if (_currentAddress != null) ...[
              const Text(
                'Scan to Send',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final qrSize = (constraints.maxWidth * 0.6).clamp(150.0, 200.0);
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: _currentAddress!,
                        version: QrVersions.auto,
                        size: qrSize,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPublicKeyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Public Key',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _currentPublicKey ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Public key copied to clipboard')),
                    );
                  },
                  tooltip: 'Copy Public Key',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              _currentPublicKey ?? '',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCoinColor(CoinType coinType) {
    switch (coinType.value) {
      case 0:
        return const Color(0xFFD4AF37); // Gold - Bitcoin
      case 111111:
        return const Color(0xFFC0C0C0); // Silver - Kaspa
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchBalanceOnOpen() async {
    try {
      // Create a temporary account model for the current address
      final tempAccount = AccountModel(
        id: '${widget.account.id}_$_addressIndex',
        walletId: widget.account.walletId,
        name: '${widget.account.name} (Index $_addressIndex)',
        coinType: widget.account.coinType,
        accountIndex: widget.account.accountIndex,
        derivationPath: "m/44'/${widget.account.coinType.value}'/${widget.account.accountIndex}'/0/$_addressIndex",
        signatureType: widget.account.signatureType,
        address: _currentAddress ?? '',
      );
      
      final networkService = context.read<NetworkService>();
      await networkService.fetchBalance(tempAccount);
    } catch (e) {
      // Don't show error to user on automatic fetch
    }
  }

  Future<void> _refreshBalance(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching balance...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      // Create a temporary account model for the current address
      final tempAccount = AccountModel(
        id: '${widget.account.id}_$_addressIndex',
        walletId: widget.account.walletId,
        name: '${widget.account.name} (Index $_addressIndex)',
        coinType: widget.account.coinType,
        accountIndex: widget.account.accountIndex,
        derivationPath: "m/44'/${widget.account.coinType.value}'/${widget.account.accountIndex}'/0/$_addressIndex",
        signatureType: widget.account.signatureType,
        address: _currentAddress ?? '',
      );
      
      final networkService = context.read<NetworkService>();
      await networkService.fetchBalance(tempAccount);
      
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balance updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching balance: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatConfirmations(int confirmations) {
    if (confirmations < 1000) {
      return confirmations.toString();
    } else if (confirmations < 1000000) {
      return '${(confirmations / 1000).toStringAsFixed(1)}K';
    } else if (confirmations < 1000000000) {
      return '${(confirmations / 1000000).toStringAsFixed(1)}M';
    } else {
      return '${(confirmations / 1000000000).toStringAsFixed(1)}B';
    }
  }

  Widget _buildTransactionHistory() {
    return Consumer<TransactionService>(
      builder: (context, transactionService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use LayoutBuilder to handle different screen sizes
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrowScreen = constraints.maxWidth < 400;
                    
                    if (isNarrowScreen) {
                      // Stack layout for narrow screens
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Transaction History',
                                  style: AppTheme.getResponsiveTextStyle(
                                    context,
                                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    desktopMultiplier: 1.1,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _isLoadingTransactions ? null : () => _loadTransactions(),
                                tooltip: 'Refresh Transactions',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.autorenew, size: AppTheme.getTransactionDetailIconSize(context), color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'Auto-refresh',
                                  style: AppTheme.getResponsiveTextStyle(
                                    context,
                                    TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    desktopMultiplier: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Row layout for wider screens
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Text(
                                  'Transaction History',
                                  style: AppTheme.getResponsiveTextStyle(
                                    context,
                                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    desktopMultiplier: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.autorenew, size: AppTheme.getTransactionDetailIconSize(context), color: Colors.green[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Auto-refresh',
                                        style: AppTheme.getResponsiveTextStyle(
                                          context,
                                          TextStyle(
                                            fontSize: 10,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          desktopMultiplier: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _isLoadingTransactions ? null : () => _loadTransactions(),
                            tooltip: 'Refresh Transactions',
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                if (_isLoadingTransactions)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_transactionHistory == null || _transactionHistory!.isEmpty)
                  _buildEmptyTransactions()
                else
                  Column(
                    children: [
                      // Transaction list
                      ..._transactionHistory!.transactions.map((transaction) => 
                        _buildTransactionItem(transaction)
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Pagination controls
                      _buildPaginationControls(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transactions will appear here once you send or receive funds.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isReceived = transaction.type == TransactionType.received;
    final isPending = transaction.status == TransactionStatus.pending;
    final isFailed = transaction.status == TransactionStatus.failed;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReceived ? Colors.green[50] : Colors.blue[50],
        border: Border.all(
          color: isReceived ? Colors.green[200]! : Colors.blue[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Transaction icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isReceived ? Colors.green[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isReceived ? Colors.green[700] : Colors.blue[700],
                  size: AppTheme.getTransactionIconSize(context),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.typeDisplayName,
                                style: AppTheme.getTransactionTypeStyle(context),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(transaction.timestamp),
                                style: AppTheme.getTransactionTimeStyle(context),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              transaction.formattedAmount,
                              style: AppTheme.getTransactionAmountStyle(
                                context,
                                color: isReceived ? Colors.green[800] : Colors.blue[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(transaction.status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                transaction.statusDisplayName,
                                style: AppTheme.getTransactionStatusStyle(context),
                              ),
                            ),
                            if (transaction.confirmations > 0) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '${_formatConfirmations(transaction.confirmations)} confirmations',
                                  style: AppTheme.getTransactionConfirmationsStyle(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (transaction.memo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        transaction.memo!,
                        style: AppTheme.getTransactionMemoStyle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Explorer button
              if (transaction.hash != null)
                IconButton(
                  icon: Icon(
                    Icons.open_in_browser,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    final url = _getTransactionExplorerUrl(transaction.hash!, widget.account.coinType);
                    if (url.isNotEmpty) {
                      _openUrl(url);
                    }
                  },
                  tooltip: 'View in Explorer',
                ),
            ],
          ),
          
          // Additional transaction information
          if (transaction.hash != null || transaction.fromAddress != null || transaction.toAddress != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (transaction.hash != null) ...[
                    Row(
                      children: [
                        Icon(Icons.fingerprint, size: AppTheme.getTransactionDetailIconSize(context), color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Hash: ',
                          style: AppTheme.getTransactionDetailLabelStyle(context),
                        ),
                        Expanded(
                          child: Text(
                            transaction.hash!,
                            style: AppTheme.getTransactionDetailStyle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (transaction.fromAddress != null && transaction.fromAddress != transaction.address) ...[
                    Row(
                      children: [
                        Icon(Icons.arrow_upward, size: AppTheme.getTransactionDetailIconSize(context), color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'From: ',
                          style: AppTheme.getTransactionDetailLabelStyle(context),
                        ),
                        Expanded(
                          child: Text(
                            transaction.fromAddress!,
                            style: AppTheme.getTransactionDetailStyle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (transaction.toAddress != null && transaction.toAddress != transaction.address) ...[
                    Row(
                      children: [
                        Icon(Icons.arrow_downward, size: AppTheme.getTransactionDetailIconSize(context), color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'To: ',
                          style: AppTheme.getTransactionDetailLabelStyle(context),
                        ),
                        Expanded(
                          child: Text(
                            transaction.toAddress!,
                            style: AppTheme.getTransactionDetailStyle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (transaction.fee > BigInt.zero) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_gas_station, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Fee: ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          transaction.formattedFee,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_transactionHistory == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Page info with total count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Page ${_transactionHistory!.currentPage} of ${_transactionHistory!.totalPages}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_transactionHistory!.totalCount} total)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Pagination buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrowScreen = constraints.maxWidth < 400;
              if (isNarrowScreen) {
                // Icon-only controls for mobile/narrow screens
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous (icon only)
                    IconButton(
                      onPressed: _transactionHistory!.hasPreviousPage ? _previousPage : null,
                      icon: const Icon(Icons.chevron_left, size: 24),
                      tooltip: 'Previous',
                    ),

                    // Page jump buttons (first/last)
                    Row(
                      children: [
                        IconButton(
                          onPressed: _transactionHistory!.currentPage > 1 ? () => _jumpToPage(1) : null,
                          icon: const Icon(Icons.first_page),
                          tooltip: 'First Page',
                          style: IconButton.styleFrom(
                            backgroundColor: _transactionHistory!.currentPage > 1 ? Colors.blue[50] : Colors.grey[100],
                          ),
                        ),
                        IconButton(
                          onPressed: _transactionHistory!.hasNextPage ? () => _jumpToPage(_transactionHistory!.totalPages) : null,
                          icon: const Icon(Icons.last_page),
                          tooltip: 'Last Page',
                          style: IconButton.styleFrom(
                            backgroundColor: _transactionHistory!.hasNextPage ? Colors.blue[50] : Colors.grey[100],
                          ),
                        ),
                      ],
                    ),

                    // Next (icon only)
                    IconButton(
                      onPressed: _transactionHistory!.hasNextPage ? _nextPage : null,
                      icon: const Icon(Icons.chevron_right, size: 24),
                      tooltip: 'Next',
                    ),
                  ],
                );
              } else {
                // Labeled controls for wider/desktop screens (original layout)
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous page button
                    ElevatedButton.icon(
                      onPressed: _transactionHistory!.hasPreviousPage ? _previousPage : null,
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _transactionHistory!.hasPreviousPage ? Colors.blue[100] : Colors.grey[200],
                        foregroundColor: _transactionHistory!.hasPreviousPage ? Colors.blue[800] : Colors.grey[500],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    
                    // Page jump buttons
                    Row(
                      children: [
                        // First page
                        IconButton(
                          onPressed: _transactionHistory!.currentPage > 1 ? () => _jumpToPage(1) : null,
                          icon: const Icon(Icons.first_page),
                          tooltip: 'First Page',
                          style: IconButton.styleFrom(
                            backgroundColor: _transactionHistory!.currentPage > 1 ? Colors.blue[50] : Colors.grey[100],
                          ),
                        ),
                        
                        // Last page
                        IconButton(
                          onPressed: _transactionHistory!.hasNextPage ? () => _jumpToPage(_transactionHistory!.totalPages) : null,
                          icon: const Icon(Icons.last_page),
                          tooltip: 'Last Page',
                          style: IconButton.styleFrom(
                            backgroundColor: _transactionHistory!.hasNextPage ? Colors.blue[50] : Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                    
                    // Next page button
                    ElevatedButton.icon(
                      onPressed: _transactionHistory!.hasNextPage ? _nextPage : null,
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _transactionHistory!.hasNextPage ? Colors.blue[100] : Colors.grey[200],
                        foregroundColor: _transactionHistory!.hasNextPage ? Colors.blue[800] : Colors.grey[500],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      // Create a temporary account model for the current address
      final tempAccount = AccountModel(
        id: '${widget.account.id}_$_addressIndex',
        walletId: widget.account.walletId,
        name: '${widget.account.name} (Index $_addressIndex)',
        coinType: widget.account.coinType,
        accountIndex: widget.account.accountIndex,
        derivationPath: "m/44'/${widget.account.coinType.value}'/${widget.account.accountIndex}'/0/$_addressIndex",
        signatureType: widget.account.signatureType,
        address: _currentAddress ?? '',
      );
      
      final transactionService = context.read<TransactionService>();
      final history = await transactionService.fetchTransactions(
        tempAccount,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _transactionHistory = history;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previousPage() {
    if (_transactionHistory?.hasPreviousPage == true) {
      setState(() {
        _currentPage--;
      });
      _loadTransactions();
    }
  }

  void _nextPage() {
    if (_transactionHistory?.hasNextPage == true) {
      setState(() {
        _currentPage++;
      });
      _loadTransactions();
    }
  }

  void _jumpToPage(int page) {
    if (page >= 1 && page <= (_transactionHistory?.totalPages ?? 1)) {
      setState(() {
        _currentPage = page;
      });
      _loadTransactions();
    }
  }
}

