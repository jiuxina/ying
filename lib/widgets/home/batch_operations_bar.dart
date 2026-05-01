import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/batch_operations_provider.dart';
import '../../providers/events_provider.dart';
import '../../utils/responsive_utils.dart';

/// 批量操作底部操作栏
class BatchOperationsBar extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onChangeCategory;
  final VoidCallback? onExport;

  const BatchOperationsBar({
    super.key,
    this.onDelete,
    this.onArchive,
    this.onChangeCategory,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final batchOps = context.watch<BatchOperationsProvider>();
    final eventsProvider = context.watch<EventsProvider>();
    final theme = Theme.of(context);
    
    final selectedCount = batchOps.selectedCount;
    final totalCount = eventsProvider.events.length;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 选择状态栏
            _buildSelectionHeader(context, batchOps, selectedCount, totalCount, theme),
            
            // 操作按钮
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSpacing.md(context),
                vertical: ResponsiveSpacing.sm(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context: context,
                    icon: Icons.delete_outline,
                    label: '删除',
                    color: Colors.red,
                    onPressed: selectedCount > 0 ? onDelete : null,
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.archive_outlined,
                    label: '归档',
                    color: Colors.orange,
                    onPressed: selectedCount > 0 ? onArchive : null,
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.folder_outlined,
                    label: '分类',
                    color: Colors.blue,
                    onPressed: selectedCount > 0 ? onChangeCategory : null,
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.ios_share_outlined,
                    label: '导出',
                    color: Colors.teal,
                    onPressed: selectedCount > 0 ? onExport : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader(
    BuildContext context,
    BatchOperationsProvider batchOps,
    int selectedCount,
    int totalCount,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.md(context),
        vertical: ResponsiveSpacing.xs(context),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(50),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha(50),
          ),
        ),
      ),
      child: Row(
        children: [
          // 全选按钮
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (batchOps.allSelected) {
                batchOps.deselectAll();
              } else {
                batchOps.selectAll();
              }
            },
            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.sm(context)),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveSpacing.xs(context)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    batchOps.allSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: ResponsiveIconSize.sm(context),
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: ResponsiveSpacing.xs(context)),
                  Text(
                    '全选',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.sm(context),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // 选择计数
          Text(
            '已选 $selectedCount / $totalCount',
            style: TextStyle(
              fontSize: ResponsiveFontSize.sm(context),
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          
          SizedBox(width: ResponsiveSpacing.md(context)),
          
          // 取消按钮
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              batchOps.exitSelectionMode();
            },
            child: Text(
              '取消',
              style: TextStyle(
                fontSize: ResponsiveFontSize.sm(context),
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    
    return InkWell(
      onTap: isEnabled
          ? () {
              HapticFeedback.mediumImpact();
              onPressed();
            }
          : null,
      borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSpacing.sm(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ResponsiveIconSize.md(context),
                color: isEnabled ? color : Colors.grey,
              ),
              SizedBox(height: ResponsiveSpacing.xs(context)),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveFontSize.xs(context),
                  color: isEnabled ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
