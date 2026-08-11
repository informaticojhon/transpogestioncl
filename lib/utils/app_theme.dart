import 'package:flutter/material.dart';

class AppTheme {
  // Paleta base: azul profundo con acento esmeralda, look "dashboard" moderno.
  static const Color _seed = Color(0xFF2454FF);
  static const Color accent = Color(0xFF10B981);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  static const Color _lightBackground = Color(0xFFF5F6FA);
  static const Color _darkBackground = Color(0xFF12141C);
  static const Color _darkSurface = Color(0xFF1B1E29);

  static RoundedRectangleBorder _cardShape([double radius = 16]) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  static InputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    background: _lightBackground,
    surface: Colors.white,
    fieldFill: const Color(0xFFF0F1F6),
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    background: _darkBackground,
    surface: _darkSurface,
    fieldFill: const Color(0xFF232634),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color fieldFill,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    ).copyWith(surface: surface, secondary: accent);

    final onSurface = colorScheme.onSurface;
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(
            bodyColor: onSurface,
            displayColor: onSurface,
          )
          .copyWith(
            headlineSmall: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: onSurface,
              letterSpacing: -0.3,
            ),
            titleLarge: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: onSurface,
            ),
            titleMedium: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: onSurface,
            ),
            bodyMedium: TextStyle(fontSize: 14, color: onSurface, height: 1.4),
            labelLarge: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          colorScheme.onSurface.withValues(alpha: 0.18),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: _cardShape().copyWith(
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: isDark ? 0.24 : 0.10),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: _cardShape(16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: _cardShape(12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: _cardShape(12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: _cardShape(10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(colorScheme.primary, width: 1.6),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.6),
        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4)),
      ),
      listTileTheme: ListTileThemeData(
        shape: _cardShape(12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: onSurface.withValues(alpha: 0.7),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.12),
        thickness: 1,
        space: 24,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: onSurface.withValues(alpha: 0.5),
        indicatorColor: colorScheme.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary.withValues(alpha: 0.5)
              : null,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fieldFill,
        labelStyle: TextStyle(color: onSurface, fontSize: 12),
        shape: _cardShape(20),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: _cardShape(20),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(color: onSurface.withValues(alpha: 0.5)),
        unselectedLabelTextStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        useIndicator: true,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: _cardShape(12),
        backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFF1F2430),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
