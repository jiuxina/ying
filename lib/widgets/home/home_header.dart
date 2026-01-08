import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';
import '../common/ui_helpers.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onArchiveTap;
  final VoidCallback? onCalendarTap;

  const HomeHeader({
    super.key,
    this.onSearchTap,
    this.onSettingsTap,
    this.onArchiveTap,
    this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          _buildAppTitle(context),
          const Spacer(),
          // 搜索按钮
          GlassIconButton(
            icon: Icons.search_rounded,
            onPressed: () {
              HapticFeedback.selectionClick();
              onSearchTap?.call();
            },
          ),
          const SizedBox(width: 4),
          // 设置按钮
          GlassIconButton(
            icon: Icons.settings_rounded,
            onPressed: () {
              HapticFeedback.selectionClick();
              onSettingsTap?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppTitle(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'app.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Icon(Icons.event_note, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              AppConstants.appDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
