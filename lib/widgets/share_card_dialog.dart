import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:provider/provider.dart';
import '../models/countdown_event.dart';
import '../models/share_template_model.dart';
import '../services/share_card_service.dart';
import '../services/share_link_service.dart';
import '../providers/events_provider.dart';
import '../utils/responsive_utils.dart';
import 'share_card_templates.dart';

/// 分享卡片对话框
/// 支持多种模板和分享方式
class ShareCardDialog extends StatefulWidget {
  final CountdownEvent event;

  const ShareCardDialog({
    super.key,
    required this.event,
  });

  @override
  State<ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<ShareCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;
  int _selectedTemplateIndex = 0;
  ShareTemplateAspectRatio _selectedRatio = ShareTemplateAspectRatio.square;
  
  // 自定义选项状态
  bool _showTitle = true;
  bool _showDate = true;
  bool _showNote = true;
  bool _showFooter = true;
  final bool _showDays = true;  // 默认显示核心天数，一般不建议隐藏，但提供选项
  
  // 自定义背景图片
  String? _customBackgroundPath;
  bool _isPickingImage = false;

  List<ShareTemplate> get _templates => ShareTemplate.presets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<EventsProvider>();
    final category = provider.getCategoryById(widget.event.categoryId);
    final categoryColor = Color(category.color);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 预览区域
            _buildPreview(context, categoryColor),
            SizedBox(height: ResponsiveSpacing.lg(context)),

            // 模板选择器
            _buildTemplateSelector(context),
            SizedBox(height: ResponsiveSpacing.base(context)),

            // 尺寸选择器
            _buildRatioSelector(context),
            SizedBox(height: ResponsiveSpacing.base(context)),
            
            // 自定义背景按钮
            _buildBackgroundSelector(context),
            SizedBox(height: ResponsiveSpacing.base(context)),
            
            // 内容选项开关
            _buildContentOptions(context, theme),
            SizedBox(height: ResponsiveSpacing.lg(context)),

