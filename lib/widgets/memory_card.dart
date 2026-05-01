import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_memory.dart';

/// 记忆卡片组件
/// 
/// 用于在时间线和列表中显示单个记忆项。
/// 支持显示照片、故事、备注三种类型的记忆。
/// 
/// 特性：
/// - 照片网格展示（支持多图）
/// - 文字内容展示
/// - 时间戳显示
/// - 删除确认对话框
/// - 点击查看大图
/// 
/// 示例:
/// ```dart
/// MemoryCard(
///   memory: myMemory,
///   onDelete: (memory) => _handleDelete(memory),
///   onTap: (memory) => _handleTap(memory),
/// )
/// ```
class MemoryCard extends StatefulWidget {
  /// 记忆数据
  final EventMemory memory;
  
  /// 删除回调
  final void Function(EventMemory memory)? onDelete;
  
  /// 点击回调
  final void Function(EventMemory memory)? onTap;
  
  /// 图片点击回调（传递图片路径和图片列表）
  final void Function(String imagePath, List<String> allImages)? onImageTap;
  
  /// 是否显示删除按钮
  final bool showDeleteButton;
  
  /// 是否紧凑模式
  final bool compact;

  const MemoryCard({
    super.key,
    required this.memory,
    this.onDelete,
    this.onTap,
    this.onImageTap,
    this.showDeleteButton = true,
    this.compact = false,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> {
  /// 日期格式化器
  static final DateFormat _dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
  
  /// 简短日期格式化器
  static final DateFormat _shortDateFormat = DateFormat('MM月dd日 HH:mm');
  
  /// 图片加载状态
  final Map<String, bool> _imageLoadStates = {};

  @override
  void dispose() {
    // 清理图片缓存状态
    _imageLoadStates.clear();
    super.dispose();
  }

  /// 显示删除确认对话框
  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记忆'),
        content: Text(
          '确定要删除这条记忆吗？${widget.memory.hasImages ? '\n关联的图片也会被删除。' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 处理删除操作
  Future<void> _handleDelete() async {
    if (await _showDeleteConfirmation()) {
      widget.onDelete?.call(widget.memory);
    }
  }

  /// 处理图片点击
  void _handleImageTap(String imagePath) {
    if (widget.onImageTap != null) {
      widget.onImageTap!(imagePath, widget.memory.imagePaths);
    } else {
      // 默认行为：显示全屏图片查看器
      _showImagePreview(imagePath);
    }
  }

  /// 显示图片预览
  void _showImagePreview(String initialPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImagePreviewScreen(
          images: widget.memory.imagePaths,
          initialIndex: widget.memory.imagePaths.indexOf(initialPath),
        ),
      ),
    );
  }

  /// 构建类型图标
  Widget _buildTypeIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (widget.memory.type) {
      case MemoryType.photo:
        iconData = Icons.photo_library;
        iconColor = Colors.blue;
        break;
      case MemoryType.story:
        iconData = Icons.auto_stories;
        iconColor = Colors.orange;
        break;
      case MemoryType.note:
        iconData = Icons.note;
        iconColor = Colors.green;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, size: 16, color: iconColor),
    );
  }

  /// 构建时间戳
  Widget _buildTimestamp() {
    final dateFormat = widget.compact ? _shortDateFormat : _dateFormat;
    return Text(
      dateFormat.format(widget.memory.createdAt),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    if (!widget.memory.hasContent) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        widget.memory.content!,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: widget.compact ? 2 : 5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 构建单张图片
  Widget _buildSingleImage(String imagePath) {
    return GestureDetector(
      onTap: () => _handleImageTap(imagePath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Hero(
          tag: 'memory_image_$imagePath',
          child: Image.file(
            File(imagePath),
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              );
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: frame != null
                    ? child
                    : Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建多张图片网格
  Widget _buildImageGrid() {
    final images = widget.memory.imagePaths;
    
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 单张图片
    if (images.length == 1) {
      return _buildSingleImage(images[0]);
    }
    
    // 多张图片网格
    final displayImages = images.length > 4 ? images.sublist(0, 4) : images;
    final remainingCount = images.length - 4;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: displayImages.length,
      itemBuilder: (context, index) {
        final imagePath = displayImages[index];
        final isLastItem = index == 3 && remainingCount > 0;
        
        return GestureDetector(
          onTap: () => _handleImageTap(imagePath),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: 'memory_image_$imagePath',
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: frame != null
                            ? child
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
              // 显示剩余图片数量
              if (isLastItem)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 16,
        vertical: 8,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: widget.onTap != null ? () => widget.onTap!(widget.memory) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(widget.compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：类型图标、时间戳、删除按钮
              Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTimestamp()),
                  if (widget.showDeleteButton && widget.onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: _handleDelete,
                      tooltip: '删除',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              
              // 图片区域
              if (widget.memory.hasImages) ...[
                const SizedBox(height: 12),
                _buildImageGrid(),
              ],
              
              // 文字内容
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 图片预览屏幕
class _ImagePreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImagePreviewScreen({
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: 'memory_image_${widget.images[index]}',
                child: Image.file(
                  File(widget.images[index]),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
