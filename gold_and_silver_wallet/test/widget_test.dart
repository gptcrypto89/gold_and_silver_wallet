// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:gold_and_silver_wallet/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Gold and SilverWalletApp());

    // Verify that the app title is displayed.
    expect(find.text('Gold and Silver Wallet'), findsWidgets);
    
    // Verify that the generate button is present.
    expect(find.text('Generate New Keys'), findsOneWidget);
  });
}
