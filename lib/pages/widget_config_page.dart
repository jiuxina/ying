import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
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
      
      // 完成配置，返回
      // SystemNavigator.pop() 可能会直接退出 App，但在 Android Widget 配置流程中是合理的
      // 或者可以使用 MethodChannel 通知 Android 侧 finishConfigure
      // HomeWidget 目前没有直接暴露 finishConfigure，但通常 updateWidget 后 Android 会处理
      // 这里我们尝试直接退出，模拟配置完成
      await SystemNavigator.pop(); 
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
