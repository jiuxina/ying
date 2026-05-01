import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event_template.dart';
import '../services/template_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/ui_helpers.dart';

/// ============================================================================
/// 模板库页面
/// ============================================================================

class TemplateGalleryScreen extends StatefulWidget {
  final Function(EventTemplate template, DateTime targetDate)? onTemplateSelected;

  const TemplateGalleryScreen({super.key, this.onTemplateSelected});

  @override
  State<TemplateGalleryScreen> createState() => _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends State<TemplateGalleryScreen>
    with SingleTickerProviderStateMixin {
  final TemplateService _templateService = TemplateService();
  
  late TabController _tabController;
  List<EventTemplate> _allTemplates = [];
  List<EventTemplate> _filteredTemplates = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TemplateCategory.builtInCategories.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final category = TemplateCategory.builtInCategories[_tabController.index];
    setState(() {
      _selectedCategory = category.id == 'custom' ? null : category.id;
      _filterTemplates();
    });
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      _allTemplates = await _templateService.getAllTemplates(forceReload: true);
      _filterTemplates();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterTemplates() {
    var result = _allTemplates;
    
    // 按分类过滤
    if (_selectedCategory != null) {
      result = result.where((t) => t.category == _selectedCategory).toList();
    }
    
    // 按搜索词过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) {
        return t.name.toLowerCase().contains(query) ||
            (t.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    setState(() => _filteredTemplates = result);
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _filterTemplates();
  }

  Future<void> _onTemplateTap(EventTemplate template) async {
    HapticFeedback.mediumImpact();
    
    // 显示日期选择对话框
    final date = await _showDatePicker(template);
    if (date != null && mounted) {
      if (widget.onTemplateSelected != null) {
        widget.onTemplateSelected!(template, date);
        Navigator.pop(context);
      } else {
        // 直接返回选中的模板和日期
        Navigator.pop(context, {'template': template, 'targetDate': date});
      }
    }
  }

  Future<DateTime?> _showDatePicker(EventTemplate template) async {
    DateTime selectedDate = DateTime.now();
    final defaults = template.defaultValues;
    
    // 如果模板有默认月日，设置初始日期
    if (defaults['targetMonth'] != null && defaults['targetDay'] != null) {
      final now = DateTime.now();
      selectedDate = DateTime(now.year, defaults['targetMonth'], defaults['targetDay']);
    }

    return showDialog<DateTime>(
      context: context,
      builder: (context) => _DatePickerDialog(
        template: template,
        initialDate: selectedDate,
      ),
    );
  }

  Future<void> _onDeleteTemplate(EventTemplate template) async {
    if (template.isBuiltIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内置模板不能删除')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模板"${template.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _templateService.deleteTemplate(template.id);
      _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板已删除')),
        );
      }
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
              _buildSearchBar(context),
              _buildTabBar(context),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTemplateList(context),
              ),
            ],
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
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: ResponsiveSpacing.sm(context)),
          Text(
            '模板库',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveFontSize.title(context),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showImportDialog(),
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.lg(context),
        vertical: ResponsiveSpacing.sm(context),
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '搜索模板...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _filterTemplates();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          contentPadding: EdgeInsets.symmetric(
            vertical: ResponsiveSpacing.sm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveSpacing.md(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.sm(context)),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
        labelStyle: TextStyle(
          fontSize: ResponsiveFontSize.sm(context),
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.all(ResponsiveSpacing.xs(context)),
        tabs: TemplateCategory.builtInCategories
            .map((cat) => Tab(text: '${cat.icon} ${cat.name}'))
            .toList(),
      ),
    );
  }

  Widget _buildTemplateList(BuildContext context) {
    if (_filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: ResponsiveSpacing.md(context)),
            Text(
              '没有找到模板',
              style: TextStyle(
                fontSize: ResponsiveFontSize.lg(context),
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveSpacing.md(context)),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _TemplateCard(
          template: template,
          onTap: () => _onTemplateTap(template),
          onDelete: template.isBuiltIn ? null : () => _onDeleteTemplate(template),
        );
      },
    );
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入模板'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请粘贴模板JSON数据：'),
            SizedBox(height: ResponsiveSpacing.md(context)),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"id": "...", "name": "...", ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _templateService.importTemplate(controller.text);
                if (mounted) {
                  Navigator.pop(context);
                  _loadTemplates();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('模板导入成功')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('导入失败: $e')),
                  );
                }
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
}

