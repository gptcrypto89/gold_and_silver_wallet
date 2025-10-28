import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/wallet_manager.dart';
import 'services/network_service.dart';
import 'services/transaction_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/password_setup_screen.dart';
import 'screens/password_unlock_screen.dart';

void main() {
  runApp(const GoldAndSilverWalletApp());
}

class GoldAndSilverWalletApp extends StatelessWidget {
  const GoldAndSilverWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletManager()),
        ChangeNotifierProvider(create: (_) {
          final networkService = NetworkService();
          networkService.initializeDefaultNetworks();
          return networkService;
        }),
        ChangeNotifierProvider(create: (_) => TransactionService()),
      ],
      child: MaterialApp(
        title: 'Gold and Silver Wallet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AppInitializer(),
      ),
    );
  }
}

/// Initializes app and determines which screen to show
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  Widget build(BuildContext context) {
    final walletManager = context.watch<WalletManager>();

    return FutureBuilder<bool>(
      future: walletManager.hasPassword(),
      builder: (context, snapshot) {
        // Show loading while checking
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radius20),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final hasPassword = snapshot.data!;

        // If password exists, show unlock screen
        if (hasPassword) {
          return const PasswordUnlockScreen();
        }

        // Otherwise, show password setup screen
        return const PasswordSetupScreen();
      },
    );
  }
}
