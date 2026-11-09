import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  /// Fonte em pixel (Pixelify Sans) só nos títulos grandes. Números, botões
  /// e texto corrido ficam na fonte padrão: no pixel, "5" parece "S".
  static const pixelFont = 'PixelifySans';

  /// Peso pelo eixo da fonte variável (o negrito "falso" borra o pixel).
  static const pixelWeight = [FontVariation('wght', 600)];

  static TextTheme _textTheme(TextTheme base) {
    TextStyle? pixel(TextStyle? style) => style?.copyWith(
      fontFamily: pixelFont,
      fontVariations: pixelWeight,
      letterSpacing: 0.3,
    );
    return base.copyWith(
      displayLarge: pixel(base.displayLarge),
      displayMedium: pixel(base.displayMedium),
      displaySmall: pixel(base.displaySmall),
      headlineLarge: pixel(base.headlineLarge),
      headlineMedium: pixel(base.headlineMedium),
      headlineSmall: pixel(base.headlineSmall),
      titleLarge: pixel(base.titleLarge),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.skyDeep,
      secondary: AppColors.auroraTeal,
      onSecondary: AppColors.skyDeep,
      tertiary: AppColors.auroraLilac,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.outline,
      error: AppColors.error,
      onError: AppColors.skyDeep,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outline),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _textTheme(base.textTheme),
      scaffoldBackgroundColor: AppColors.skyDeep,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.skyDeep,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.skyMid,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.auroraTeal, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.skyDeep,
          disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.skyDeep,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.auroraTeal),
      ),
    );
  }
}
