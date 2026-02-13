import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/events_provider.dart';
import '../models/category_model.dart';
import '../utils/responsive_utils.dart';

/// 分类筛选器组件
class CategorySelector extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  const CategorySelector({
    super.key,
    this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get categories from provider
    final categories = context.select<EventsProvider, List<Category>>((p) => p.categories);

    return SizedBox(
      height: ResponsiveUtils.scaledSize(context, 40),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSpacing.md(context),
        ),
        children: [
          // "全部"选项
          _buildChip(
            context: context,
            label: '全部',
            emoji: '📋',
            isSelected: selectedCategoryId == null,
            onTap: () => onCategoryChanged(null),
            color: theme.colorScheme.primary,
          ),
          // 各分类选项
          ...categories.map((category) {
            final color = Color(category.color);
            return _buildChip(
              context: context,
              label: category.name,
              emoji: category.icon,
              isSelected: selectedCategoryId == category.id,
              onTap: () => onCategoryChanged(category.id),
              color: color,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.xs(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveBorderRadius.lg(context),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSpacing.md(context) + 2,
              vertical: ResponsiveSpacing.sm(context),
            ),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withAlpha(25),
              borderRadius: BorderRadius.circular(
                ResponsiveBorderRadius.lg(context),
              ),
              border: Border.all(
                color: isSelected ? color : color.withAlpha(80),
                width: ResponsiveUtils.scaledSize(context, 1.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.base(context),
                  ),
                  overflow: TextOverflow.visible,
                ),
                SizedBox(width: ResponsiveSpacing.xs(context) + 2),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontSize: ResponsiveFontSize.md(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
