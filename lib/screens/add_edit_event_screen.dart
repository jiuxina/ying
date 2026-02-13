import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/countdown_event.dart';
import '../providers/events_provider.dart';
import '../utils/constants.dart';
import '../utils/lunar_utils.dart';
import '../utils/responsive_utils.dart';
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
  bool _isPickingImage = false;

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
      _categoryId =
          'custom'; // Default to custom if not specified, or 'birthday'
      _targetDate = DateTime.now().add(const Duration(days: 30));
      _targetDate = DateTime(
        _targetDate.year,
        _targetDate.month,
        _targetDate.day,
        0,
        0,
        0,
      );
    }

    // 从目标日期提取时间
    _targetHour = _targetDate.hour;
    _targetMinute = _targetDate.minute;
    _targetSecond = _targetDate.second;
    _useExactTime =
        _targetHour != 0 || _targetMinute != 0 || _targetSecond != 0;

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
        title: Text(
          '放弃更改？',
          style: TextStyle(fontSize: ResponsiveFontSize.lg(context)),
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          '您有未保存的更改，确定要离开吗？',
          style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '继续编辑',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '放弃',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              overflow: TextOverflow.ellipsis,
            ),
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
          Navigator.pop(this.context);
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(ResponsiveSpacing.lg(context)),
                      child: Column(
                        children: [
                          // 基本信息
                          const SectionHeader(title: '基本信息', icon: Icons.info),
                          SizedBox(height: ResponsiveSpacing.md(context)),
                          GlassCard(
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _titleController,
                                  label: '事件名称',
                                  hint: '请输入事件名称',
                                  icon: Icons.title,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? '请输入事件名称'
                                      : null,
                                  key: const Key('event_title_input'),
                                ),
                                Divider(
                                  height: ResponsiveUtils.scaledSize(
                                    context,
                                    1,
                                  ),
                                ),
                                // 分组选择
                                Consumer<EventsProvider>(
                                  builder: (context, provider, child) {
                                    final groups = provider.groups;
                                    if (groups.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Column(
                                      children: [
                                        ListTile(
                                          leading: IconBox(
                                            icon: Icons.folder,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ),
                                          title: Text(
                                            '所属分组',
                                            style: TextStyle(
                                              fontSize: ResponsiveFontSize.base(
                                                context,
                                              ),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: DropdownButtonHideUnderline(
                                            child: DropdownButton<String?>(
                                              value: _groupId,
                                              hint: Text(
                                                '无分组',
                                                style: TextStyle(
                                                  fontSize:
                                                      ResponsiveFontSize.base(
                                                        context,
                                                      ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              items: [
                                                DropdownMenuItem<String?>(
                                                  value: null,
                                                  child: Text(
                                                    '无分组',
                                                    style: TextStyle(
                                                      fontSize:
                                                          ResponsiveFontSize.base(
                                                            context,
                                                          ),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                ...groups.map(
                                                  (
                                                    g,
                                                  ) => DropdownMenuItem<String?>(
                                                    value: g.id,
                                                    child: Text(
                                                      g.name,
                                                      style: TextStyle(
                                                        fontSize:
                                                            ResponsiveFontSize.base(
                                                              context,
                                                            ),
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (v) =>
                                                  setState(() => _groupId = v),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          height: ResponsiveUtils.scaledSize(
                                            context,
                                            1,
                                          ),
                                        ),
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
                          SizedBox(height: ResponsiveSpacing.lg(context)),

                          // 分类
                          const SectionHeader(
                            title: '分类',
                            icon: Icons.category,
                          ),
                          SizedBox(height: ResponsiveSpacing.md(context)),
                          _buildCategorySelector(),
                          SizedBox(height: ResponsiveSpacing.lg(context)),

                          // 日期设置
                          const SectionHeader(
                            title: '日期设置',
                            icon: Icons.calendar_month,
                          ),
                          SizedBox(height: ResponsiveSpacing.md(context)),
                          GlassCard(
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const IconBox(
                                    icon: Icons.event,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    '目标日期',
                                    style: TextStyle(
                                      fontSize: ResponsiveFontSize.base(
                                        context,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    DateFormat(
                                          'yyyy年MM月dd日',
                                        ).format(_targetDate) +
                                        (_isLunar ? ' (农历)' : ''),
                                    style: TextStyle(
                                      fontSize: ResponsiveFontSize.sm(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _selectDate,
                                ),
                                Divider(
                                  height: ResponsiveUtils.scaledSize(
                                    context,
                                    1,
                                  ),
                                ),
                                SwitchListTile(
                                  secondary: const IconBox(
                                    icon: Icons.auto_awesome,
                                    color: Colors.purple,
                                  ),
                                  title: Text(
                                    '使用农历日期',
                                    style: TextStyle(
                                      fontSize: ResponsiveFontSize.base(
                                        context,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  value: _isLunar,
                                  onChanged: (v) =>
                                      setState(() => _isLunar = v),
                                ),
                                Divider(
                                  height: ResponsiveUtils.scaledSize(
                                    context,
                                    1,
                                  ),
                                ),
                                // "正数日" switch removed - automatically derived from target date
                                // Divider removed
                                SwitchListTile(
                                  secondary: const IconBox(
                                    icon: Icons.access_time_filled,
                                    color: Colors.cyan,
                                  ),
                                  title: Text(
                                    '精确时间（时分秒）',
                                    style: TextStyle(
                                      fontSize: ResponsiveFontSize.base(
                                        context,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    _useExactTime
                                        ? '${_targetHour.toString().padLeft(2, '0')}:${_targetMinute.toString().padLeft(2, '0')}:${_targetSecond.toString().padLeft(2, '0')}'
                                        : '默认 00:00:00',
                                    style: TextStyle(
                                      fontSize: ResponsiveFontSize.sm(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  value: _useExactTime,
                                  onChanged: (v) =>
                                      setState(() => _useExactTime = v),
                                ),
                                if (_useExactTime) ...[
                                  Divider(
                                    height: ResponsiveUtils.scaledSize(
                                      context,
                                      1,
                                    ),
                                  ),
                                  ListTile(
                                    leading: const IconBox(
                                      icon: Icons.schedule,
                                      color: Colors.indigo,
                                    ),
                                    title: Text(
                                      '目标时间',
                                      style: TextStyle(
                                        fontSize: ResponsiveFontSize.base(
                                          context,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${_targetHour.toString().padLeft(2, '0')}:${_targetMinute.toString().padLeft(2, '0')}:${_targetSecond.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: ResponsiveFontSize.sm(
                                          context,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: _selectTargetTime,
                                  ),
                                ],
                                Divider(
                                  height: ResponsiveUtils.scaledSize(
                                    context,
                                    1,
                                  ),
                                ),
                                SwitchListTile(
                                  secondary: const IconBox(
                                    icon: Icons.repeat,
                                    color: Colors.orange,
                                  ),
                                  title: Text(
                                    '每年重复',
                                    style: TextStyle(
                                      fontSize: ResponsiveFontSize.base(
                                        context,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  value: _isRepeating,
                                  onChanged: (v) =>
                                      setState(() => _isRepeating = v),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: ResponsiveSpacing.lg(context)),

                          // 通知设置
                          const SectionHeader(
                            title: '通知提醒',
                            icon: Icons.notifications,
                          ),
                          SizedBox(height: ResponsiveSpacing.md(context)),
                          GlassCard(
                            child: Column(
                              children: [
                                SwitchListTile(
                                  secondary: IconBox(
                                    icon: _enableNotification
                                        ? Icons.notifications_active
                                        : Icons.notifications_off,
                                    color: _enableNotification
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                  title: Text(
                                    '开启提醒',
                                    style: TextStyle(
                                      fontSize: ResponsiveFontSize.base(
                                        context,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  value: _enableNotification,
                                  onChanged: (v) =>
                                      setState(() => _enableNotification = v),
                                ),
                                if (_enableNotification) ...[
                                  Divider(
                                    height: ResponsiveUtils.scaledSize(
                                      context,
                                      1,
                                    ),
                                  ),
                                  // Reminders List
                                  ..._reminders.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final r = entry.value;
                                    return Column(
                                      children: [
                                        ListTile(
                                          leading: const IconBox(
                                            icon: Icons.alarm,
                                            color: Colors.blue,
                                          ),
                                          title: Text(
                                            r.daysBefore == 0
                                                ? '当天'
                                                : (r.daysBefore < 0
                                                      ? '已过 ${r.daysBefore.abs()} 天'
                                                      : '提前 ${r.daysBefore} 天'),
                                            style: TextStyle(
                                              fontSize: ResponsiveFontSize.base(
                                                context,
                                              ),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: ResponsiveFontSize.sm(
                                                context,
                                              ),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  size: ResponsiveIconSize.md(
                                                    context,
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    _showReminderDialog(
                                                      reminder: r,
                                                      index: index,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  size: ResponsiveIconSize.md(
                                                    context,
                                                  ),
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed: () {
                                                  HapticFeedback.mediumImpact();
                                                  setState(
                                                    () => _reminders.removeAt(
                                                      index,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          height: ResponsiveUtils.scaledSize(
                                            context,
                                            1,
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  // Add Button
                                  ListTile(
                                    leading: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      '添加提醒',
                                      style: TextStyle(
                                        fontSize: ResponsiveFontSize.base(
                                          context,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _showReminderDialog(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: ResponsiveSpacing.lg(context)),

                          // 背景设置
                          const SectionHeader(title: '背景设置', icon: Icons.image),
                          SizedBox(height: ResponsiveSpacing.md(context)),
                          GlassCard(
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const IconBox(
                                    icon: Icons.image,
                                    color: Colors.pink,
                                  ),
                                  title: Text(
                                    '背景图片',
                                    style: TextStyle(
                                      fontSize: ResponsiveFontSize.base(
                                        context,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    _isPickingImage
                                        ? '选择中...'
                                        : (_backgroundImage != null ? '已设置' : '默认背景'),
                                    style: TextStyle(
                                      fontSize: ResponsiveFontSize.sm(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: _isPickingImage
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : (_backgroundImage != null
                                          ? IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () => setState(
                                                () => _backgroundImage = null,
                                              ),
                                            )
                                          : const Icon(Icons.chevron_right)),
                                  onTap: _isPickingImage ? null : _pickImage,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: ResponsiveSpacing.xxl(context)),

                          // 保存按钮
                          _buildSaveButton(),
                          SizedBox(height: ResponsiveSpacing.xxl(context)),
                        ],
                      ),
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
      padding: EdgeInsets.fromLTRB(
        ResponsiveSpacing.sm(context),
        ResponsiveSpacing.sm(context),
        ResponsiveSpacing.base(context),
        ResponsiveSpacing.sm(context),
      ),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.close,
            onPressed: () async {
              final shouldPop = await _confirmDiscard();
              if (shouldPop && mounted) {
                Navigator.pop(this.context);
              }
            },
          ),
          SizedBox(width: ResponsiveSpacing.sm(context)),
          Text(
            _isEditing ? '编辑事件' : '添加事件',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveFontSize.title(context),
            ),
            overflow: TextOverflow.ellipsis,
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
      padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Wrap IconBox in Align to center it when TextField grows
          Align(
            alignment: Alignment.center,
            child: IconBox(icon: icon, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(width: ResponsiveSpacing.base(context)),
          Expanded(
            child: TextFormField(
              key: key,
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  fontSize: ResponsiveFontSize.base(context),
                ),
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: ResponsiveFontSize.base(context),
                ),
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
          spacing: ResponsiveSpacing.sm(context),
          runSpacing: ResponsiveSpacing.sm(context),
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
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSpacing.base(context),
                  vertical:
                      ResponsiveSpacing.sm(context) +
                      ResponsiveSpacing.xs(context),
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(
                    ResponsiveBorderRadius.md(context),
                  ),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: ResponsiveSpacing.sm(context),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.icon,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.lg(context),
                      ),
                    ),
                    SizedBox(
                      width:
                          ResponsiveSpacing.xs(context) +
                          ResponsiveSpacing.xs(context),
                    ),
                    Flexible(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                          fontSize: ResponsiveFontSize.base(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
        borderRadius: BorderRadius.circular(
          ResponsiveBorderRadius.base(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: ResponsiveSpacing.md(context),
            offset: Offset(0, ResponsiveSpacing.xs(context)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('save_event_button'),
          borderRadius: BorderRadius.circular(
            ResponsiveBorderRadius.base(context),
          ),
          onTap: _isSaving ? null : _save,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveSpacing.base(context),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _isSaving
                  ? [
                      SizedBox(
                        width: ResponsiveIconSize.md(context),
                        height: ResponsiveIconSize.md(context),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveSpacing.md(context)),
                      Text(
                        '保存中...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveFontSize.lg(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  : [
                      Icon(
                        _isEditing ? Icons.check : Icons.add,
                        color: Colors.white,
                        size: ResponsiveIconSize.base(context),
                      ),
                      SizedBox(width: ResponsiveSpacing.sm(context)),
                      Text(
                        _isEditing ? '保存修改' : '添加事件',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveFontSize.lg(context),
                        ),
                        overflow: TextOverflow.ellipsis,
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
      setState(() {
        _targetDate = picked;
        // _isCountUp is now automatically derived when saving
      });
    }
  }

  void _showReminderDialog({Reminder? reminder, int? index}) {
    HapticFeedback.selectionClick();
    int days = reminder?.daysBefore ?? 1;
    TimeOfDayWithSeconds time = reminder != null
        ? TimeOfDayWithSeconds(hour: reminder.hour, minute: reminder.minute, second: 0)
        : const TimeOfDayWithSeconds(hour: 9, minute: 0, second: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassCard(
                padding: EdgeInsets.all(ResponsiveSpacing.lg(context)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reminder == null ? '添加提醒' : '编辑提醒',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.lg(context),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveSpacing.lg(context)),
                    // 提前天数选择
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '提前天数: ',
                          style: TextStyle(
                            fontSize: ResponsiveFontSize.base(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: days > 0
                              ? () {
                                  HapticFeedback.selectionClick();
                                  setDialogState(() => days--);
                                }
                              : null,
                        ),
                        Flexible(
                          child: Text(
                            days == 0 ? '当天' : '提前 $days 天',
                            style: TextStyle(
                              fontSize: ResponsiveFontSize.base(context),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: days < 365
                              ? () {
                                  HapticFeedback.selectionClick();
                                  setDialogState(() => days++);
                                }
                              : null,
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveSpacing.base(context)),
                    Divider(),
                    // 提醒时间选择
                    ListTile(
                      leading: IconBox(
                        icon: Icons.access_time,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        '提醒时间',
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.base(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.base(context),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        final picked = await showTimePickerSheet(
                          context: context,
                          initialHour: time.hour,
                          initialMinute: time.minute,
                          initialSecond: 0,
                          showSeconds: false,
                        );
                        if (picked != null) {
                          setDialogState(() => time = picked);
                        }
                      },
                    ),
                    SizedBox(height: ResponsiveSpacing.lg(context)),
                    // 按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            '取消',
                            style: TextStyle(
                              fontSize: ResponsiveFontSize.base(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: ResponsiveSpacing.sm(context)),
                        FilledButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
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
                          child: Text(
                            '确定',
                            style: TextStyle(
                              fontSize: ResponsiveFontSize.base(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
                      fontSize: ResponsiveFontSize.base(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);
    HapticFeedback.selectionClick();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        setState(() {
          _backgroundImage = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
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
            0,
            0,
            0,
          );

    String? lunarDateStr;
    if (_isLunar) {
      lunarDateStr = LunarUtils.getLunarDateString(_targetDate);
    }

    // Auto-derive isCountUp from target date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(
      targetDateTime.year,
      targetDateTime.month,
      targetDateTime.day,
    );
    final autoIsCountUp = targetDay.isBefore(today);

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
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      targetDate: targetDateTime,
      isLunar: _isLunar,
      lunarDateStr: lunarDateStr,
      categoryId: _categoryId, // Corrected variable name
      isCountUp: autoIsCountUp, // Automatically derived
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
      if (mounted) {
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? '保存成功' : '添加成功',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '保存失败: $e',
              style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