            // 操作按钮
            _buildActionButtons(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, Color categoryColor) {
    final template = _templates[_selectedTemplateIndex];
    final effectiveTemplate = ShareTemplate(
      id: template.id,
      name: template.name,
      style: template.style,
      aspectRatio: _selectedRatio,
      theme: template.theme,
    );

    // 计算预览尺寸 (响应式，基于屏幕宽度)
    final screenWidth = MediaQuery.of(context).size.width;
    // 4倍间距 = Dialog insetPadding(左右各1倍) + 内部边距(左右各1倍)
    double previewWidth = (screenWidth - ResponsiveSpacing.base(context) * 4).clamp(280.0, 350.0);
    double previewHeight;
    switch (_selectedRatio) {
      case ShareTemplateAspectRatio.square:
        previewHeight = previewWidth;
        break;
      case ShareTemplateAspectRatio.portrait:
        previewHeight = previewWidth * 4 / 3;
        break;
      case ShareTemplateAspectRatio.landscape:
        previewHeight = previewWidth * 9 / 16;
        break;
    }

    return RepaintBoundary(
      key: _cardKey,
      child: Container(
        width: previewWidth,
        height: previewHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: ResponsiveUtils.scaledSize(context, 20),
              offset: Offset(0, ResponsiveUtils.scaledSize(context, 10)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 自定义背景图片层
              if (_customBackgroundPath != null)
                Image.file(
                  File(_customBackgroundPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              // 如果有自定义背景，添加半透明遮罩
              if (_customBackgroundPath != null)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              // 模板内容
              ShareCardTemplates.buildCard(
                event: widget.event,
                template: effectiveTemplate,
                options: ShareContentOptions(
                  showTitle: _showTitle,
                  showDays: _showDays,
                  showDate: _showDate,
                  showNote: _showNote,
                  showFooter: _showFooter,
                ),
                categoryColor: categoryColor,
                hasCustomBackground: _customBackgroundPath != null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSelector(BuildContext context) {
    return SizedBox(
      height: ResponsiveUtils.scaledSize(context, 40),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: _templates.length,
        separatorBuilder: (_, __) => SizedBox(width: ResponsiveSpacing.sm(context)),
        itemBuilder: (context, index) {
          final template = _templates[index];
          final isSelected = _selectedTemplateIndex == index;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedTemplateIndex = index);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSpacing.base(context), 
                vertical: ResponsiveSpacing.sm(context)
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                template.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveFontSize.md(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 选择/更换背景按钮
        Flexible(
          child: OutlinedButton.icon(
            onPressed: _isPickingImage ? null : _pickAndCropImage,
            icon: _isPickingImage 
                ? SizedBox(
                    width: ResponsiveIconSize.sm(context), 
                    height: ResponsiveIconSize.sm(context), 
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.image, size: ResponsiveIconSize.sm(context)),
            label: Text(
              _customBackgroundPath != null ? '更换背景' : '自定义背景',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _customBackgroundPath != null 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.white70,
              side: BorderSide(
                color: _customBackgroundPath != null 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.white38,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSpacing.base(context), 
                vertical: ResponsiveSpacing.sm(context)
              ),
            ),
          ),
        ),
        // 清除背景按钮
        if (_customBackgroundPath != null) ...[
          SizedBox(width: ResponsiveSpacing.sm(context)),
          IconButton(
            onPressed: () {
              setState(() => _customBackgroundPath = null);
            },
            icon: Icon(Icons.close, size: ResponsiveIconSize.md(context)),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            tooltip: '移除背景',
          ),
        ],
      ],
    );
  }

  Future<void> _pickAndCropImage() async {
    // 保存主题色（避免异步上下文问题）
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    setState(() => _isPickingImage = true);
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) {
        setState(() => _isPickingImage = false);
        return;
      }
      
      // 根据当前选择的比例计算裁剪比例
      CropAspectRatio cropRatio;
      switch (_selectedRatio) {
        case ShareTemplateAspectRatio.square:
          cropRatio = const CropAspectRatio(ratioX: 1, ratioY: 1);
          break;
        case ShareTemplateAspectRatio.portrait:
          cropRatio = const CropAspectRatio(ratioX: 3, ratioY: 4);
          break;
        case ShareTemplateAspectRatio.landscape:
          cropRatio = const CropAspectRatio(ratioX: 16, ratioY: 9);
          break;
      }
      
      // 调用裁剪器
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: cropRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪背景图片',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
            hideBottomControls: false,
            activeControlsWidgetColor: primaryColor,
          ),
          IOSUiSettings(
            title: '裁剪背景图片',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      
      if (croppedFile != null && mounted) {
        setState(() {
          _customBackgroundPath = croppedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e', maxLines: 2, overflow: TextOverflow.ellipsis)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Widget _buildContentOptions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveSpacing.sm(context)),
      child: Wrap(
        spacing: ResponsiveSpacing.sm(context),
        runSpacing: ResponsiveSpacing.sm(context),
        alignment: WrapAlignment.center,
        children: [
          FilterChip(
            label: Text('标题', style: TextStyle(fontSize: ResponsiveFontSize.sm(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
            selected: _showTitle,
            onSelected: (bool value) => setState(() => _showTitle = value),
            visualDensity: VisualDensity.compact,
          ),
          FilterChip(
            label: Text('备注', style: TextStyle(fontSize: ResponsiveFontSize.sm(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
            selected: _showNote,
            onSelected: (bool value) => setState(() => _showNote = value),
            visualDensity: VisualDensity.compact,
          ),
          FilterChip(
            label: Text('日期', style: TextStyle(fontSize: ResponsiveFontSize.sm(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
            selected: _showDate,
            onSelected: (bool value) => setState(() => _showDate = value),
            visualDensity: VisualDensity.compact,
          ),
          FilterChip(
            label: Text('水印', style: TextStyle(fontSize: ResponsiveFontSize.sm(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
            selected: _showFooter,
            onSelected: (bool value) => setState(() => _showFooter = value),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildRatioSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ShareTemplateAspectRatio.values.map((ratio) {
        final isSelected = _selectedRatio == ratio;
        String label;
        String usage;
        switch (ratio) {
          case ShareTemplateAspectRatio.square:
            label = '1:1';
            usage = '朋友圈';
            break;
          case ShareTemplateAspectRatio.portrait:
            label = '3:4';
            usage = '小红书';
            break;
          case ShareTemplateAspectRatio.landscape:
            label = '16:9';
            usage = '微博';
            break;
        }
        return Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveSpacing.xs(context)),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedRatio = ratio;
                  // 如果已有背景图，提示用户需要重新裁剪
                  if (_customBackgroundPath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          '比例已变更，建议重新选择背景图片以适配新尺寸',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        action: SnackBarAction(
                          label: '选择图片',
                          onPressed: _pickAndCropImage,
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSpacing.md(context), 
                  vertical: ResponsiveSpacing.xs(context) * 1.5
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveFontSize.sm(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      usage,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: ResponsiveFontSize.xs(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // 复制链接按钮
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyLink,
            icon: Icon(Icons.link, size: ResponsiveIconSize.sm(context)),
            label: const Text('复制链接', maxLines: 1, overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: EdgeInsets.symmetric(vertical: ResponsiveSpacing.md(context)),
            ),
          ),
        ),
        SizedBox(width: ResponsiveSpacing.md(context)),
        // 分享按钮
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _isSharing ? null : _share,
            icon: _isSharing
                ? SizedBox(
                    width: ResponsiveIconSize.sm(context),
                    height: ResponsiveIconSize.sm(context),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.share, size: ResponsiveIconSize.sm(context)),
            label: const Text('分享图片', maxLines: 1, overflow: TextOverflow.ellipsis),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: ResponsiveSpacing.md(context)),
            ),
          ),
        ),
      ],
    );
  }

  void _copyLink() {
    final shareText = ShareLinkService.getShareableText(widget.event);
    Clipboard.setData(ClipboardData(text: shareText));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('链接已复制到剪贴板', maxLines: 1, overflow: TextOverflow.ellipsis),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);

    // 等待一帧以确保UI更新
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      await ShareCardService.shareEventCard(
        context,
        _cardKey,
        subject: '分享倒数日: ${widget.event.title}',
        text: '${widget.event.title} - ${widget.event.isCountUp ? "已经" : "还有"}${widget.event.daysRemaining.abs()}天',
      );
    }

    if (mounted) {
      setState(() => _isSharing = false);
      Navigator.pop(context);
    }
  }
}
