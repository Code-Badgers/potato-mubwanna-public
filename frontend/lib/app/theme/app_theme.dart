import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    return ThemeData(
      fontFamily: 'Pretendard',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize:
              const Size(AppDimens.buttonHeight, AppDimens.buttonHeight),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.textSecondary,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize:
              const Size(AppDimens.buttonHeight, AppDimens.buttonHeight),
          foregroundColor: AppColors.actionGreen,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: AppColors.actionGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.actionGreen,
          minimumSize:
              const Size(AppDimens.buttonHeight, AppDimens.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          textStyle: AppTextStyles.button,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.actionGreen,
          minimumSize:
              const Size(AppDimens.buttonHeight, AppDimens.buttonHeight),
        ),
      ),
      useMaterial3: true,
    );
  }
}
