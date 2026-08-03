import 'package:flutter/material.dart';

import '../models/event_sort_mode.dart';
import 'glass_ui.dart';

class EventFilterBar extends StatelessWidget {
  const EventFilterBar({
    super.key,
    required this.controller,
    required this.searchExpanded,
    required this.incompleteOnly,
    required this.selectedCategory,
    required this.categories,
    required this.sortMode,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.onIncompleteChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool searchExpanded;
  final bool incompleteOnly;
  final String? selectedCategory;
  final List<String> categories;
  final EventSortMode sortMode;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onIncompleteChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<EventSortMode> onSortChanged;
  final VoidCallback onClear;

  bool get hasFilters =>
      controller.text.trim().isNotEmpty ||
      incompleteOnly ||
      selectedCategory != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterButton(
                  icon: Icons.search_rounded,
                  label: searchExpanded ? '收起搜索' : '搜索事件',
                  selected: searchExpanded || controller.text.isNotEmpty,
                  onTap: onToggleSearch,
                ),
              ),
              const SizedBox(width: 8),
              _FilterButton(
                icon: Icons.swap_vert_rounded,
                label: _sortLabel(sortMode),
                onTap: () => _showSortSheet(context),
              ),
              const SizedBox(width: 8),
              _FilterButton(
                icon: Icons.tune_rounded,
                label: incompleteOnly || selectedCategory != null
                    ? '筛选中'
                    : '筛选',
                selected: incompleteOnly || selectedCategory != null,
                onTap: () => _showFilterSheet(context),
              ),
            ],
          ),
          AnimatedSize(
            duration: motionDuration(
              context,
              const Duration(milliseconds: 220),
            ),
            curve: Curves.easeOutCubic,
            child: searchExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: '搜索标题或备注',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: '清空搜索',
                                onPressed: onClear,
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = index == 0 ? null : categories[index - 1];
                  final selected = selectedCategory == category;
                  return _CategoryChip(
                    label: category ?? '全部',
                    selected: selected,
                    onTap: () => onCategoryChanged(category),
                  );
                },
              ),
            ),
          ],
          if (hasFilters) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 17),
                label: const Text('清除筛选'),
                style: TextButton.styleFrom(foregroundColor: scheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _sortLabel(EventSortMode mode) => switch (mode) {
    EventSortMode.distance => '按距离',
    EventSortMode.targetDate => '按日期',
    EventSortMode.createdAt => '按创建',
  };

  Future<void> _showSortSheet(BuildContext context) async {
    final value = await showModalBottomSheet<EventSortMode>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChoiceSheet<EventSortMode>(
        title: '排序方式',
        value: sortMode,
        options: const [
          (EventSortMode.distance, '距离最近'),
          (EventSortMode.targetDate, '目标日期'),
          (EventSortMode.createdAt, '最近创建'),
        ],
      ),
    );
    if (value != null) onSortChanged(value);
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final value = await showModalBottomSheet<(bool, String?)>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        incompleteOnly: incompleteOnly,
        selectedCategory: selectedCategory,
        categories: categories,
      ),
    );
    if (value == null) return;
    onIncompleteChanged(value.$1);
    onCategoryChanged(value.$2);
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          // 按钮可能处于无界宽度约束下（Row 的非弹性子项），
          // IntrinsicWidth 保证内部 Row 的 Flexible 文本始终拿到有限宽度。
          child: IntrinsicWidth(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.34)
                      : scheme.outlineVariant.withValues(alpha: 0.50),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? scheme.primary : scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '分类：$label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: motionDuration(context, const Duration(milliseconds: 180)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.34)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.value,
    required this.options,
  });
  final String title;
  final T value;
  final List<(T, String)> options;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: GlassSurface(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GlassChoiceTile(
                  icon: Icons.sort_rounded,
                  title: option.$2,
                  value: '',
                  selected: option.$1 == value,
                  onTap: () => Navigator.pop(context, option.$1),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.incompleteOnly,
    required this.selectedCategory,
    required this.categories,
  });
  final bool incompleteOnly;
  final String? selectedCategory;
  final List<String> categories;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool incompleteOnly;
  late String? category;

  @override
  void initState() {
    super.initState();
    incompleteOnly = widget.incompleteOnly;
    category = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: GlassSurface(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('筛选事件', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GlassChoiceTile(
              icon: Icons.check_circle_outline_rounded,
              title: '未完成',
              value: incompleteOnly ? '仅显示' : '显示全部',
              selected: incompleteOnly,
              onTap: () => setState(() => incompleteOnly = !incompleteOnly),
            ),
            const SizedBox(height: 14),
            Text('分类', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CategoryChip(
                  label: '全部',
                  selected: category == null,
                  onTap: () => setState(() => category = null),
                ),
                for (final value in widget.categories)
                  _CategoryChip(
                    label: value,
                    selected: category == value,
                    onTap: () => setState(() => category = value),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, (incompleteOnly, category)),
                child: const Text('应用筛选'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
