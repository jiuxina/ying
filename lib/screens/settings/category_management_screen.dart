import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:flutter/services.dart';

import '../../models/category_model.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';
import '../../widgets/common/empty_state.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final List<String> _emojiOptions = [
    '📌', '🎂', '💑', '🎉', '📚', '💼', '✈️', '🏋️', '💊', '💰',
    '🏠', '🚗', '🎮', '🎬', '🎵', '🍔', '🍺', '🛍️', '💡', '❤️'
  ];

  final List<Color> _colorOptions = [
    Colors.pink, Colors.red, Colors.deepOrange, Colors.orange,
    Colors.amber, Colors.yellow, Colors.lime, Colors.lightGreen,
    Colors.green, Colors.teal, Colors.cyan, Colors.lightBlue,
    Colors.blue, Colors.indigo, Colors.purple, Colors.deepPurple,
    Colors.blueGrey, Colors.brown, Colors.grey, Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Consumer<EventsProvider>(
                  builder: (context, provider, child) {
                    final categories = provider.categories;
                    if (categories.isEmpty) {
                      return const EmptyState(
                        icon: Icons.category,
                        title: '没有分类',
                        description: '这不应该发生...',
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(category.color),
                                child: Text(category.icon),
                              ),
                              title: Text(category.name),
                              subtitle: category.isDefault 
                                  ? const Text('系统默认', style: TextStyle(fontSize: 12)) 
                                  : null,
                              trailing: category.isDefault 
                                  ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () => _showAddEditDialog(context, category: category),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20),
                                          onPressed: () => _confirmDelete(context, category),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            '分类管理',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Category? category}) {
    final nameController = TextEditingController(text: category?.name);
    String selectedIcon = category?.icon ?? _emojiOptions[0];
    Color selectedColor = category?.color != null 
        ? Color(category!.color) 
        : _colorOptions[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                category == null ? '新建分类' : '编辑分类',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '分类名称',
                  border: OutlineInputBorder(),
                ),
                autofocus: category == null,
              ),
              const SizedBox(height: 16),
              const Text('选择图标', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojiOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final icon = _emojiOptions[index];
                    final isSelected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(icon, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('选择颜色', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colorOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final color = _colorOptions[index];
                    final isSelected = selectedColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: isSelected ? [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
                          ] : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  
                  final provider = Provider.of<EventsProvider>(context, listen: false);
                  if (category == null) {
                    final newCategory = Category(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      icon: selectedIcon,
                      color: selectedColor.toARGB32(),
                    );
                    provider.addCategory(newCategory);
                  } else {
                    provider.updateCategory(category.copyWith(
                      name: nameController.text.trim(),
                      icon: selectedIcon,
                      color: selectedColor.toARGB32(),
                    ));
                  }
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    if (category.isDefault) return; // Should not happen due to UI check

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${category.name}"吗？该分类下的事件将被移至"其他"分类。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final provider = Provider.of<EventsProvider>(context, listen: false);
              provider.deleteCategory(category.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
