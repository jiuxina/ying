import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/countdown_event.dart';
import '../models/category_model.dart';
import '../providers/events_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// 事件卡片组件
class EventCard extends StatefulWidget {
  final CountdownEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onTogglePin;
  final bool compact; // 紧凑模式

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.onTogglePin,
    this.compact = false,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;
    
    // 获取分类信息
    final provider = context.watch<EventsProvider>();
    final category = provider.getCategoryById(event.categoryId);
    final categoryColor = Color(category.color);
    
    final settings = context.watch<SettingsProvider>();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // 背景
                _buildBackground(categoryColor, settings),
                // 背景进度条（可选）
                if (settings.progressStyle == 'background' && !event.isCountUp)
                  _buildBackgroundProgress(settings, categoryColor),
                // 内容
                widget.compact
                    ? _buildCompactContent(theme, categoryColor, category)
                    : _buildContent(theme, categoryColor, category),
                // 置顶标记
                if (event.isPinned) _buildPinnedBadge(categoryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(Color categoryColor, SettingsProvider settings) {
    final event = widget.event;

    if (event.backgroundImage != null) {
      return Positioned.fill(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(event.backgroundImage!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientBackground(categoryColor),
            ),
            if (event.enableBlur)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withAlpha(30),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(20),
                    Colors.black.withAlpha(100),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildGradientBackground(categoryColor);
  }

  Widget _buildGradientBackground(Color categoryColor) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withAlpha(200),
              categoryColor.withAlpha(150),
            ],
          ),
        ),
      ),
    );
  }

  /// 背景进度条（占卡片宽度的百分比）
  Widget _buildBackgroundProgress(SettingsProvider settings, Color categoryColor) {
    final event = widget.event;
    final progress = _calculateProgress(event, settings);
    
    return Positioned.fill(
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              color: settings.progressColor.withAlpha(60),
            ),
          ),
        ),
      ),
    );
  }

  /// 根据设置计算进度
  /// 返回剩余时间百分比：1.0 表示时间充裕，0.0 表示已到期
  double _calculateProgress(CountdownEvent event, SettingsProvider settings) {
    if (event.isCountUp || event.daysRemaining < 0) return 0.0;
    
    int totalDays;
    switch (settings.progressCalculation) {
      case 'created':
        // 从创建时开始算（剩余进度，100%→0%）
        totalDays = event.targetDate.difference(event.createdAt).inDays;
        if (totalDays <= 0) return 0.0;
        return (event.daysRemaining / totalDays).clamp(0.0, 1.0);
      case 'fixed':
      default:
        // 按固定天数（剩余进度，100%→0%）
        totalDays = settings.progressFixedDays;
        if (totalDays <= 0) return 0.0;
        return (event.daysRemaining / totalDays).clamp(0.0, 1.0);
    }
  }

  /// 紧凑模式内容
  Widget _buildCompactContent(ThemeData theme, Color categoryColor, dynamic category) {
    final event = widget.event;
    final days = event.daysRemaining.abs();
    final isCountUp = event.isCountUp;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 分类图标
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          
          // 标题
          Expanded(
            child: Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 天数
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCountUp ? '+' : (event.daysRemaining >= 0 ? '' : '-'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' 天',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 完整内容
  Widget _buildContent(ThemeData theme, Color categoryColor, dynamic category) {
    final event = widget.event;
    final days = event.daysRemaining.abs();
    final isCountUp = event.isCountUp;
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final settings = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：分类和标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (widget.onTogglePin != null)
                GestureDetector(
                  onTap: widget.onTogglePin,
                  child: Icon(
                    event.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: Colors.white.withAlpha(180),
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 标题
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // 天数/详细日期显示
          if (settings.cardDisplayFormat == 'detailed')
            _buildDetailedDate(event, isCountUp)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isCountUp ? '已经' : (event.daysRemaining >= 0 ? '还有' : '已过'),
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '天',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // 标准进度条（非背景模式时显示）
          if (!isCountUp && settings.progressStyle == 'standard') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _calculateProgress(event, settings),
                backgroundColor: Colors.white.withAlpha(60),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_calculateProgress(event, settings) * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
                Text(
                  dateFormat.format(event.targetDate),
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          // 农历日期
          if (event.isLunar && event.lunarDateStr != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '农历 ${event.lunarDateStr}',
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 12,
                ),
              ),
            ),

          // 备注
          if (event.note != null && event.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                event.note!,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedDate(CountdownEvent event, bool isCountUp) {
    final now = DateTime.now();
    // Reset time to midnight for accurate date comparison
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(event.targetDate.year, event.targetDate.month, event.targetDate.day);
    
    int years = 0;
    int months = 0;
    int days = 0;

    DateTime tempDate;
    DateTime endDate;
    
    if (isCountUp) {
       tempDate = target;
       endDate = today;
    } else {
       tempDate = today;
       endDate = target;
    }

    if (endDate.isBefore(tempDate)) {
      final swap = tempDate;
      tempDate = endDate;
      endDate = swap;
    }

    // Calculate years
    while (DateTime(tempDate.year + 1, tempDate.month, tempDate.day).isBefore(endDate) || 
           DateTime(tempDate.year + 1, tempDate.month, tempDate.day).isAtSameMomentAs(endDate)) {
      years++;
      tempDate = DateTime(tempDate.year + 1, tempDate.month, tempDate.day);
    }

    // Calculate months
    while (DateTime(tempDate.year, tempDate.month + 1, tempDate.day).isBefore(endDate) || 
           DateTime(tempDate.year, tempDate.month + 1, tempDate.day).isAtSameMomentAs(endDate)) {
      months++;
      tempDate = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
    }
    
    // Calculate days
    days = endDate.difference(tempDate).inDays;

    final parts = <String>[];
    if (years > 0) parts.add('$years年');
    if (months > 0) parts.add('$months个月');
    if (days > 0 || parts.isEmpty) parts.add('$days天');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCountUp ? '已经' : (event.daysRemaining >= 0 ? '还有' : '已过'),
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          parts.join(' '),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedBadge(Color color) {
    return Positioned(
      top: 0,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(50),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.push_pin,
          size: 14,
          color: color,
        ),
      ),
    );
  }
}
