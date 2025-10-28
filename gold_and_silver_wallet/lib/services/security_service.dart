import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Security service to check network connectivity and enforce offline requirements
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device is connected to any network
  Future<bool> isDeviceConnected() async {
    try {
      final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
      
      // Check if any connection type is active (not none)
      return result.any((connection) => connection != ConnectivityResult.none);
    } catch (e) {
      // If we can't determine, assume connected for safety
      return true;
    }
  }

  /// Check if device is in a secure offline state
  Future<bool> isSecureOfflineState() async {
    final isConnected = await isDeviceConnected();
    return !isConnected;
  }

  /// Show a security warning dialog when device is connected
  Future<bool> showSecurityWarningDialog(BuildContext context) async {
    final isConnected = await isDeviceConnected();
    
    if (!isConnected) {
      return true; // Device is offline, safe to proceed
    }

    // Show warning dialog
    if (!context.mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.red),
          title: const Text(
            'Security Warning',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your device is connected to the internet!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'For maximum security when handling sensitive wallet information:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '• Turn on Airplane Mode\n'
                '• Disable Wi-Fi\n'
                '• Disable Mobile Data\n'
                '• Disable Bluetooth',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'This ensures your private keys and recovery phrase cannot be intercepted.',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.warning),
              label: const Text('Continue Anyway (Not Recommended)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Block action if device is connected (stricter enforcement)
  Future<bool> enforceOfflineMode(BuildContext context) async {
    final isConnected = await isDeviceConnected();
    
    if (!isConnected) {
      return true; // Device is offline, safe to proceed
    }

    // Show blocking dialog
    if (!context.mounted) return false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.signal_wifi_off, size: 64, color: Colors.red),
          title: const Text(
            'Offline Mode Required',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action requires your device to be offline.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'To proceed:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Turn on Airplane Mode\n'
                '2. Disable Wi-Fi and Mobile Data\n'
                '3. Return to this screen',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '🔒 This protects your private keys from potential network threats.',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I Understand'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    return false; // Block the action
  }

  /// Show a persistent warning banner when device is connected
  Widget buildSecurityBanner(BuildContext context) {
    return FutureBuilder<bool>(
      future: isDeviceConnected(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[100],
              border: Border(
                bottom: BorderSide(color: Colors.red[300]!, width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[900]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Device is online! Turn on Airplane Mode for security.',
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}

