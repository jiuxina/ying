import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_memory.dart';
import 'memory_card.dart';

/// 时间线节点样式
enum TimelineStyle {
  /// 左侧线条样式
  leftLine,
  
  /// 中央交替样式
  alternating,
  
  /// 简洁样式
  minimal,
}

/// 记忆时间线组件
/// 
/// 按时间倒序展示事件的所有记忆，形成时间线回忆。
/// 
/// 特性：
/// - 多种时间线样式
/// - 按日期分组
/// - 支持筛选记忆类型
/// - 空状态展示
/// - 加载状态处理
/// 
/// 示例:
/// ```dart
/// MemoryTimeline(
///   memories: myMemories,
///   style: TimelineStyle.leftLine,
///   onDelete: (memory) => _handleDelete(memory),
/// )
/// ```
class MemoryTimeline extends StatelessWidget {
  /// 记忆列表（按时间倒序）
  final List<EventMemory> memories;
  
  /// 时间线样式
  final TimelineStyle style;
  
  /// 删除回调
  final void Function(EventMemory memory)? onDelete;
  
  /// 点击回调
  final void Function(EventMemory memory)? onTap;
  
  /// 图片点击回调
  final void Function(String imagePath, List<String> allImages)? onImageTap;
  
  /// 是否显示删除按钮
  final bool showDeleteButton;
  
  /// 是否显示日期分组头
  final bool showDateHeaders;
  
  /// 筛选的类型（null表示显示全部）
  final MemoryType? filterType;
  
  /// 空状态提示文本
  final String emptyText;
  
  /// 空状态图标
  final IconData emptyIcon;

  const MemoryTimeline({
    super.key,
    required this.memories,
    this.style = TimelineStyle.leftLine,
    this.onDelete,
    this.onTap,
    this.onImageTap,
    this.showDeleteButton = true,
    this.showDateHeaders = true,
    this.filterType,
    this.emptyText = '还没有任何记忆\n点击右下角按钮添加第一条记忆吧',
    this.emptyIcon = Icons.history,
  });

