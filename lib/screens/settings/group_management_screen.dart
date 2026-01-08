import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_group.dart';
import '../../providers/events_provider.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';
import '../../widgets/common/empty_state.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
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
                    final groups = provider.groups;
                    if (groups.isEmpty) {
                      return const EmptyState(
                        icon: Icons.folder_open,
                        title: '没有分组',
                        description: '点击右下角按钮添加分组',
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: group.color != null 
                                    ? Color(int.parse(group.color!, radix: 16)) 
                                    : Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  group.name.characters.first,
                                  style: TextStyle(
                                    color: group.color != null 
                                        ? Colors.white 
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              title: Text(group.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showAddEditDialog(context, group: group),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _confirmDelete(context, group),
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
            '分组管理',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {EventGroup? group}) {
    final nameController = TextEditingController(text: group?.name);
    // 简化的颜色选择逻辑，此处可扩展
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group == null ? '新建分组' : '编辑分组'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '分组名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              
              final provider = Provider.of<EventsProvider>(context, listen: false);
              if (group == null) {
                provider.addGroup(nameController.text.trim());
              } else {
                provider.updateGroup(group.copyWith(name: nameController.text.trim()));
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EventGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分组"${group.name}"吗？该分组下的事件将移出分组。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final provider = Provider.of<EventsProvider>(context, listen: false);
              provider.deleteGroup(group.id);
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
