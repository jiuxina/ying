import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/countdown_event.dart';
import '../providers/events_provider.dart';
import '../utils/constants.dart';
import '../utils/lunar_utils.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/ui_helpers.dart';
import '../widgets/common/segmented_date_input.dart';
import '../widgets/common/time_picker_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';


/// ============================================================================
/// 添加/编辑事件页面
/// ============================================================================

class AddEditEventScreen extends StatefulWidget {
  final CountdownEvent? event;

  const AddEditEventScreen({super.key, this.event});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late String _categoryId;
  late DateTime _targetDate;
  bool _isLunar = false;
  bool _isCountUp = false;
  bool _isRepeating = false;
  bool _enableNotification = true;

  String? _backgroundImage;
  
  // 精确时间（时分秒）
  bool _useExactTime = false;
  int _targetHour = 0;
  int _targetMinute = 0;
  int _targetSecond = 0;

  String? _groupId;
  List<Reminder> _reminders = [];

  bool get _isEditing => widget.event != null;
  
  // 追踪初始值用于判断是否有未保存的更改
  String _initialTitle = '';
  String _initialNote = '';
  String _initialCategoryId = '';
  DateTime? _initialTargetDate;
  bool _initialIsLunar = false;
  bool _initialIsCountUp = false;
  bool _initialIsRepeating = false;
  bool _initialEnableNotification = true;
  String? _initialBackgroundImage;
  String? _initialGroupId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.event!;
      _titleController.text = e.title;
      _noteController.text = e.note ?? '';
      _categoryId = e.categoryId;
      _targetDate = e.targetDate;
      _isLunar = e.isLunar;
      _isCountUp = e.isCountUp;
      _isRepeating = e.isRepeating;
      _enableNotification = e.enableNotification;

      _backgroundImage = e.backgroundImage;

