import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/events_provider.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/ui_helpers.dart';

/// ============================================================================
/// 统计屏幕 - 数据可视化分析
/// ============================================================================

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsService _analyticsService = AnalyticsService();
  
  // 数据状态
  ComprehensiveStats? _comprehensiveStats;
  List<CategoryStats>? _categoryStats;
  List<MonthlyStats>? _monthlyStats;
  EventDensityAnalysis? _densityAnalysis;
  List<CreationTrend>? _creationTrend;
  bool _isLoading = true;
  String? _error;
  
  // 时间范围选择
  int _selectedYear = DateTime.now().year;
  String _timeRange = 'year'; // 'week', 'month', 'year', 'all'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final eventsProvider = context.read<EventsProvider>();
      final events = eventsProvider.events;
      final archivedEvents = eventsProvider.archivedEvents;
      final allEvents = [...events, ...archivedEvents];
      final categories = eventsProvider.categories;

      // 并行加载所有统计数据
      final results = await Future.wait([
        _analyticsService.getComprehensiveStats(
          events: allEvents,
          categories: categories,
        ),
        _analyticsService.getEventsByCategoryStats(
          events: allEvents,
          categories: categories,
        ),
        _analyticsService.getEventsByMonthStats(
          events: allEvents,
          year: _selectedYear,
        ),
        _analyticsService.getEventDensityAnalysis(
          events: allEvents,
          year: _selectedYear,
        ),
        _analyticsService.getCreationTrend(
          events: allEvents,
          days: _getDaysForTimeRange(),
        ),
      ]);

      if (mounted) {
        setState(() {
          _comprehensiveStats = results[0] as ComprehensiveStats;
          _categoryStats = results[1] as List<CategoryStats>;
          _monthlyStats = results[2] as List<MonthlyStats>;
          _densityAnalysis = results[3] as EventDensityAnalysis;
          _creationTrend = results[4] as List<CreationTrend>;
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

  int _getDaysForTimeRange() {
    switch (_timeRange) {
      case 'week':
        return 7;
      case 'month':
        return 30;
      case 'year':
        return 365;
      case 'all':
        return 365 * 3; // 最多3年
      default:
        return 365;
    }
  }

  void _onTimeRangeChanged(String? value) {
    if (value != null && value != _timeRange) {
      setState(() {
        _timeRange = value;
      });
      _loadStatistics();
    }
  }

  void _onYearChanged(int delta) {
    setState(() {
      _selectedYear += delta;
    });
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState(context)
                        : _buildContent(context, isDark),
              ),
            ],
          ),
        ),
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
            '数据分析',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          // 时间范围选择器
          _buildTimeRangeSelector(context),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButton<String>(
        value: _timeRange,
        isDense: true,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'week', child: Text('本周')),
          DropdownMenuItem(value: 'month', child: Text('本月')),
          DropdownMenuItem(value: 'year', child: Text('本年')),
          DropdownMenuItem(value: 'all', child: Text('全部')),
        ],
        onChanged: _onTimeRangeChanged,
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadStatistics,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        // TabBar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: '概览'),
              Tab(text: '分类'),
              Tab(text: '趋势'),
              Tab(text: '分布'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, isDark),
              _buildCategoryTab(context, isDark),
              _buildTrendTab(context, isDark),
              _buildDistributionTab(context, isDark),
            ],
          ),
        ),
      ],
    );
  }

  /// 概览标签页
  Widget _buildOverviewTab(BuildContext context, bool isDark) {
    final stats = _comprehensiveStats;
    if (stats == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 核心指标卡片
          _buildOverviewCards(context, stats),
          const SizedBox(height: 24),
          
          // 时间分布环图
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '事件状态分布',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildStatusPieChart(context, isDark),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusLegend(context, stats.timeStats),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 快速统计
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快速统计',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(context, '7天内即将到来', '${stats.upcomingEvents7Days} 个'),
                  _buildStatRow(context, '30天内即将到来', '${stats.upcomingEvents30Days} 个'),
                  _buildStatRow(context, '已设置提醒', '${stats.totalReminders} 个'),
                  _buildStatRow(context, '已使用分类', '${stats.usedCategories}/${stats.totalCategories}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, ComprehensiveStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            title: '总事件',
            value: '${stats.totalEvents}',
            icon: Icons.event_note,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            title: '活跃',
            value: '${stats.activeEvents}',
            icon: Icons.play_circle_outline,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            title: '归档',
            value: '${stats.archivedEvents}',
            icon: Icons.archive,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart(BuildContext context, bool isDark) {
    final stats = _comprehensiveStats?.timeStats;
    if (stats == null || stats.totalEvents == 0) {
      return Center(
        child: Text(
          '暂无数据',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: stats.upcomingEvents.toDouble(),
            title: '${stats.upcomingEvents}',
            color: Colors.blue,
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          PieChartSectionData(
            value: stats.passedEvents.toDouble(),
            title: '${stats.passedEvents}',
            color: Colors.orange,
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          PieChartSectionData(
            value: stats.archivedEvents.toDouble(),
            title: '${stats.archivedEvents}',
            color: Colors.grey,
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend(BuildContext context, TimeRangeStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(context, '即将到来', Colors.blue, stats.upcomingEvents),
        _buildLegendItem(context, '已过/正计', Colors.orange, stats.passedEvents),
        _buildLegendItem(context, '已归档', Colors.grey, stats.archivedEvents),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 分类标签页
  Widget _buildCategoryTab(BuildContext context, bool isDark) {
    final stats = _categoryStats;
    if (stats == null || stats.isEmpty) {
      return const Center(child: Text('暂无分类数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 饼图
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '分类分布',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: stats.map((stat) {
                          return PieChartSectionData(
                            value: stat.count.toDouble(),
                            title: '${stat.percentage.toStringAsFixed(0)}%',
                            color: stat.color,
                            radius: 70,
                            titleStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 分类列表
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '分类详情',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...stats.map((stat) => _buildCategoryItem(context, stat)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, CategoryStats stat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(stat.icon, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.categoryName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stat.percentage,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(stat.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${stat.count}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 趋势标签页
  Widget _buildTrendTab(BuildContext context, bool isDark) {
    final trend = _creationTrend;
    if (trend == null || trend.isEmpty) {
      return const Center(child: Text('暂无趋势数据'));
    }

    // 计算最大值
    final maxCount = trend.map((t) => t.count).reduce((a, b) => a > b ? a : b);
    final maxCumulative = trend.last.cumulative;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 柱状图 - 每日创建数量
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '创建趋势',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (maxCount + 1).toDouble(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final item = trend[groupIndex];
                              return BarTooltipItem(
                                '${item.date.month}/${item.date.day}\n${item.count} 个',
                                TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() % 7 != 0) return const SizedBox();
                                final item = trend[value.toInt()];
                                return Text(
                                  '${item.date.month}/${item.date.day}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        barGroups: trend.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.count.toDouble(),
                                color: Theme.of(context).colorScheme.primary,
                                width: 8,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 折线图 - 累计事件
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '累计事件数',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        maxY: (maxCumulative + 5).toDouble(),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final item = trend[spot.x.toInt()];
                                return LineTooltipItem(
                                  '${item.date.month}/${item.date.day}\n累计: ${item.cumulative}',
                                  TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() % 7 != 0) return const SizedBox();
                                final item = trend[value.toInt()];
                                return Text(
                                  '${item.date.month}/${item.date.day}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5,
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: trend.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value.cumulative.toDouble());
                            }).toList(),
                            isCurved: true,
                            color: Theme.of(context).colorScheme.secondary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 分布标签页
  Widget _buildDistributionTab(BuildContext context, bool isDark) {
    final monthly = _monthlyStats;
    final density = _densityAnalysis;
    
    if (monthly == null || density == null) {
      return const Center(child: Text('暂无分布数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 年份选择器
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _onYearChanged(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '$_selectedYear 年',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _selectedYear < DateTime.now().year
                    ? () => _onYearChanged(1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 月度分布柱状图
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '月度分布',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (density.peakMonthEventCount + 1).toDouble(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final item = monthly[groupIndex];
                              return BarTooltipItem(
                                '${item.month}月\n${item.count} 个事件',
                                TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        barGroups: monthly.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.count.toDouble(),
                                color: _getMonthColor(entry.value.count, density.peakMonthEventCount),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 密度分析
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '密度分析',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(context, '月均事件', density.averageEventsPerMonth.toStringAsFixed(1)),
                  _buildStatRow(context, '周均事件', density.averageEventsPerWeek.toStringAsFixed(1)),
                  _buildStatRow(context, '最活跃月份', density.peakMonthLabel),
                  _buildStatRow(context, '最活跃月份事件数', '${density.peakMonthEventCount}'),
                  if (density.quietMonthEventCount > 0) ...[
                    _buildStatRow(context, '最安静月份', density.quietMonthLabel),
                    _buildStatRow(context, '最安静月份事件数', '${density.quietMonthEventCount}'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMonthColor(int count, int maxCount) {
    if (maxCount == 0) return Colors.grey;
    final intensity = count / maxCount;
    if (intensity >= 0.8) return Colors.green;
    if (intensity >= 0.6) return Colors.lightGreen;
    if (intensity >= 0.4) return Colors.yellow;
    if (intensity >= 0.2) return Colors.orange;
    return Colors.grey;
  }
}
