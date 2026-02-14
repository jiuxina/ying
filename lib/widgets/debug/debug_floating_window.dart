import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/debug_logger.dart';
import '../../services/notification_service.dart';

/// 调试悬浮窗
/// 
/// 用于实时显示应用运行时的调试信息，帮助排查通知和其他功能问题
/// 
/// 功能：
/// - 实时显示日志信息
/// - 显示通知队列状态
/// - 显示权限状态
/// - 支持日志筛选和搜索
/// - 支持日志复制
/// - 可拖动和调整大小
/// 
/// 使用方式：
/// ```dart
/// DebugFloatingWindow.show(context);
/// ```
class DebugFloatingWindow extends StatefulWidget {
  const DebugFloatingWindow({super.key});

  /// 显示调试悬浮窗
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DebugFloatingWindow(),
    );
  }

  @override
  State<DebugFloatingWindow> createState() => _DebugFloatingWindowState();
}

class _DebugFloatingWindowState extends State<DebugFloatingWindow>
    with SingleTickerProviderStateMixin {
  final DebugLogger _logger = DebugLogger();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _searchController = TextEditingController();

  /// 当前选中的标签页
  late TabController _tabController;

  /// 搜索关键词
  String _searchQuery = '';

  /// 选中的日志类型筛选
  DebugLogType? _selectedLogType;

  /// 通知权限状态
  Map<String, dynamic>? _notificationStatus;

  /// 待处理通知列表
  List<PendingNotificationRequest> _pendingNotifications = [];

  /// 是否展开（最小化/最大化）
  bool _isExpanded = true;

  /// 悬浮窗位置
  Offset _position = const Offset(20, 100);

  /// 是否正在拖动
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _logger.addListener(_onLogUpdated);
    _loadNotificationStatus();
    _loadPendingNotifications();
  }

  @override
  void dispose() {
    _logger.removeListener(_onLogUpdated);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 日志更新回调
  void _onLogUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 加载通知状态
  Future<void> _loadNotificationStatus() async {
    final status = await _notificationService.checkNotificationStatus();
    if (mounted) {
      setState(() {
        _notificationStatus = status;
      });
    }
  }

  /// 加载待处理通知
  Future<void> _loadPendingNotifications() async {
    final notifications = await _notificationService.getPendingNotifications();
    if (mounted) {
      setState(() {
        _pendingNotifications = notifications;
      });
    }
  }

  /// 刷新数据
  Future<void> _refresh() async {
    await Future.wait([
      _loadNotificationStatus(),
      _loadPendingNotifications(),
    ]);
  }

  /// 获取筛选后的日志
  List<DebugLogEntry> get _filteredLogs {
    var logs = _logger.logs.toList();

    // 按类型筛选
    if (_selectedLogType != null) {
      logs = logs.where((log) => log.type == _selectedLogType).toList();
    }

    // 按搜索关键词筛选
    if (_searchQuery.isNotEmpty) {
      logs = logs
          .where((log) =>
              log.message.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return logs.reversed.toList(); // 最新的日志在前
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 半透明背景（点击关闭）
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black26,
          ),
        ),
        // 悬浮窗主体
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  (_position.dx + details.delta.dx)
                      .clamp(0.0, MediaQuery.of(context).size.width - 400),
                  (_position.dy + details.delta.dy)
                      .clamp(0.0, MediaQuery.of(context).size.height - 600),
                );
              });
            },
            onPanEnd: (_) {
              setState(() {
                _isDragging = false;
              });
            },
            child: Material(
              elevation: _isDragging ? 16 : 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: _isExpanded ? 400 : 200,
                height: _isExpanded ? 600 : 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade300,
                    width: 2,
                  ),
                ),
                child: _isExpanded ? _buildExpandedContent() : _buildMinimizedContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建最小化内容
  Widget _buildMinimizedContent() {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('调试窗口', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建展开内容
  Widget _buildExpandedContent() {
    return Column(
      children: [
        // 标题栏
        _buildHeader(),
        // 标签页
        _buildTabs(),
        // 内容区域
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLogsTab(),
              _buildNotificationsTab(),
              _buildPermissionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            '调试窗口',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _refresh,
            tooltip: '刷新',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          // 最小化按钮
          IconButton(
            icon: const Icon(Icons.minimize, size: 20),
            onPressed: () {
              setState(() {
                _isExpanded = false;
              });
            },
            tooltip: '最小化',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          // 关闭按钮
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '关闭',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 构建标签页
  Widget _buildTabs() {
    return Container(
      color: Colors.grey.shade100,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        tabs: const [
          Tab(text: '日志'),
          Tab(text: '通知'),
          Tab(text: '权限'),
        ],
      ),
    );
  }

  /// 构建日志标签页
  Widget _buildLogsTab() {
    return Column(
      children: [
        // 搜索和筛选
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索日志...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              // 清空按钮
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  _logger.clear();
                  setState(() {});
                },
                tooltip: '清空日志',
              ),
            ],
          ),
        ),
        // 类型筛选
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _buildTypeChip('全部', null),
              _buildTypeChip('通知 🔔', DebugLogType.notification),
              _buildTypeChip('权限 🔐', DebugLogType.permission),
              _buildTypeChip('时区 🌏', DebugLogType.timezone),
              _buildTypeChip('事件 📅', DebugLogType.event),
              _buildTypeChip('错误 ❌', DebugLogType.error),
              _buildTypeChip('警告 ⚠️', DebugLogType.warning),
            ],
          ),
        ),
        const Divider(height: 1),
        // 日志列表
        Expanded(
          child: _filteredLogs.isEmpty
              ? const Center(
                  child: Text(
                    '暂无日志',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    return _buildLogItem(log);
                  },
                ),
        ),
      ],
    );
  }

  /// 构建类型筛选芯片
  Widget _buildTypeChip(String label, DebugLogType? type) {
    final isSelected = _selectedLogType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedLogType = selected ? type : null;
          });
        },
        selectedColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  /// 构建日志条目
  Widget _buildLogItem(DebugLogEntry log) {
    return InkWell(
      onLongPress: () {
        // 长按复制日志
        Clipboard.setData(
          ClipboardData(text: '${log.formattedTime} ${log.message}'),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已复制到剪贴板'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  log.typeIcon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  log.formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              log.message,
              style: const TextStyle(fontSize: 12),
            ),
            if (log.data != null && log.data!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.data.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建通知标签页
  Widget _buildNotificationsTab() {
    return RefreshIndicator(
      onRefresh: _loadPendingNotifications,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 统计信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '通知队列统计',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '待处理通知数: ${_pendingNotifications.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 通知列表
          if (_pendingNotifications.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    '暂无待处理通知',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ...(_pendingNotifications.map((notification) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.notifications, size: 20),
                  title: Text(
                    notification.title ?? '无标题',
                    style: const TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    'ID: ${notification.id}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: 'ID: ${notification.id}\n'
                              'Title: ${notification.title}\n'
                              'Body: ${notification.body ?? "无内容"}',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已复制到剪贴板'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              );
            })),
        ],
      ),
    );
  }

  /// 构建权限标签页
  Widget _buildPermissionsTab() {
    return RefreshIndicator(
      onRefresh: _loadNotificationStatus,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 权限状态
          _buildPermissionCard(
            '通知权限',
            _notificationStatus?['hasNotificationPermission'] ?? false,
            Icons.notifications,
          ),
          const SizedBox(height: 8),
          _buildPermissionCard(
            '精确闹钟权限',
            _notificationStatus?['hasExactAlarmPermission'] ?? false,
            Icons.alarm,
          ),
          const SizedBox(height: 8),
          // 警告信息
          if (_notificationStatus?['warnings'] != null &&
              (_notificationStatus!['warnings'] as List).isNotEmpty) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '警告',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(_notificationStatus!['warnings'] as List).map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $warning',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 建议信息
          if (_notificationStatus?['recommendations'] != null &&
              (_notificationStatus!['recommendations'] as List).isNotEmpty) ...[
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '建议',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(_notificationStatus!['recommendations'] as List).map(
                      (recommendation) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          recommendation.toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建权限卡片
  Widget _buildPermissionCard(String title, bool granted, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: granted ? Colors.green : Colors.red,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
