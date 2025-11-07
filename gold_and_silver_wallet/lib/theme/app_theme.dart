import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern design system for Gold and Silver Wallet
/// Following Material Design 3 guidelines with premium Gold/Silver theme
class AppTheme {
  // Color Palette
  static const Color goldPrimary = Color(0xFFF08E19);
  static const Color goldSecondary = Color(0xFFFFF4E6);
  static const Color goldTertiary = Color(0xFFC06E14);
  static const Color goldSurface = Color(0xFFFFF4E6);
  
  static const Color silverPrimary = Color(0xFF6EC7BB);
  static const Color silverSecondary = Color(0xFFE6F7F4);
  static const Color silverTertiary = Color(0xFF4FA896);
  static const Color silverSurface = Color(0xFFE6F7F4);
  
  // Neutral Colors
  static const Color surface = Color(0xFFFFFBFE);
  static const Color surfaceVariant = Color(0xFFF3F0F4);
  static const Color surfaceContainer = Color(0xFFF3F0F4);
  static const Color surfaceContainerHigh = Color(0xFFECE6F0);
  static const Color surfaceContainerHighest = Color(0xFFE6E0E9);
  
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
  
  // Elegant Gold & Silver UI Colors
  static const Color primaryGold = Color(0xFFF08E19); // Gold orange
  static const Color primaryGoldLight = Color(0xFFFFA64D); // Lighter gold
  static const Color primaryGoldDark = Color(0xFFC06E14); // Darker gold
  static const Color primaryGoldSurface = Color(0xFFFFF4E6); // Warm gold surface
  
  static const Color secondarySilver = Color(0xFF6EC7BB); // Teal silver
  static const Color secondarySilverLight = Color(0xFF8ED9CC); // Lighter silver
  static const Color secondarySilverDark = Color(0xFF4FA896); // Darker silver
  static const Color secondarySilverSurface = Color(0xFFE6F7F4); // Cool silver surface
  
  static const Color accentBronze = Color(0xFFCD7F32); // Bronze accent
  static const Color accentBronzeLight = Color(0xFFE6A85C);
  static const Color accentBronzeSurface = Color(0xFFF5E6D3);

  // Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF1B5E20);
  