      _groupId = e.groupId;
      _reminders = List.from(e.reminders);
    } else {
      _categoryId = 'custom'; // Default to custom if not specified, or 'birthday'
      _targetDate = DateTime.now().add(const Duration(days: 30));
      _targetDate = DateTime(_targetDate.year, _targetDate.month, _targetDate.day, 0, 0, 0);
    }
    
    // 从目标日期提取时间
    _targetHour = _targetDate.hour;
    _targetMinute = _targetDate.minute;
    _targetSecond = _targetDate.second;
    _useExactTime = _targetHour != 0 || _targetMinute != 0 || _targetSecond != 0;
    
    // 保存初始值用于追踪更改
    _initialTitle = _titleController.text;
    _initialNote = _noteController.text;
    _initialCategoryId = _categoryId;
    _initialTargetDate = _targetDate;
    _initialIsLunar = _isLunar;
    _initialIsCountUp = _isCountUp;
    _initialIsRepeating = _isRepeating;
    _initialEnableNotification = _enableNotification;
    _initialBackgroundImage = _backgroundImage;
    _initialGroupId = _groupId;
  }
  
  /// 检查是否有未保存的更改
  bool _hasUnsavedChanges() {
    return _titleController.text != _initialTitle ||
           _noteController.text != _initialNote ||
           _categoryId != _initialCategoryId ||
           _targetDate != _initialTargetDate ||
           _isLunar != _initialIsLunar ||
           _isCountUp != _initialIsCountUp ||
           _isRepeating != _initialIsRepeating ||
           _enableNotification != _initialEnableNotification ||
           _backgroundImage != _initialBackgroundImage ||
           _groupId != _initialGroupId;
  }
  
  /// 显示放弃更改确认对话框
  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges()) return true;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃更改？'),
        content: const Text('您有未保存的更改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
  
  // ... (dispose)

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: AppBackground(
          backgroundImage: _backgroundImage,
          enableBlur: true,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // 基本信息
                      const SectionHeader(title: '基本信息', icon: Icons.info),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _titleController,
                              label: '事件名称',
                              hint: '请输入事件名称',
                              icon: Icons.title,
                              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入事件名称' : null,
                              key: const Key('event_title_input'),
                            ),
                            const Divider(height: 1),
                            // 分组选择
                            Consumer<EventsProvider>(
                              builder: (context, provider, child) {
                                final groups = provider.groups;
                                if (groups.isEmpty) return const SizedBox.shrink();
                                return Column(
                                  children: [
                                    ListTile(
                                      leading: IconBox(icon: Icons.folder, color: Theme.of(context).colorScheme.secondary),
                                      title: const Text('所属分组'),
                                      trailing: DropdownButtonHideUnderline(
                                        child: DropdownButton<String?>(
                                          value: _groupId,
                                          hint: const Text('无分组'),
                                          items: [
                                              const DropdownMenuItem<String?>(
                                                value: null,
                                                child: Text('无分组'),
                                              ),
                                              ...groups.map((g) => DropdownMenuItem<String?>(
                                                value: g.id,
                                                child: Text(g.name),
                                              )),
                                          ],
                                          onChanged: (v) => setState(() => _groupId = v),
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              },
                            ),
                            _buildTextField(
                              controller: _noteController,
                              label: '备注',
                              hint: '可选备注信息',
                              icon: Icons.notes,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 分类
                      const SectionHeader(title: '分类', icon: Icons.category),
                      const SizedBox(height: 12),
                      _buildCategorySelector(),
                      const SizedBox(height: 20),

                      // 日期设置
                      const SectionHeader(title: '日期设置', icon: Icons.calendar_month),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const IconBox(icon: Icons.event, color: Colors.blue),
                              title: const Text('目标日期'),
                              subtitle: Text(
                                DateFormat('yyyy年MM月dd日').format(_targetDate) +
                                    (_isLunar ? ' (农历)' : ''),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _selectDate,
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary: const IconBox(icon: Icons.auto_awesome, color: Colors.purple),
                              title: const Text('使用农历日期'),
                              value: _isLunar,
                              onChanged: (v) => setState(() => _isLunar = v),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary: const IconBox(icon: Icons.replay, color: Colors.green),
                              title: const Text('正数日（已过天数）'),
                              value: _isCountUp,
                              onChanged: (v) => setState(() => _isCountUp = v),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary: const IconBox(icon: Icons.access_time_filled, color: Colors.cyan),
                              title: const Text('精确时间（时分秒）'),
                              subtitle: Text(_useExactTime 
                                  ? '${_targetHour.toString().padLeft(2, '0')}:${_targetMinute.toString().padLeft(2, '0')}:${_targetSecond.toString().padLeft(2, '0')}'
                                  : '默认 00:00:00'),
                              value: _useExactTime,
                              onChanged: (v) => setState(() => _useExactTime = v),
                            ),
                            if (_useExactTime) ...[
                              const Divider(height: 1),
                              ListTile(
                                leading: const IconBox(icon: Icons.schedule, color: Colors.indigo),
                                title: const Text('目标时间'),
                                subtitle: Text(
                                  '${_targetHour.toString().padLeft(2, '0')}:${_targetMinute.toString().padLeft(2, '0')}:${_targetSecond.toString().padLeft(2, '0')}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _selectTargetTime,
                              ),
                            ],
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary: const IconBox(icon: Icons.repeat, color: Colors.orange),
                              title: const Text('每年重复'),
                              value: _isRepeating,
                              onChanged: (v) => setState(() => _isRepeating = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 通知设置
                      const SectionHeader(title: '通知提醒', icon: Icons.notifications),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          children: [
                            SwitchListTile(
                              secondary: IconBox(
                                icon: _enableNotification ? Icons.notifications_active : Icons.notifications_off,
                                color: _enableNotification ? Colors.orange : Colors.grey,
                              ),
                              title: const Text('开启提醒'),
                              value: _enableNotification,
                              onChanged: (v) => setState(() => _enableNotification = v),
                            ),
                            if (_enableNotification) ...[
                              const Divider(height: 1),
                              // Reminders List
                              ..._reminders.asMap().entries.map((entry) {
                                final index = entry.key;
                                final r = entry.value;
                                return Column(
                                  children: [
                                    ListTile(
                                      leading: const IconBox(icon: Icons.alarm, color: Colors.blue),
                                      title: Text(r.daysBefore == 0 
                                          ? '当天' 
                                          : (r.daysBefore < 0 ? '已过 ${r.daysBefore.abs()} 天' : '提前 ${r.daysBefore} 天')),
                                      subtitle: Text('${r.hour.toString().padLeft(2,'0')}:${r.minute.toString().padLeft(2,'0')}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            onPressed: () => _showReminderDialog(reminder: r, index: index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                            onPressed: () => setState(() => _reminders.removeAt(index)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              }), 
                              // Add Button
                              ListTile(
                                leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                                title: const Text('添加提醒'),
                                onTap: () => _showReminderDialog(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 背景设置
                      const SectionHeader(title: '背景设置', icon: Icons.image),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const IconBox(icon: Icons.image, color: Colors.pink),
                              title: const Text('背景图片'),
                              subtitle: Text(_backgroundImage != null ? '已设置' : '默认背景'),
                              trailing: _backgroundImage != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => setState(() => _backgroundImage = null),
                                    )
                                  : const Icon(Icons.chevron_right),
                              onTap: _pickImage,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 保存按钮
                      _buildSaveButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            icon: Icons.close,
            onPressed: () async {
              final shouldPop = await _confirmDiscard();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
          Text(
            _isEditing ? '编辑事件' : '添加事件',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    Key? key,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          IconBox(icon: icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              key: key,
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<EventsProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _categoryId == category.id;
            final color = Color(category.color);

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _categoryId = category.id);
              },
              child: AnimatedContainer(
                duration: AppConstants.animationFast,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('save_event_button'),
          borderRadius: BorderRadius.circular(16),
          onTap: _isSaving ? null : _save,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _isSaving
                  ? [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '保存中...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ]
                  : [
                      Icon(
                        _isEditing ? Icons.check : Icons.add,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEditing ? '保存修改' : '添加事件',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();
    final picked = await showSegmentedDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pickedDay = DateTime(picked.year, picked.month, picked.day);
      setState(() {
        _targetDate = picked;
        // 自动设置正数日：当目标日期在过去时
        if (pickedDay.isBefore(today)) {
          _isCountUp = true;
        }
      });
    }
  }

  void _showReminderDialog({Reminder? reminder, int? index}) {
    int days = reminder?.daysBefore ?? 1;
    TimeOfDay time = reminder != null ? TimeOfDay(hour: reminder.hour, minute: reminder.minute) : const TimeOfDay(hour: 9, minute: 0);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(reminder == null ? '添加提醒' : '编辑提醒'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Row(
                     children: [
                       const Text('提前天数: '),
                       IconButton(
                         icon: const Icon(Icons.remove_circle_outline),
                         onPressed: days > 0 ? () => setDialogState(() => days--) : null,
                       ),
                       Text(days == 0 ? '当天' : '提前 $days 天'),
                       IconButton(
                         icon: const Icon(Icons.add_circle_outline),
                         onPressed: days < 365 ? () => setDialogState(() => days++) : null,
                       ),
                     ],
                   ),
                   ListTile(
                     title: const Text('提醒时间'),
                     trailing: Text(time.format(context)),
                     onTap: () async {
                       final picked = await showTimePicker(context: context, initialTime: time);
                       if (picked != null) setDialogState(() => time = picked);
                     },
                   ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                TextButton(
                  onPressed: () {
                    final newReminder = Reminder(
                       id: reminder?.id ?? const Uuid().v4(),
                       eventId: widget.event?.id ?? '', // TBD on save
                       daysBefore: days,
                       hour: time.hour,
                       minute: time.minute,
                    );
                    
                    setState(() {
                      if (index != null) {
                         _reminders[index] = newReminder;
                      } else {
                         _reminders.add(newReminder);
                      }
                    });
                    Navigator.pop(context);
                  }, 
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Removed unused _selectTime method
  Future<void> _selectTargetTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePickerSheet(
      context: context,
      initialHour: _targetHour,
      initialMinute: _targetMinute,
      initialSecond: _targetSecond,
      showSeconds: true,
    );
    if (picked != null) {
      setState(() {
        _targetHour = picked.hour;
        _targetMinute = picked.minute;
        _targetSecond = picked.second;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _backgroundImage = image.path;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    // 构建包含精确时间的目标日期
    final targetDateTime = _useExactTime
        ? DateTime(
            _targetDate.year,
            _targetDate.month,
            _targetDate.day,
            _targetHour,
            _targetMinute,
            _targetSecond,
          )
        : DateTime(
            _targetDate.year,
            _targetDate.month,
            _targetDate.day,
            0, 0, 0,
          );

    String? lunarDateStr;
    if (_isLunar) {
      lunarDateStr = LunarUtils.getLunarDateString(_targetDate);
    }

    // Sync legacy fields with first reminder if available
    int legacyDays = _reminders.isNotEmpty ? _reminders.first.daysBefore : 1;
    int legacyHour = _reminders.isNotEmpty ? _reminders.first.hour : 9;
    int legacyMinute = _reminders.isNotEmpty ? _reminders.first.minute : 0;
    
    // Ensure `categoryId` is passed correctly (it was `category: _category` in previous file view, but `categoryId` is the correct param name in model)
    // Wait, the file uses `category: _category` which I suspected was an error or legacy var name. 
    // In `_AddEditEventScreenState`, `_categoryId` is the variable name.
    // So I MUST use `categoryId: _categoryId`.

    final event = CountdownEvent(
      id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      targetDate: targetDateTime,
      isLunar: _isLunar,
      lunarDateStr: lunarDateStr,
      categoryId: _categoryId, // Corrected variable name
      isCountUp: _isCountUp,
      isRepeating: _isRepeating,
      isPinned: widget.event?.isPinned ?? false,
      isArchived: widget.event?.isArchived ?? false,
      backgroundImage: _backgroundImage,
      enableBlur: widget.event?.enableBlur ?? false,
      createdAt: widget.event?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      enableNotification: _enableNotification,
      notifyDaysBefore: legacyDays,
      notifyHour: legacyHour,
      notifyMinute: legacyMinute,
      groupId: _groupId,
      reminders: _reminders,
    );

    final provider = context.read<EventsProvider>();
    try {
      if (_isEditing) {
        await provider.updateEvent(event);
      } else {
        await provider.addEvent(
          title: event.title,
          note: event.note,
          targetDate: event.targetDate,
          isLunar: event.isLunar,
          lunarDateStr: event.lunarDateStr,
          categoryId: event.categoryId,
          isCountUp: event.isCountUp,
          isRepeating: event.isRepeating,
          backgroundImage: event.backgroundImage,
          enableBlur: event.enableBlur,
          enableNotification: event.enableNotification,
          notifyDaysBefore: event.notifyDaysBefore,
          notifyHour: event.notifyHour,
          notifyMinute: event.notifyMinute,
          groupId: event.groupId,
          reminders: event.reminders,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}