  /// 按日期分组记忆
  Map<String, List<EventMemory>> _groupByDate(List<EventMemory> memoryList) {
    final grouped = <String, List<EventMemory>>{};
    final dateFormat = DateFormat('yyyy年MM月dd日');
    
    for (final memory in memoryList) {
      final dateKey = dateFormat.format(memory.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(memory);
    }
    
    return grouped;
  }

  /// 根据类型筛选记忆
  List<EventMemory> _filterMemories(List<EventMemory> memoryList) {
    if (filterType == null) {
      return memoryList;
    }
    return memoryList.where((m) => m.type == filterType).toList();
  }

  /// 构建日期分组头
  Widget _buildDateHeader(BuildContext context, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(left: 12),
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建时间线节点
  Widget _buildTimelineNode(BuildContext context, bool isFirst, bool isLast) {
    return Column(
      children: [
        // 上方连接线
        Container(
          width: 2,
          height: isFirst ? 16 : 20,
          color: isFirst
              ? Colors.transparent
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        // 圆点
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 2,
            ),
          ),
        ),
        // 下方连接线
        Expanded(
          child: Container(
            width: 2,
            color: isLast
                ? Colors.transparent
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  /// 构建左侧线条样式的时间线
  Widget _buildLeftLineStyle(BuildContext context, List<EventMemory> filteredMemories) {
    if (showDateHeaders) {
      final grouped = _groupByDate(filteredMemories);
      
      return Column(
        children: grouped.entries.expand((entry) {
          final dateHeader = _buildDateHeader(context, entry.key);
          final memoryItems = entry.value.asMap().entries.map((e) {
            final index = e.key;
            final memory = e.value;
            
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 时间线节点
                  _buildTimelineNode(
                    context,
                    index == 0,
                    index == entry.value.length - 1,
                  ),
                  const SizedBox(width: 12),
                  // 记忆卡片
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MemoryCard(
                        memory: memory,
                        onDelete: onDelete,
                        onTap: onTap,
                        onImageTap: onImageTap,
                        showDeleteButton: showDeleteButton,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList();
          
          return [
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: dateHeader,
            ),
            ...memoryItems,
          ];
        }).toList(),
      );
    } else {
      return Column(
        children: filteredMemories.asMap().entries.map((e) {
          final index = e.key;
          final memory = e.value;
          
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTimelineNode(
                  context,
                  index == 0,
                  index == filteredMemories.length - 1,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MemoryCard(
                      memory: memory,
                      onDelete: onDelete,
                      onTap: onTap,
                      onImageTap: onImageTap,
                      showDeleteButton: showDeleteButton,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  /// 构建交替样式的时间线
  Widget _buildAlternatingStyle(BuildContext context, List<EventMemory> filteredMemories) {
    final grouped = _groupByDate(filteredMemories);
    
    return Column(
      children: grouped.entries.expand((entry) {
        final dateHeader = _buildDateHeader(context, entry.key);
        final memoryItems = entry.value.asMap().entries.map((e) {
          final index = e.key;
          final memory = e.value;
          final isLeft = index % 2 == 0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                if (isLeft) ...[
                  Expanded(
                    child: MemoryCard(
                      memory: memory,
                      onDelete: onDelete,
                      onTap: onTap,
                      onImageTap: onImageTap,
                      showDeleteButton: showDeleteButton,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                ] else ...[
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MemoryCard(
                      memory: memory,
                      onDelete: onDelete,
                      onTap: onTap,
                      onImageTap: onImageTap,
                      showDeleteButton: showDeleteButton,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList();
        
        return [
          dateHeader,
          ...memoryItems,
        ];
      }).toList(),
    );
  }

  /// 构建简洁样式的时间线
  Widget _buildMinimalStyle(BuildContext context, List<EventMemory> filteredMemories) {
    if (showDateHeaders) {
      final grouped = _groupByDate(filteredMemories);
      
      return Column(
        children: grouped.entries.expand((entry) {
          final dateHeader = _buildDateHeader(context, entry.key);
          final memoryItems = entry.value.map((memory) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MemoryCard(
                memory: memory,
                onDelete: onDelete,
                onTap: onTap,
                onImageTap: onImageTap,
                showDeleteButton: showDeleteButton,
                compact: true,
              ),
            );
          }).toList();
          
          return [dateHeader, ...memoryItems];
        }).toList(),
      );
    } else {
      return Column(
        children: filteredMemories.map((memory) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MemoryCard(
              memory: memory,
              onDelete: onDelete,
              onTap: onTap,
              onImageTap: onImageTap,
              showDeleteButton: showDeleteButton,
              compact: true,
            ),
          );
        }).toList(),
      );
    }
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              emptyText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 筛选记忆
    final filteredMemories = _filterMemories(memories);
    
    // 空状态
    if (filteredMemories.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // 根据样式构建时间线
    return switch (style) {
      TimelineStyle.leftLine => _buildLeftLineStyle(context, filteredMemories),
      TimelineStyle.alternating => _buildAlternatingStyle(context, filteredMemories),
      TimelineStyle.minimal => _buildMinimalStyle(context, filteredMemories),
    };
  }
}

/// 记忆时间线视图（带加载状态）
/// 
/// 封装了加载状态和刷新功能
class MemoryTimelineView extends StatefulWidget {
  /// 获取记忆的异步函数
  final Future<List<EventMemory>> Function() loadMemories;
  
  /// 时间线样式
  final TimelineStyle style;
  
  /// 删除回调
  final void Function(EventMemory memory)? onDelete;
  
  /// 点击回调
  final void Function(EventMemory memory)? onTap;
  
  /// 图片点击回调
  final void Function(String imagePath, List<String> allImages)? onImageTap;
  
  /// 是否显示删除按钮
  final bool showDeleteButton;
  
  /// 是否显示日期分组头
  final bool showDateHeaders;
  
  /// 筛选的类型
  final MemoryType? filterType;
  
  /// 空状态提示文本
  final String emptyText;
  
  /// 空状态图标
  final IconData emptyIcon;

  const MemoryTimelineView({
    super.key,
    required this.loadMemories,
    this.style = TimelineStyle.leftLine,
    this.onDelete,
    this.onTap,
    this.onImageTap,
    this.showDeleteButton = true,
    this.showDateHeaders = true,
    this.filterType,
    this.emptyText = '还没有任何记忆\n点击右下角按钮添加第一条记忆吧',
    this.emptyIcon = Icons.history,
  });

  @override
  State<MemoryTimelineView> createState() => _MemoryTimelineViewState();
}

class _MemoryTimelineViewState extends State<MemoryTimelineView> {
  List<EventMemory>? _memories;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final memories = await widget.loadMemories();
      if (mounted) {
        setState(() {
          _memories = memories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败: $_error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    return MemoryTimeline(
      memories: _memories ?? [],
      style: widget.style,
      onDelete: widget.onDelete,
      onTap: widget.onTap,
      onImageTap: widget.onImageTap,
      showDeleteButton: widget.showDeleteButton,
      showDateHeaders: widget.showDateHeaders,
      filterType: widget.filterType,
      emptyText: widget.emptyText,
      emptyIcon: widget.emptyIcon,
    );
  }
}