  static const Color warning = Color(0xFFF57C00);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFFE65100);
  
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFCDD2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFFB71C1C);
  
  // Spacing System (6px base unit for mobile)
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;
  
  // Border Radius System
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  
  // Elevation System
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 3.0;
  static const double elevation4 = 4.0;
  static const double elevation5 = 5.0;
  static const double elevation6 = 6.0;
  
  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
  
  // Text Styles - Mobile Optimized
  static const TextStyle displayLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Responsive Text Utilities
  static double getResponsiveFontSize(BuildContext context, double mobileSize, {double? desktopMultiplier}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    
    if (isDesktop) {
      return mobileSize * (desktopMultiplier ?? 1.2);
    }
    return mobileSize;
  }

  static TextStyle getResponsiveTextStyle(
    BuildContext context, 
    TextStyle baseStyle, 
    {double? desktopMultiplier}
  ) {
    return baseStyle.copyWith(
      fontSize: getResponsiveFontSize(
        context, 
        baseStyle.fontSize ?? 14, 
        desktopMultiplier: desktopMultiplier
      ),
    );
  }

  // Common responsive text styles for transaction items
  static TextStyle getTransactionTypeStyle(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      desktopMultiplier: 1.15,
    );
  }

  static TextStyle getTransactionAmountStyle(BuildContext context, {Color? color}) {
    return getResponsiveTextStyle(
      context,
      TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: color,
      ),
      desktopMultiplier: 1.15,
    );
  }

  static TextStyle getTransactionTimeStyle(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
      desktopMultiplier: 1.1,
    );
  }

  static TextStyle getTransactionStatusStyle(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      desktopMultiplier: 1.2,
    );
  }

  static TextStyle getTransactionConfirmationsStyle(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: Colors.blue[700],
      ),
      desktopMultiplier: 1.2,
    );
  }

  static TextStyle getTransactionMemoStyle(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      TextStyle(
        fontSize: 11,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
      desktopMultiplier: 1.1,
    );
  }

  static TextStyle getTransactionDetailStyle(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      TextStyle(
        fontSize: 10,
        color: Colors.grey[600],
        fontFamily: 'monospace',
      ),
      desktopMultiplier: 1.1,
    );
  }

  static TextStyle getTransactionDetailLabelStyle(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
      desktopMultiplier: 1.1,
    );
  }

  // Responsive Icon Sizes
  static double getResponsiveIconSize(BuildContext context, double mobileSize, {double? desktopMultiplier}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    
    if (isDesktop) {
      return mobileSize * (desktopMultiplier ?? 1.2);
    }
    return mobileSize;
  }

  // Common responsive icon sizes for transaction items
  static double getTransactionIconSize(BuildContext context) {
    return getResponsiveIconSize(context, 20, desktopMultiplier: 1.15);
  }

  static double getTransactionDetailIconSize(BuildContext context) {
    return getResponsiveIconSize(context, 12, desktopMultiplier: 1.2);
  }

  static double getTransactionSmallIconSize(BuildContext context) {
    return getResponsiveIconSize(context, 10, desktopMultiplier: 1.2);
  }

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: goldPrimary,
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: goldSurface,
        onPrimaryContainer: goldTertiary,
        secondary: silverPrimary,
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: silverSurface,
        onSecondaryContainer: silverTertiary,
        tertiary: goldTertiary,
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: goldSecondary,
        onTertiaryContainer: goldTertiary,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceVariant: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        outline: outline,
        outlineVariant: outlineVariant,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF313033),
        onInverseSurface: Color(0xFFF4EFF4),
        inversePrimary: goldSecondary,
      ),
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        iconTheme: IconThemeData(
          color: onSurface,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: onSurface,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation1,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          textStyle: labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          textStyle: labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          textStyle: labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space12,
          ),
          textStyle: labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: goldPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space16,
        ),
        labelStyle: bodyLarge.copyWith(color: onSurfaceVariant),
        hintStyle: bodyLarge.copyWith(color: onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHigh,
        selectedColor: goldPrimary,
        disabledColor: surfaceContainer,
        labelStyle: labelMedium,
        secondaryLabelStyle: labelMedium.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: space12,
          vertical: space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius8),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
        titleTextStyle: titleMedium,
        subtitleTextStyle: bodyMedium,
        leadingAndTrailingTextStyle: bodySmall,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: elevation3,
        backgroundColor: surface,
        selectedItemColor: goldPrimary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: elevation3,
        highlightElevation: elevation6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: goldPrimary,
        onPrimary: Color(0xFF000000),
        primaryContainer: goldTertiary,
        onPrimaryContainer: goldSecondary,
        secondary: silverPrimary,
        onSecondary: Color(0xFF000000),
        secondaryContainer: silverTertiary,
        onSecondaryContainer: silverSecondary,
        tertiary: goldSecondary,
        onTertiary: Color(0xFF000000),
        tertiaryContainer: goldTertiary,
        onTertiaryContainer: goldSecondary,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF1C1B1F),
        onSurface: Color(0xFFE6E0E9),
        surfaceVariant: Color(0xFF49454F),
        onSurfaceVariant: Color(0xFFCAC4D0),
        surfaceContainer: Color(0xFF313033),
        surfaceContainerHigh: Color(0xFF3B383E),
        surfaceContainerHighest: Color(0xFF464249),
        outline: Color(0xFF938F99),
        outlineVariant: Color(0xFF49454F),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFE6E0E9),
        onInverseSurface: Color(0xFF313033),
        inversePrimary: goldTertiary,
      ),
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6E0E9),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFE6E0E9),
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: Color(0xFFE6E0E9),
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation1,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          textStyle: labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          textStyle: labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space16,
          ),
          textStyle: labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space12,
          ),
          textStyle: labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF313033),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: Color(0xFF49454F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: Color(0xFF49454F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: goldPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space16,
        ),
        labelStyle: bodyLarge.copyWith(color: const Color(0xFFCAC4D0)),
        hintStyle: bodyLarge.copyWith(color: const Color(0xFFCAC4D0)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF3B383E),
        selectedColor: goldPrimary,
        disabledColor: const Color(0xFF313033),
        labelStyle: labelMedium,
        secondaryLabelStyle: labelMedium.copyWith(color: const Color(0xFF000000)),
        padding: const EdgeInsets.symmetric(
          horizontal: space12,
          vertical: space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius8),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
        titleTextStyle: titleMedium,
        subtitleTextStyle: bodyMedium,
        leadingAndTrailingTextStyle: bodySmall,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: elevation3,
        backgroundColor: Color(0xFF1C1B1F),
        selectedItemColor: goldPrimary,
        unselectedItemColor: Color(0xFFCAC4D0),
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: elevation3,
        highlightElevation: elevation6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF49454F),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Custom gradients for premium feel
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldPrimary, goldTertiary],
  );

  static const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [silverPrimary, silverTertiary],
  );

  /// Elegant Gold & Silver gradients
  static const LinearGradient primaryGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGold, primaryGoldDark],
  );

  static const LinearGradient secondarySilverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondarySilver, secondarySilverDark],
  );

  static const LinearGradient accentBronzeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBronze, accentBronzeLight],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, surfaceVariant],
  );

  /// Custom shadows for depth
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
