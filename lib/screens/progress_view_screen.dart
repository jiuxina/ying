import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/countdown_event.dart';
import '../providers/events_provider.dart';
import '../widgets/progress_ring.dart';
import '../widgets/year_progress_grid.dart';
import '../widgets/month_progress_bar.dart';

/// 进度视图页面
///
/// 整合三种进度展示：圆形进度环、年度进度网格、月度进度条。
/// 支持切换不同视图，显示统计数据。
class ProgressViewScreen extends StatefulWidget {
  const ProgressViewScreen({super.key});

  @override
  State<ProgressViewScreen> createState() => _ProgressViewScreenState();
}

class _ProgressViewScreenState extends State<ProgressViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    // 获取所有事件日期
    final eventDates = eventsProvider.events
        .map((e) => DateTime(e.targetDate.year, e.targetDate.month, e.targetDate.day))
        .toSet();

    // 计算统计数据
    final stats = _calculateStats(eventsProvider.events);

    return Scaffold(
      appBar: AppBar(
        title: const Text('进度视图'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.radio_button_checked), text: '环形'),
            Tab(icon: Icon(Icons.calendar_month), text: '年度'),
            Tab(icon: Icon(Icons.view_day), text: '月度'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 统计信息卡片
          _buildStatsCard(context, stats),

          // Tab 内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 环形视图
                _buildRingView(context, stats),

                // 年度视图
                _buildYearView(context, eventDates),

                // 月度视图
                _buildMonthView(context, eventDates),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 计算统计数据
  Map<String, dynamic> _calculateStats(List<CountdownEvent> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 即将到来（7天内）
    final upcoming = events.where((e) {
      if (e.isCountUp) return false;
      final targetDay = DateTime(e.targetDate.year, e.targetDate.month, e.targetDate.day);
      final daysUntil = targetDay.difference(today).inDays;
      return daysUntil >= 0 && daysUntil <= 7;
    }).length;

    // 已过期
    final expired = events.where((e) {
      if (e.isCountUp) return false;
      return e.daysRemaining < 0;
    }).length;

    // 正进行中
    final ongoing = events.where((e) {
      if (e.isCountUp) return true;
      return e.daysRemaining >= 0;
    }).length;

    // 今年的总数
    final thisYearEvents = events.where((e) => e.targetDate.year == now.year).length;

    // 今年的已过事件
    final thisYearPassed = events.where((e) {
      if (e.isCountUp) return true;
      return e.targetDate.year < now.year ||
          (e.targetDate.year == now.year && e.targetDate.month < now.month) ||
          (e.targetDate.year == now.year &&
              e.targetDate.month == now.month &&
              e.targetDate.day <= now.day);
    }).length;

    // 年度进度
    final yearProgress = thisYearPassed / (thisYearEvents > 0 ? thisYearEvents : 1);

    return {
      'total': events.length,
      'upcoming': upcoming,
      'expired': expired,
      'ongoing': ongoing,
      'thisYear': thisYearEvents,
      'thisYearPassed': thisYearPassed,
      'yearProgress': yearProgress.clamp(0.0, 1.0),
    };
  }

  /// 构建统计卡片
  Widget _buildStatsCard(
      BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            '总事件',
            '${stats['total']}',
            Icons.event_note,
          ),
          _buildStatItem(
            context,
            '进行中',
            '${stats['ongoing']}',
            Icons.play_circle_outline,
          ),
          _buildStatItem(
            context,
            '即将到来',
            '${stats['upcoming']}',
            Icons.schedule,
          ),
          _buildStatItem(
            context,
            '已过期',
            '${stats['expired']}',
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 构建环形视图
  Widget _buildRingView(
      BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final yearProgress = stats['yearProgress'] as double;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 年度进度环
          ProgressRingWithLabel(
            progress: yearProgress,
            size: 180,
            strokeWidth: 16,
            title: '年度进度',
            description: '${stats['thisYearPassed']} / ${stats['thisYear']} 个事件',
            gradientColors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
          const SizedBox(height: 32),

          // 事件分布环
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ProgressRingWithLabel(
                progress: stats['ongoing'] / (stats['total'] > 0 ? stats['total'] : 1),
                size: 120,
                strokeWidth: 10,
                title: '进行中',
                color: Colors.blue,
              ),
              ProgressRingWithLabel(
                progress: stats['upcoming'] / (stats['total'] > 0 ? stats['total'] : 1),
                size: 120,
                strokeWidth: 10,
                title: '即将到来',
                color: Colors.orange,
              ),
              ProgressRingWithLabel(
                progress: stats['expired'] / (stats['total'] > 0 ? stats['total'] : 1),
                size: 120,
                strokeWidth: 10,
                title: '已过期',
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 快速统计
          _buildQuickStats(context, stats),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快速统计',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickStatRow(
              context, '今年已有事件', '${stats['thisYearPassed']} 个'),
          _buildQuickStatRow(
              context, '今年待办事件', '${stats['thisYear'] - stats['thisYearPassed']} 个'),
          _buildQuickStatRow(
              context, '今年事件总数', '${stats['thisYear']} 个'),
        ],
      ),
    );
  }

  Widget _buildQuickStatRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建年度视图
  Widget _buildYearView(BuildContext context, Set<DateTime> eventDates) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 年份选择器
          _buildYearSelector(context),
          const SizedBox(height: 16),

          // 年度进度网格
          YearProgressGridWithStats(
            year: _selectedYear,
            eventDates: eventDates,
            onDayTap: (date) => _showDayDetails(context, date, eventDates),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => setState(() => _selectedYear--),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '$_selectedYear 年',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: _selectedYear < currentYear
              ? () => setState(() => _selectedYear++)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  /// 构建月度视图
  Widget _buildMonthView(BuildContext context, Set<DateTime> eventDates) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 今年的月度进度条
          for (int month = 1; month <= 12; month++) ...[
            MonthProgressBar(
              year: _selectedYear,
              month: month,
              eventDates: eventDates,
              onDayTap: (date) => _showDayDetails(context, date, eventDates),
              height: 60,
            ),
            if (month < 12) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  /// 显示某天的事件详情
  void _showDayDetails(
      BuildContext context, DateTime date, Set<DateTime> eventDates) {
    final theme = Theme.of(context);
    final eventsProvider = context.read<EventsProvider>();

    // 找到当天的事件
    final dayEvents = eventsProvider.events.where((e) {
      final targetDay = DateTime(e.targetDate.year, e.targetDate.month, e.targetDate.day);
      return targetDay.year == date.year &&
          targetDay.month == date.month &&
          targetDay.day == date.day;
    }).toList();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.year}年${date.month}月${date.day}日',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${dayEvents.length} 个事件',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (dayEvents.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('这一天没有事件'),
                  ),
                )
              else
                ...dayEvents.map((event) => ListTile(
                      leading: Icon(
                        event.isCountUp
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(event.title),
                      subtitle: Text(
                        event.isCountUp
                            ? '已过去 ${event.daysRemaining.abs()} 天'
                            : '还剩 ${event.daysRemaining} 天',
                      ),
                      trailing: Text(
                        '${event.daysRemaining.abs()}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
