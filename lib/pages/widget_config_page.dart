import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/events_provider.dart';
import '../models/countdown_event.dart';
import '../services/widget_service.dart';

class WidgetConfigPage extends StatefulWidget {
  const WidgetConfigPage({super.key});

  @override
  State<WidgetConfigPage> createState() => _WidgetConfigPageState();
}

class _WidgetConfigPageState extends State<WidgetConfigPage> {
  int? _widgetId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkWidgetId();
  }

  Future<void> _checkWidgetId() async {
    try {
      const channel = MethodChannel('com.jiuxina.ying/install');
      _widgetId = await channel.invokeMethod<int>('getAppWidgetId');
      debugPrint("Widget ID from channel: $_widgetId");
    } catch (e) {
      debugPrint("Error getting widget ID: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectEvent(CountdownEvent event) async {
    if (_widgetId != null) {
      await WidgetService.saveConfiguredWidget(_widgetId!, event);
      
      // 通过 MethodChannel 通知原生端完成配置
      // 这会设置 RESULT_OK 并正确返回 widget ID，让系统知道配置成功
      try {
        const channel = MethodChannel('com.jiuxina.ying/install');
        await channel.invokeMethod('finishConfigure', {'widgetId': _widgetId});
      } catch (e) {
        debugPrint("Error finishing configure: $e");
        // 降级处理：如果 finishConfigure 失败，尝试直接退出
        await SystemNavigator.pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未获取到 Widget ID，无法保存配置')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final events = Provider.of<EventsProvider>(context).events;
    // 过滤掉归档的
    final activeEvents = events.where((e) => !e.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择要显示的事件'),
      ),
      body: _widgetId == null
          ? const Center(child: Text('未检测到 Widget ID\n请直接从桌面添加小部件'))
          : activeEvents.isEmpty 
              ? const Center(child: Text('暂无事件，请先在 App 中添加'))
              : ListView.builder(
                  itemCount: activeEvents.length,
                  itemBuilder: (context, index) {
                    final event = activeEvents[index];
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.targetDate.toString().split(' ')[0]),
                      onTap: () => _selectEvent(event),
                      trailing: const Icon(Icons.check_circle_outline),
                    );
                  },
                ),
    );
  }
}
