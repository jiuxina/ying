import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/countdown_event.dart';
import '../providers/events_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/responsive_utils.dart';

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
        child: Hero(
          tag: 'event_card_${event.id}',
          flightShuttleBuilder: (
            BuildContext flightContext,
            Animation<double> animation,
            HeroFlightDirection flightDirection,
            BuildContext fromHeroContext,
            BuildContext toHeroContext,
          ) {
            return Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
                  color: categoryColor.withAlpha(180),
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withAlpha(30),
                  blurRadius: ResponsiveUtils.scaledSize(context, 20),
                  offset: Offset(0, ResponsiveUtils.scaledSpacing(context, 8)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.base(context), 
        vertical: ResponsiveSpacing.md(context),
      ),
      child: Row(
        children: [
          // 分类图标
          Container(
            padding: EdgeInsets.all(ResponsiveSpacing.sm(context)),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
            ),
            child: Text(
              category.icon,
              style: TextStyle(fontSize: ResponsiveFontSize.xl(context)),
            ),
          ),
          SizedBox(width: ResponsiveSpacing.md(context)),
          
          // 标题
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveFontSize.lg(context),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 天数
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSpacing.md(context), 
              vertical: ResponsiveSpacing.xs(context) + ResponsiveUtils.scaledSpacing(context, 2),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCountUp ? '+' : (event.daysRemaining >= 0 ? '' : '-'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveFontSize.base(context),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
                Text(
                  '$days',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveFontSize.xxl(context),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
                Text(
                  ' 天',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: ResponsiveFontSize.sm(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
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
      padding: EdgeInsets.all(ResponsiveSpacing.base(context) - ResponsiveUtils.scaledSpacing(context, 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：分类和标题
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSpacing.sm(context) + ResponsiveUtils.scaledSpacing(context, 2), 
                  vertical: ResponsiveSpacing.xs(context),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.icon,
                      style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                    SizedBox(width: ResponsiveSpacing.xs(context)),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveFontSize.sm(context),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    size: ResponsiveIconSize.md(context),
                  ),
                ),
            ],
          ),
          SizedBox(height: ResponsiveSpacing.sm(context) + ResponsiveUtils.scaledSpacing(context, 2)),

          // 标题
          Text(
            event.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveFontSize.lg(context) + ResponsiveUtils.scaledFontSize(context, 1),
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ResponsiveSpacing.xs(context) + ResponsiveUtils.scaledSpacing(context, 2)),

          // 天数/详细日期显示
          if (settings.cardDisplayFormat == 'detailed')
            _buildDetailedDate(event, isCountUp)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    isCountUp ? '已经' : (event.daysRemaining >= 0 ? '还有' : '已过'),
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: ResponsiveFontSize.base(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                SizedBox(width: ResponsiveSpacing.sm(context)),
                Flexible(
                  child: Text(
                    '$days',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveFontSize.hero(context),
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
                SizedBox(width: ResponsiveSpacing.xs(context)),
                Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveSpacing.sm(context)),
                  child: Text(
                    '天',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: ResponsiveFontSize.lg(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          SizedBox(height: ResponsiveSpacing.md(context)),

          // 标准进度条（非背景模式时显示）
          if (!isCountUp && settings.progressStyle == 'standard') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xs(context)),
              child: LinearProgressIndicator(
                value: _calculateProgress(event, settings),
                backgroundColor: Colors.white.withAlpha(60),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: ResponsiveUtils.scaledSize(context, 6),
              ),
            ),
            SizedBox(height: ResponsiveSpacing.sm(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${(_calculateProgress(event, settings) * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: ResponsiveFontSize.sm(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    dateFormat.format(event.targetDate),
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: ResponsiveFontSize.sm(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // 农历日期
          if (event.isLunar && event.lunarDateStr != null)
            Padding(
              padding: EdgeInsets.only(top: ResponsiveSpacing.xs(context)),
              child: Text(
                '农历 ${event.lunarDateStr}',
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: ResponsiveFontSize.sm(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // 备注
          if (event.note != null && event.note!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: ResponsiveSpacing.sm(context)),
              child: Text(
                event.note!,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: ResponsiveFontSize.md(context),
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
            fontSize: ResponsiveFontSize.sm(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: ResponsiveSpacing.xs(context)),
        Text(
          parts.join(' '),
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveFontSize.title(context),
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPinnedBadge(Color color) {
    return Positioned(
      top: 0,
      right: ResponsiveSpacing.lg(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSpacing.sm(context), 
          vertical: ResponsiveSpacing.xs(context),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(ResponsiveBorderRadius.sm(context)),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(50),
              blurRadius: ResponsiveUtils.scaledSize(context, 8),
              offset: Offset(0, ResponsiveUtils.scaledSpacing(context, 2)),
            ),
          ],
        ),
        child: Icon(
          Icons.push_pin,
          size: ResponsiveIconSize.xs(context) + ResponsiveUtils.scaledSize(context, 2),
          color: color,
        ),
      ),
    );
  }
}
