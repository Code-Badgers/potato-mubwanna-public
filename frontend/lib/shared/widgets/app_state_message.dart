import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_design_tokens.dart';

/// An unframed state message that works inside a section or a full page.
class AppStateMessage extends StatelessWidget {
  const AppStateMessage({
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.pageHorizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 36),
          const SizedBox(height: AppDimens.contentSpacing),
          Text(title,
              textAlign: TextAlign.center, style: AppTextStyles.stateTitle),
          if (description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(description!,
                textAlign: TextAlign.center, style: AppTextStyles.body),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppDimens.buttonHeight),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
