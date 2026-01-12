import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../models/countdown_event.dart';
import '../../providers/events_provider.dart';
import '../../services/ical_service.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';
// import '../../widgets/common/empty_state.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  List<CountdownEvent> _importedEvents = [];
  bool _isLoading = false;
  bool _hasImported = false;

  Future<void> _pickAndParseFile() async {
    setState(() {
      _isLoading = true;
      _hasImported = false;
      _importedEvents = [];
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final events = await ICalService.parseIcsFile(filePath);
        
        setState(() {
          _importedEvents = events;
        });
        
        if (events.isEmpty && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未从文件中找到有效事件')),
          );
        }
      }
    } catch (e) {
      debugPrint('选择文件失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取文件失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confrimImport() async {
    if (_importedEvents.isEmpty) return;

    setState(() => _isLoading = true);
    
    final provider = Provider.of<EventsProvider>(context, listen: false);
    int successCount = 0;

    for (final event in _importedEvents) {
      try {
        await provider.insertEvent(event);
        successCount++;
      } catch (e) {
        debugPrint('导入事件失败: ${event.title}, $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasImported = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $successCount 个事件')),
      );
      
      // 延迟关闭页面
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              if (_importedEvents.isEmpty && !_hasImported)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_file, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          '选择 .ics 文件导入日历事件',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _pickAndParseFile,
                          icon: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.folder_open),
                          label: const Text('选择文件'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '解析到 ${_importedEvents.length} 个事件',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            FilledButton(
                              onPressed: _isLoading || _hasImported ? null : _confrimImport,
                              child: Text(_hasImported ? '已导入' : '确认导入'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _importedEvents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final event = _importedEvents[index];
                            return Card(
                              elevation: 0,
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                              child: ListTile(
                                title: Text(event.title),
                                subtitle: Text(DateFormat('yyyy-MM-dd').format(event.targetDate)),
                                trailing: event.isRepeating 
                                    ? const Icon(Icons.repeat, size: 16) 
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.import_export,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '导入日历',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
