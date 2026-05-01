import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/intelligence_models.dart';
import '../../services/intelligence_service.dart';
import '../../services/smart_suggestion_service.dart'; // For SmartInputResult
import '../../utils/responsive_utils.dart';

/// 智能输入组件
///
/// 提供自然语言输入功能，支持：
/// - 语音转文字（可选）
/// - 实时解析预览
/// - 智能建议显示
/// - 重复事件检测提示
class SmartInputWidget extends StatefulWidget {
  /// 初始文本
  final String? initialText;
  
  /// 输入提示
  final String? hint;
  
  /// 解析完成回调
  final void Function(ParsedEventInput parsed, SmartInputResult? result)? onParsed;
  
  /// 文本变化回调
  final void Function(String text)? onChanged;
  
  /// 提交回调
  final void Function(String text)? onSubmitted;
  
  /// 是否显示解析预览
  final bool showPreview;
  
  /// 是否显示建议
  final bool showSuggestions;
  
  /// 是否检测重复
  final bool checkDuplicates;

  const SmartInputWidget({
    super.key,
    this.initialText,
    this.hint,
    this.onParsed,
    this.onChanged,
    this.onSubmitted,
    this.showPreview = true,
    this.showSuggestions = true,
    this.checkDuplicates = true,
  });

  @override
  State<SmartInputWidget> createState() => _SmartInputWidgetState();
}

class _SmartInputWidgetState extends State<SmartInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final IntelligenceService _intelligenceService = IntelligenceService();
  
  ParsedEventInput? _parsedInput;
  SmartInputResult? _smartResult;
  bool _isParsing = false;
  bool _showResultPanel = false;
  
  // 防抖定时器
  DateTime? _lastParseTime;
  static const _parseDebounce = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialText ?? '';
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    // 初始化智能服务
    _intelligenceService.initialize().then((_) {
      if (_controller.text.isNotEmpty) {
        _parseInput(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
    _debouncedParse();
  }

  void _onFocusChanged() {
    setState(() {
      _showResultPanel = _focusNode.hasFocus && _controller.text.isNotEmpty;
    });
  }

  void _debouncedParse() {
    final now = DateTime.now();
    _lastParseTime = now;
    
    Future.delayed(_parseDebounce, () {
      if (_lastParseTime == now && _controller.text.isNotEmpty) {
        _parseInput(_controller.text);
      }
    });
  }

  Future<void> _parseInput(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _parsedInput = null;
        _smartResult = null;
        _showResultPanel = false;
      });
      return;
    }

    setState(() => _isParsing = true);

    try {
      final result = await _intelligenceService.parseAndSuggest(text);
      
      if (mounted) {
        setState(() {
          _parsedInput = result.parsed;
          _smartResult = result;
          _isParsing = false;
          _showResultPanel = result.parsed.hasResult;
        });
        
        widget.onParsed?.call(result.parsed, result);
      }
    } catch (e) {
      debugPrint('解析失败: $e');
      if (mounted) {
        setState(() {
          _isParsing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 输入框
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // 输入行
              Row(
                children: [
                  // 智能图标
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  
                  // 输入框
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.base(context),
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hint ?? '输入事件，如"妈妈生日 下周五"',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (text) {
                        widget.onSubmitted?.call(text);
                      },
                    ),
                  ),
                  
                  // 清除按钮
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _parsedInput = null;
                          _smartResult = null;
                          _showResultPanel = false;
                        });
                      },
                    ),
                  
                  // 加载指示器
                  if (_isParsing)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              
              // 解析预览
              if (widget.showPreview && _showResultPanel && _parsedInput != null)
                _buildPreviewPanel(context),
            ],
          ),
        ),
        
        // 建议面板
        if (widget.showSuggestions && _smartResult != null)
          _buildSuggestionsPanel(context),
        
        // 重复事件警告
        if (widget.checkDuplicates && 
            _smartResult?.hasDuplicates == true)
          _buildDuplicateWarning(context),
      ],
    );
  }

  /// 构建解析预览面板
  Widget _buildPreviewPanel(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = _parsedInput!;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          if (parsed.title != null)
            _buildPreviewItem(
              context,
              icon: Icons.title,
              label: '标题',
              value: parsed.title!,
            ),
          
          // 日期
          if (parsed.targetDate != null)
            _buildPreviewItem(
              context,
              icon: Icons.calendar_today,
              label: '日期',
              value: _formatDate(parsed.targetDate!),
              badge: parsed.isLunar ? '农历' : null,
            ),
          
          // 分类
          if (parsed.categoryId != null)
            _buildPreviewItem(
              context,
              icon: Icons.category,
              label: '分类',
              value: _getCategoryName(parsed.categoryId!),
            ),
          
          // 重复
          if (parsed.isRepeating == true)
            _buildPreviewItem(
              context,
              icon: Icons.repeat,
              label: '重复',
              value: '每年',
            ),
          
          // 置信度指示器
          if (parsed.confidence > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '解析置信度: ${(parsed.confidence * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.xs(context),
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? badge,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: ResponsiveFontSize.sm(context),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveFontSize.sm(context),
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: ResponsiveFontSize.xs(context),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建建议面板
  Widget _buildSuggestionsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = _smartResult!.categorySuggestions ?? [];
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                '智能建议',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.sm(context),
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.take(3).map((s) {
              return ActionChip(
                label: Text(s.title),
                avatar: Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                side: BorderSide.none,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  // 应用建议
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建重复警告
  Widget _buildDuplicateWarning(BuildContext context) {
    final theme = Theme.of(context);
    final duplicates = _smartResult!.duplicateCheck!.matches;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '检测到相似事件',
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.sm(context),
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.error,
                  ),
                ),
                if (duplicates.isNotEmpty)
                  Text(
                    duplicates.first.eventTitle,
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.xs(context),
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // 查看重复事件
            },
            child: Text(
              '查看',
              style: TextStyle(
                fontSize: ResponsiveFontSize.sm(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  String _getCategoryName(String categoryId) {
    const categoryNames = {
      'birthday': '生日',
      'anniversary': '纪念日',
      'holiday': '节假日',
      'exam': '考试',
      'work': '工作',
      'travel': '旅行',
      'custom': '其他',
    };
    return categoryNames[categoryId] ?? categoryId;
  }
}

/// 智能输入对话框
///
/// 弹出式智能输入界面
class SmartInputDialog extends StatefulWidget {
  final String? initialText;
  final void Function(ParsedEventInput parsed)? onConfirm;

  const SmartInputDialog({
    super.key,
    this.initialText,
    this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialText,
    void Function(ParsedEventInput parsed)? onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SmartInputDialog(
        initialText: initialText,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<SmartInputDialog> createState() => _SmartInputDialogState();
}

class _SmartInputDialogState extends State<SmartInputDialog> {
  ParsedEventInput? _parsedInput;
  SmartInputResult? _smartResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('智能创建'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SmartInputWidget(
          initialText: widget.initialText,
          onParsed: (parsed, result) {
            setState(() {
              _parsedInput = parsed;
              _smartResult = result;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _parsedInput?.hasResult == true
              ? () {
                  widget.onConfirm?.call(_parsedInput!);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('创建'),
        ),
      ],
    );
  }
}
