import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppDimens {
  const AppDimens._();

  static const pageHorizontalPadding = 20.0;
  static const cardRadius = 22.0;
  static const compactCardRadius = 18.0;
  static const sheetRadius = 28.0;
  static const buttonRadius = 18.0;
  static const pillRadius = 999.0;
  static const bottomNavigationHeight = 78.0;
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get softCard => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ];
}

class AppDecorations {
  const AppDecorations._();

  static BoxDecoration card({
    Color color = AppColors.surface,
    double alpha = 0.94,
    double radius = AppDimens.cardRadius,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.line.withValues(alpha: 0.82)),
      boxShadow: shadow ? AppShadows.softCard : null,
    );
  }

  static BoxDecoration mutedCard({
    Color color = AppColors.primaryTint,
    double radius = AppDimens.cardRadius,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.line.withValues(alpha: 0.62)),
    );
  }

  static ShapeBorder cardShape({
    double radius = AppDimens.cardRadius,
    Color borderColor = AppColors.line,
  }) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor.withValues(alpha: 0.82)),
    );
  }
}
