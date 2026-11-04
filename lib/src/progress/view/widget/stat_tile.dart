import 'package:flutter/material.dart';

import '../../../../utils/app_spacing.dart';

/// Labelled value, e.g. "Best e1RM / 120 kg".
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppInsets.card,
        child: Semantics(
          label: '$label: $value${caption == null ? '' : ', $caption'}',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: AppSizes.iconSm,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    child: Text(label, style: theme.textTheme.labelMedium),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: theme.textTheme.titleLarge),
              if (caption != null)
                Text(caption!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
