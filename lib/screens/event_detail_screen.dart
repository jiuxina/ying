import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/countdown_event.dart';
import '../models/event_memory.dart';
import '../providers/events_provider.dart';
import '../providers/settings_provider.dart';
import '../services/memory_service.dart';
import '../widgets/animations/counting_animation.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/ui_helpers.dart';
import '../widgets/memory_card.dart';
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

class _EventDetailScreenState extends State<EventDetailScreen> with TickerProviderStateMixin {
  late CountdownEvent _event;
  late ConfettiController _confettiController;
  late TabController _tabController;
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _hasShownCelebration = false;
  
  // Memory service
  final MemoryService _memoryService = MemoryService();
  List<EventMemory> _memories = [];
  bool _isLoadingMemories = true;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _tabController = TabController(length: 2, vsync: this);
    
    // Check if celebration is needed (D-Day or milestone)
    if (_event.daysRemaining == 0 && !_hasShownCelebration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCelebration();
      });
    }

    _startTimer();
    _loadMemories();
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
    _tabController.dispose();
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

  /// 加载记忆数据
  Future<void> _loadMemories() async {
    setState(() => _isLoadingMemories = true);
    try {
      final memories = await _memoryService.getMemories(_event.id);
      if (mounted) {
        setState(() {
          _memories = memories;
          _isLoadingMemories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMemories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载记忆失败: $e')),
        );
      }
    }
  }

  /// 添加新记忆
  Future<void> _addMemory() async {
    final result = await showModalBottomSheet<MemoryAddResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemoryAddSheet(
        eventId: _event.id,
        eventTitle: _event.title,
      ),
    );

    if (result != null && mounted) {
      await _loadMemories();
    }
  }

  /// 删除记忆
  Future<void> _deleteMemory(EventMemory memory) async {
    try {
      await _memoryService.deleteMemory(memory.id);
      await _loadMemories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除记忆')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 格式化时间组件为两位数字
  String _formatTimeComponent(int value) {
    return value.toString().padLeft(2, '0');
  }

  /// 格式化完整时间字符串 HH:MM:SS
  String _formatTimeHMS(int hours, int minutes, int seconds) {
    return '${_formatTimeComponent(hours)}:${_formatTimeComponent(minutes)}:${_formatTimeComponent(seconds)}';
  }

  /// 格式化详细时间字符串: D天 HH时 MM分 SS秒 (天数不补零，时分秒补零)
  /// 注意：天数会减1，因为如果明天是目标日期，剩余时间不足一天，只是若干小时
  String _formatDetailedTime(int days, int hours, int minutes, int seconds) {
    // 如果有完整天数，减1后显示，因为剩余的时间不足整天
    final adjustedDays = days > 0 ? days - 1 : 0;
    if (adjustedDays > 0) {
      return '$adjustedDays天 ${_formatTimeComponent(hours)}时 ${_formatTimeComponent(minutes)}分 ${_formatTimeComponent(seconds)}秒';
    } else {
      // 不足1天时，只显示时分秒
      return '${_formatTimeComponent(hours)}时 ${_formatTimeComponent(minutes)}分 ${_formatTimeComponent(seconds)}秒';
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
                  _buildTabBar(context),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(context, categoryColor),
                        _buildAlbumTab(context),
                      ],
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

  /// 构建标签栏
  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.lg(context),
        vertical: ResponsiveSpacing.sm(context),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context)),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveFontSize.base(context),
        ),
        tabs: const [
          Tab(text: '信息'),
          Tab(text: '相册'),
        ],
      ),
    );
  }

  /// 构建信息标签页
  Widget _buildInfoTab(BuildContext context, Color categoryColor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveSpacing.lg(context)),
      child: Column(
        children: [
          _buildCountdownCard(context, categoryColor),
          SizedBox(height: ResponsiveSpacing.lg(context)),
          _buildDetailedTimeInfo(context),
          SizedBox(height: ResponsiveSpacing.md(context)),
          _buildProgressInfo(context),
          SizedBox(height: ResponsiveSpacing.lg(context)),
          _buildInfoCard(context),
          SizedBox(height: ResponsiveSpacing.lg(context)),
          _buildActions(context),
        ],
      ),
    );
  }

  /// 构建相册标签页
  Widget _buildAlbumTab(BuildContext context) {
    if (_isLoadingMemories) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_memories.isEmpty) {
      return _buildEmptyAlbum(context);
    }

    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.only(
            left: ResponsiveSpacing.sm(context),
            right: ResponsiveSpacing.sm(context),
            top: ResponsiveSpacing.md(context),
            bottom: 100, // Space for FAB
          ),
          itemCount: _memories.length,
          itemBuilder: (context, index) {
            final memory = _memories[index];
            return MemoryCard(
              memory: memory,
              onDelete: _deleteMemory,
              compact: true,
            );
          },
        ),
        // 添加记忆的FAB
        Positioned(
          right: ResponsiveSpacing.lg(context),
          bottom: ResponsiveSpacing.lg(context),
          child: FloatingActionButton.extended(
            onPressed: _addMemory,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('添加记忆'),
          ),
        ),
      ],
    );
  }

  /// 构建空相册状态
  Widget _buildEmptyAlbum(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_album_outlined,
              size: ResponsiveUtils.scaledSize(context, 80),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: ResponsiveSpacing.lg(context)),
            Text(
              '还没有任何记忆',
              style: TextStyle(
                fontSize: ResponsiveFontSize.lg(context),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveSpacing.sm(context)),
            Text(
              '记录这个重要时刻的照片和故事',
              style: TextStyle(
                fontSize: ResponsiveFontSize.base(context),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveSpacing.xl(context)),
            FilledButton.icon(
              onPressed: _addMemory,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('添加第一张照片'),
            ),
          ],
        ),
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

    return Center(
      child: AspectRatio(
        aspectRatio: 1.0, // 正方形卡片
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.scaledSize(context, 400),
            maxHeight: ResponsiveUtils.scaledSize(context, 400),
          ),
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
                blurRadius: ResponsiveSpacing.xl(context),
                offset: Offset(0, ResponsiveSpacing.md(context)),
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
              Padding(
                padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 分类标签
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveSpacing.md(context),
                        vertical: ResponsiveSpacing.xs(context),
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
                            style: TextStyle(fontSize: ResponsiveFontSize.lg(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: ResponsiveSpacing.xs(context)),
                          Flexible(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveFontSize.sm(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ResponsiveSpacing.lg(context)),
                    
                    // 事件标题
                    Text(
                      _event.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveFontSize.xxl(context),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // 倒计时主体
                    if (_event.daysRemaining == 0) ...[
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
                    ] else ...[
                      Text(
                        isCountUp ? '已经' : (days >= 0 ? '还有' : '已过'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: ResponsiveFontSize.lg(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveSpacing.xs(context)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedNumber(
                            value: days,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.scaledFontSize(context, 96.0),
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            duration: const Duration(milliseconds: 800),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: ResponsiveSpacing.sm(context)),
                            child: Text(
                              '天',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: ResponsiveFontSize.xxl(context),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建卡片下方的详细时间信息
  Widget _buildDetailedTimeInfo(BuildContext context) {
    final days = _event.daysRemaining.abs();
    
    // Calculate precise time difference
    final diff = _event.targetDate.difference(_now);
    final absDiff = diff.abs();
    final hours = absDiff.inHours % 24;
    final minutes = absDiff.inMinutes % 60;
    final seconds = absDiff.inSeconds % 60;

    if (_event.daysRemaining == 0) {
      // D-Day: 只显示时分秒
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.scaledSize(context, 400),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSpacing.lg(context),
            vertical: ResponsiveSpacing.md(context),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
          ),
          child: Text(
            _formatTimeHMS(hours, minutes, seconds),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: ResponsiveFontSize.xl(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.scaledSize(context, 400),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSpacing.lg(context),
          vertical: ResponsiveSpacing.md(context),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
        ),
        child: Column(
          children: [
            Text(
              '精确倒计时',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: ResponsiveFontSize.sm(context),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveSpacing.xs(context)),
            Text(
              _formatDetailedTime(days, hours, minutes, seconds),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveFontSize.lg(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建进度条信息
  Widget _buildProgressInfo(BuildContext context) {
    final isCountUp = _event.isCountUp;
    
    if (isCountUp || _event.daysRemaining <= 0) {
      return const SizedBox.shrink();
    }

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final progress = _calculateProgress(_event, settings);
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.scaledSize(context, 400),
            ),
            padding: EdgeInsets.all(ResponsiveSpacing.md(context)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '进度',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: ResponsiveFontSize.sm(context),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${(progress * 100).toInt()}% 剩余',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: ResponsiveFontSize.sm(context),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveSpacing.sm(context)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xs(context)),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    minHeight: ResponsiveSpacing.sm(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ... (rest of the file: _buildInfoCard, _buildActions, _buildActionButton, _confirmDelete)


  Widget _buildInfoCard(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN');

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.scaledSize(context, 400),
        ),
        child: GlassCard(
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
        ),
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

/// 添加记忆的结果
class MemoryAddResult {
  final bool success;
  
  const MemoryAddResult({required this.success});
}

/// 添加记忆的底部表单
class MemoryAddSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const MemoryAddSheet({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<MemoryAddSheet> createState() => _MemoryAddSheetState();
}

class _MemoryAddSheetState extends State<MemoryAddSheet> {
  final MemoryService _memoryService = MemoryService();
  final TextEditingController _contentController = TextEditingController();
  
  int _selectedTab = 0; // 0: 照片, 1: 故事, 2: 备注
  List<String> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final image = await _memoryService.takePhoto();
    if (image != null && mounted) {
      setState(() {
        _selectedImages = [image.path];
        _selectedTab = 0; // Switch to photo tab
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final images = await _memoryService.pickMultipleImages(maxImages: 9);
    if (images.isNotEmpty && mounted) {
      setState(() {
        _selectedImages = images.map((e) => e.path).toList();
        _selectedTab = 0; // Switch to photo tab
      });
    }
  }

  Future<void> _save() async {
    if (_selectedTab == 0 && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一张照片')),
      );
      return;
    }

    if (_selectedTab != 0 && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedTab == 0) {
        // 照片记忆
        final xFiles = _selectedImages.map((path) => XFile(path)).toList();
        await _memoryService.addPhotoMemory(
          eventId: widget.eventId,
          imageFiles: xFiles,
          content: _contentController.text.trim().isNotEmpty 
              ? _contentController.text.trim() 
              : null,
        );
      } else if (_selectedTab == 1) {
        // 故事记忆
        await _memoryService.addStoryMemory(
          eventId: widget.eventId,
          content: _contentController.text.trim(),
        );
      } else {
        // 备注记忆
        await _memoryService.addNoteMemory(
          eventId: widget.eventId,
          content: _contentController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context, const MemoryAddResult(success: true));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveBorderRadius.xl(context)),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSpacing.lg(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动条
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: ResponsiveSpacing.md(context)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // 标题
              Text(
                '添加记忆',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.lg(context),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveSpacing.md(context)),
              
              // 类型选择
              Row(
                children: [
                  _buildTypeChip(0, Icons.photo_library, '照片', Colors.blue),
                  SizedBox(width: ResponsiveSpacing.sm(context)),
                  _buildTypeChip(1, Icons.auto_stories, '故事', Colors.orange),
                  SizedBox(width: ResponsiveSpacing.sm(context)),
                  _buildTypeChip(2, Icons.note, '备注', Colors.green),
                ],
              ),
              SizedBox(height: ResponsiveSpacing.lg(context)),
              
              // 照片选择（仅照片类型）
              if (_selectedTab == 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('拍照'),
                      ),
                    ),
                    SizedBox(width: ResponsiveSpacing.md(context)),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo),
                        label: const Text('相册'),
                      ),
                    ),
                  ],
                ),
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(height: ResponsiveSpacing.md(context)),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImages[index]),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                SizedBox(height: ResponsiveSpacing.lg(context)),
              ],
              
              // 内容输入
              TextField(
                controller: _contentController,
                maxLines: _selectedTab == 0 ? 2 : 5,
                decoration: InputDecoration(
                  hintText: _selectedTab == 0 
                      ? '添加照片描述（可选）'
                      : (_selectedTab == 1 ? '记录这个特别的日子...' : '写下你的想法...'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context)),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveSpacing.lg(context)),
              
              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ),
              SizedBox(height: ResponsiveSpacing.md(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(int index, IconData icon, String label, Color color) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveSpacing.md(context),
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context)),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant),
              SizedBox(height: ResponsiveSpacing.xs(context)),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: ResponsiveFontSize.sm(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
