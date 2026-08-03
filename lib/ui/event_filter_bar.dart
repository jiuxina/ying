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
    return GlassSurface(
      radius: 18,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 156),
                child: OutlinedButton.icon(
                  onPressed: onToggleSearch,
                  icon: const Icon(Icons.search_rounded),
                  label: Text(searchExpanded ? '收起搜索' : '搜索事件'),
                ),
              ),
              PopupMenuButton<EventSortMode>(
                tooltip: '排序方式',
                initialValue: sortMode,
                onSelected: onSortChanged,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: EventSortMode.distance,
                    child: Text('按距离排序'),
                  ),
                  PopupMenuItem(
                    value: EventSortMode.targetDate,
                    child: Text('按目标日期'),
                  ),
                  PopupMenuItem(
                    value: EventSortMode.createdAt,
                    child: Text('按创建时间'),
                  ),
                ],
                icon: const Icon(Icons.swap_vert_rounded),
              ),
              FilterChip(
                label: const Text('未完成'),
                selected: incompleteOnly,
                onSelected: onIncompleteChanged,
              ),
            ],
          ),
          if (searchExpanded) ...[
            const SizedBox(height: 10),
            TextField(
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
          ],
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: selectedCategory == null,
                    onSelected: (_) => onCategoryChanged(null),
                  ),
                  for (final category in categories)
                    ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) => onCategoryChanged(category),
                    ),
                  if (hasFilters)
                    ActionChip(
                      avatar: const Icon(
                        Icons.filter_alt_off_rounded,
                        size: 18,
                      ),
                      label: const Text('清除'),
                      onPressed: onClear,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
