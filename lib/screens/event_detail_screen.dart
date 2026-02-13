import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/countdown_event.dart';
import '../providers/events_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/animations/counting_animation.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/ui_helpers.dart';
import '../utils/responsive_utils.dart';

import 'add_edit_event_screen.dart';
import '../widgets/share_card_dialog.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/invite_share_sheet.dart';

class EventDetailScreen extends StatefulWidget {
  final CountdownEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late CountdownEvent _event;
  late ConfettiController _confettiController;
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _hasShownCelebration = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Check if celebration is needed (D-Day or milestone)
    if (_event.daysRemaining == 0 && !_hasShownCelebration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCelebration();
      });
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _refreshEvent() {
    final provider = context.read<EventsProvider>();
    final updated = provider.events.firstWhere(
      (e) => e.id == _event.id,
      orElse: () => _event,
    );
    if (mounted && updated != _event) {
      setState(() => _event = updated);
    }
  }

  void _showCelebration() {
    if (_hasShownCelebration) return;
    setState(() => _hasShownCelebration = true);
    
    showCelebrationOverlay(
      context,
      event: _event,
      onShare: () {
        // 打开分享对话框
        showDialog(
          context: context,
          builder: (context) => ShareCardDialog(event: _event),
        );
      },
      onDismiss: () {
        // 仍然播放彩纸效果
        _confettiController.play();
      },
    );
  }

  /// 根据设置计算进度（与主页一致）
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

  @override
  Widget build(BuildContext context) {
    context.watch<EventsProvider>();
    _refreshEvent();

    // final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 获取分类
    final provider = context.watch<EventsProvider>();
    final category = provider.getCategoryById(_event.categoryId);
    final categoryColor = Color(category.color);

    return Scaffold(
      body: Stack(
        children: [
          AppBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(ResponsiveSpacing.lg(context)),
                      child: Column(
                        children: [
                          _buildCountdownCard(context, categoryColor),
                          SizedBox(height: ResponsiveSpacing.lg(context)),
                          _buildInfoCard(context),
                          SizedBox(height: ResponsiveSpacing.lg(context)),
                          _buildActions(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveSpacing.sm(context),
        ResponsiveSpacing.sm(context),
        ResponsiveSpacing.base(context),
        ResponsiveSpacing.sm(context),
      ),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: ResponsiveSpacing.sm(context)),
          const Spacer(),
          // 邀请按钮
          GlassIconButton(
            icon: Icons.person_add,
            onPressed: () {
              showInviteShareSheet(context, _event);
            },
          ),
          SizedBox(width: ResponsiveSpacing.sm(context)),
          GlassIconButton(
            icon: Icons.share,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ShareCardDialog(event: _event),
              );
            },
          ),
          SizedBox(width: ResponsiveSpacing.sm(context)),
          if (_event.daysRemaining == 0) ...[
             GlassIconButton(
              icon: Icons.celebration,
              onPressed: () => _showCelebration(),
            ),
            SizedBox(width: ResponsiveSpacing.sm(context)),
          ],
          GlassIconButton(
            icon: Icons.edit,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditEventScreen(event: widget.event),
                ),
              );
              _refreshEvent();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard(BuildContext context, Color categoryColor) {
    // 获取分类
    final provider = context.read<EventsProvider>();
    final category = provider.getCategoryById(_event.categoryId);
    
    final days = _event.daysRemaining.abs();
    final isCountUp = _event.isCountUp;
    
    // Calculate precise time difference
    final diff = _event.targetDate.difference(_now);
    final absDiff = diff.abs();
    final hours = absDiff.inHours % 24;
    final minutes = absDiff.inMinutes % 60;
    final seconds = absDiff.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveSpacing.xxl(context)),
      decoration: BoxDecoration(
        gradient: _event.backgroundImage == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor,
                  categoryColor.withValues(alpha: 0.7),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xl(context)),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.3),
            blurRadius: ResponsiveSpacing.lg(context),
            offset: Offset(0, ResponsiveSpacing.sm(context)),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (_event.backgroundImage != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xl(context)),
                child: Image.file(
                  File(_event.backgroundImage!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          if (_event.backgroundImage != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xl(context)),
                ),
              ),
            ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSpacing.base(context),
                  vertical: ResponsiveSpacing.sm(context),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.icon,
                      style: TextStyle(fontSize: ResponsiveFontSize.xl(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: ResponsiveSpacing.sm(context)),
                    Flexible(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveFontSize.base(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveSpacing.xl(context)),
              Text(
                _event.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveFontSize.heading(context),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveSpacing.xxl(context)),
              Text(
                isCountUp ? '已经' : (days >= 0 ? '还有' : '已过'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: ResponsiveFontSize.lg(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveSpacing.sm(context)),
              if (_event.daysRemaining == 0) ...[
                // Show only time for D-Day
                Text(
                  '今天',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.scaledFontSize(context, 72.0),
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveSpacing.base(context)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSpacing.md(context),
                    vertical: ResponsiveSpacing.xs(context) * 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
                  ),
                  child: Text(
                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: ResponsiveFontSize.lg(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                // Show square container with days number
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveUtils.scaledSize(context, 150),
                      maxHeight: ResponsiveUtils.scaledSize(context, 150),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedNumber(
                          value: days,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.scaledFontSize(context, 48.0),
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          duration: const Duration(milliseconds: 800),
                        ),
                        Text(
                          '天',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: ResponsiveFontSize.lg(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSpacing.base(context)),
                // Show combined detailed time
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSpacing.md(context),
                    vertical: ResponsiveSpacing.xs(context) * 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
                  ),
                  child: Text(
                    '$days天 ${hours.toString().padLeft(2, '0')}时 ${minutes.toString().padLeft(2, '0')}分 ${seconds.toString().padLeft(2, '0')}秒',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveFontSize.base(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              if (!isCountUp && _event.daysRemaining > 0) ...[
                SizedBox(height: ResponsiveSpacing.xxl(context)),
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    final progress = _calculateProgress(_event, settings);
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xs(context)),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: ResponsiveSpacing.sm(context),
                          ),
                        ),
                        SizedBox(height: ResponsiveSpacing.sm(context)),
                        Text(
                          '${(progress * 100).toInt()}% 剩余',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: ResponsiveFontSize.base(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ... (rest of the file: _buildInfoCard, _buildActions, _buildActionButton, _confirmDelete)


  Widget _buildInfoCard(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN');

    return GlassCard(
      child: Column(
        children: [
          ListTile(
            leading: const IconBox(icon: Icons.calendar_today, color: Colors.blue),
            title: Text(
              '目标日期',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              dateFormat.format(_event.targetDate),
              style: TextStyle(fontSize: ResponsiveFontSize.sm(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_event.isLunar && _event.lunarDateStr != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const IconBox(icon: Icons.auto_awesome, color: Colors.purple),
              title: Text(
                '农历日期',
                style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _event.lunarDateStr!,
                style: TextStyle(fontSize: ResponsiveFontSize.sm(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (_event.isRepeating) ...[
            const Divider(height: 1),
            ListTile(
              leading: const IconBox(icon: Icons.repeat, color: Colors.green),
              title: Text(
                '重复',
                style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '每年重复',
                style: TextStyle(fontSize: ResponsiveFontSize.sm(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: IconBox(
              icon: _event.enableNotification ? Icons.notifications_active : Icons.notifications_off,
              color: _event.enableNotification ? Colors.orange : Colors.grey,
            ),
            title: Text(
              '通知提醒',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _event.enableNotification
                  ? '提前 ${_event.notifyDaysBefore} 天，${_event.notifyHour.toString().padLeft(2, '0')}:${_event.notifyMinute.toString().padLeft(2, '0')} 提醒'
                  : '已关闭',
              style: TextStyle(fontSize: ResponsiveFontSize.sm(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_event.note != null && _event.note!.isNotEmpty) ...[
            const Divider(height: 1),
            ListTile(
              leading: const IconBox(icon: Icons.notes, color: Colors.teal),
              title: Text(
                '备注',
                style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _event.note!,
                style: TextStyle(fontSize: ResponsiveFontSize.sm(context)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: _event.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: _event.isPinned ? '取消置顶' : '置顶',
            color: Colors.orange,
            onTap: () => _confirmPin(context),
          ),
        ),
        SizedBox(width: ResponsiveSpacing.md(context)),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.archive,
            label: '归档',
            color: Colors.blue,
            onTap: () => _confirmArchive(context),
          ),
        ),
        SizedBox(width: ResponsiveSpacing.md(context)),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.delete,
            label: '删除',
            color: Colors.red,
            onTap: () => _confirmDelete(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: ResponsiveSpacing.base(context)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context)),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: ResponsiveIconSize.base(context),
              ),
              SizedBox(height: ResponsiveSpacing.xs(context)),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveFontSize.sm(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
        ),
        title: Text(
          '确认删除',
          style: TextStyle(fontSize: ResponsiveFontSize.lg(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          '确定要删除"${_event.title}"吗？',
          style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<EventsProvider>().deleteEvent(_event.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              '删除',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPin(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
        ),
        title: Text(
          _event.isPinned ? '取消置顶' : '置顶事件',
          style: TextStyle(fontSize: ResponsiveFontSize.lg(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          _event.isPinned
              ? '确定要取消置顶"${_event.title}"吗？'
              : '确定要置顶"${_event.title}"吗？置顶的事件将显示在列表顶部。',
          style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<EventsProvider>().togglePin(_event.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _event.isPinned ? '已取消置顶' : '已置顶',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              '确定',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
        ),
        title: Text(
          '归档事件',
          style: TextStyle(fontSize: ResponsiveFontSize.lg(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          '确定要归档"${_event.title}"吗？归档后可在归档页面查看。',
          style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<EventsProvider>().toggleArchive(_event.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '已归档',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(
              '归档',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
