import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    this.icon = Icons.event_available,
    this.title = '还没有事件',
    this.description = '点击右下角按钮添加第一个倒数日',
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSpacing.xxxl(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: ResponsiveIconSize.xxl(context),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: ResponsiveSpacing.xl(context)),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveSpacing.sm(context)),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              overflow: TextOverflow.visible,
              softWrap: true,
              maxLines: 3,
            ),
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: ResponsiveSpacing.lg(context)),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.clear),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
