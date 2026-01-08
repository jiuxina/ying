import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/countdown_event.dart';
import '../providers/events_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/ui_helpers.dart';

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

  @override
  Widget build(BuildContext context) {
    context.watch<EventsProvider>();
    _refreshEvent();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildCountdownCard(context, categoryColor),
                          const SizedBox(height: 20),
                          _buildInfoCard(context),
                          const SizedBox(height: 20),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          // 邀请按钮
          GlassIconButton(
            icon: Icons.person_add,
            onPressed: () {
              showInviteShareSheet(context, _event);
            },
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Icons.share,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ShareCardDialog(event: _event),
              );
            },
          ),
          const SizedBox(width: 8),
          if (_event.daysRemaining == 0) ...[
             GlassIconButton(
              icon: Icons.celebration,
              onPressed: () => _showCelebration(),
            ),
            const SizedBox(width: 8),
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
    final isPast = diff.isNegative;
    final absDiff = diff.abs();
    final hours = absDiff.inHours % 24;
    final minutes = absDiff.inMinutes % 60;
    final seconds = absDiff.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor,
            categoryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (_event.backgroundImage != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  File(_event.backgroundImage!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                isCountUp ? '已经' : (days >= 0 ? '还有' : '已过'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (_event.daysRemaining == 0) ...[
                const Text(
                  '今天',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ] else ...[
                 Text(
                  '$days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(
                  '天',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 20,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Real-time HH:MM:SS display
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
              ),

              if (!isCountUp && _event.daysRemaining > 0) ...[
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _event.progressPercentage,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_event.progressPercentage * 100).toInt()}% 已过',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
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
            title: const Text('目标日期'),
            subtitle: Text(dateFormat.format(_event.targetDate)),
          ),
          if (_event.isLunar && _event.lunarDateStr != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const IconBox(icon: Icons.auto_awesome, color: Colors.purple),
              title: const Text('农历日期'),
              subtitle: Text(_event.lunarDateStr!),
            ),
          ],
          if (_event.isRepeating) ...[
            const Divider(height: 1),
            ListTile(
              leading: const IconBox(icon: Icons.repeat, color: Colors.green),
              title: const Text('重复'),
              subtitle: const Text('每年重复'),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: IconBox(
              icon: _event.enableNotification ? Icons.notifications_active : Icons.notifications_off,
              color: _event.enableNotification ? Colors.orange : Colors.grey,
            ),
            title: const Text('通知提醒'),
            subtitle: Text(
              _event.enableNotification
                  ? '提前 ${_event.notifyDaysBefore} 天，${_event.notifyHour.toString().padLeft(2, '0')}:${_event.notifyMinute.toString().padLeft(2, '0')} 提醒'
                  : '已关闭',
            ),
          ),
          if (_event.note != null && _event.note!.isNotEmpty) ...[
            const Divider(height: 1),
            ListTile(
              leading: const IconBox(icon: Icons.notes, color: Colors.teal),
              title: const Text('备注'),
              subtitle: Text(_event.note!),
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
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<EventsProvider>().togglePin(_event.id);
              Navigator.pop(context);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.archive,
            label: '归档',
            color: Colors.blue,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<EventsProvider>().toggleArchive(_event.id);
              Navigator.pop(context);
            },
          ),
        ),
        const SizedBox(width: 12),
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认删除'),
        content: Text('确定要删除"${_event.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<EventsProvider>().deleteEvent(_event.id);
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