/// 模板卡片组件
class _TemplateCard extends StatelessWidget {
  final EventTemplate template;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveSpacing.sm(context)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
          child: Row(
            children: [
              // 图标
              Container(
                width: ResponsiveUtils.scaledSize(context, 48),
                height: ResponsiveUtils.scaledSize(context, 48),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
                ),
                child: Center(
                  child: Text(
                    template.icon,
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.xl(context),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveSpacing.base(context)),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: TextStyle(
                              fontSize: ResponsiveFontSize.base(context),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (template.isBuiltIn)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveSpacing.xs(context),
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(
                                ResponsiveBorderRadius.xs(context),
                              ),
                            ),
                            child: Text(
                              '内置',
                              style: TextStyle(
                                fontSize: ResponsiveFontSize.xs(context),
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (template.description != null) ...[
                      SizedBox(height: ResponsiveSpacing.xs(context)),
                      Text(
                        template.description!,
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.sm(context),
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: ResponsiveSpacing.xs(context)),
                    // 功能标签
                    Wrap(
                      spacing: ResponsiveSpacing.xs(context),
                      runSpacing: ResponsiveSpacing.xs(context),
                      children: _buildFeatureTags(context),
                    ),
                  ],
                ),
              ),
              // 操作按钮
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeatureTags(BuildContext context) {
    final tags = <Widget>[];
    
    if (template.features.contains(TemplateFeature.yearlyRepeat)) {
      tags.add(_buildTag(context, '每年重复', Icons.repeat));
    }
    if (template.features.contains(TemplateFeature.autoAgeCalculation)) {
      tags.add(_buildTag(context, '年龄计算', Icons.cake));
    }
    if (template.features.contains(TemplateFeature.lunarDateConversion)) {
      tags.add(_buildTag(context, '农历', Icons.nights_stay));
    }
    if (template.defaultValues['enableNotification'] == true) {
      tags.add(_buildTag(context, '提醒', Icons.notifications));
    }
    
    return tags;
  }

  Widget _buildTag(BuildContext context, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.xs(context),
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xs(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.outline),
          SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveFontSize.xs(context),
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 日期选择对话框
class _DatePickerDialog extends StatefulWidget {
  final EventTemplate template;
  final DateTime initialDate;

  const _DatePickerDialog({
    required this.template,
    required this.initialDate,
  });

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime _selectedDate;
  bool _isLunar = false;
  // ignore: unused_field
  int _lunarMonth = 1;
  // ignore: unused_field
  int _lunarDay = 1;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    
    final defaults = widget.template.defaultValues;
    _isLunar = defaults['isLunar'] == true;
    _lunarMonth = defaults['lunarMonth'] as int? ?? 1;
    _lunarDay = defaults['lunarDay'] as int? ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: EdgeInsets.all(ResponsiveSpacing.lg(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                Text(
                  widget.template.icon,
                  style: TextStyle(fontSize: ResponsiveFontSize.xl(context)),
                ),
                SizedBox(width: ResponsiveSpacing.sm(context)),
                Expanded(
                  child: Text(
                    widget.template.name,
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.lg(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSpacing.lg(context)),
            
            // 日期选择
            ListTile(
              leading: Icon(Icons.calendar_today, 
                color: Theme.of(context).colorScheme.primary),
              title: const Text('选择日期'),
              subtitle: Text(
                '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
            ),
            
            // 农历选项
            if (widget.template.features.contains(TemplateFeature.lunarDateConversion))
              SwitchListTile(
                secondary: Icon(Icons.nights_stay,
                  color: Theme.of(context).colorScheme.secondary),
                title: const Text('使用农历日期'),
                value: _isLunar,
                onChanged: (v) => setState(() => _isLunar = v),
              ),
            
            SizedBox(height: ResponsiveSpacing.lg(context)),
            
            // 按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                SizedBox(width: ResponsiveSpacing.sm(context)),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selectedDate),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}
