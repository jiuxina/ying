import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/countdown_event.dart';
import '../models/shared_event.dart';
import '../services/qr_code_service.dart';
import '../utils/responsive_utils.dart';
import '../providers/events_provider.dart';
import 'package:provider/provider.dart';

/// QR扫描结果
class QRScanResult {
  final QRDataType type;
  final dynamic data; // CountdownEvent, List<CountdownEvent>, SharedEventImportData, FamilyGroupInviteData

  const QRScanResult({
    required this.type,
    required this.data,
  });
}

/// QR码扫描器屏幕
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isScanning = true;
  bool _hasScanned = false;
  bool _flashOn = false;
  QRScanResult? _scanResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed && _isScanning) {
      _controller.start();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || !_isScanning) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) return;

    _processQRCode(rawValue);
  }

  Future<void> _processQRCode(String content) async {
    setState(() {
      _hasScanned = true;
      _isScanning = false;
    });

    HapticFeedback.mediumImpact();

    try {
      final qrData = QRCodeService.parseQRCode(content);
      if (qrData == null) {
        _showError('无法识别的二维码格式');
        return;
      }

      switch (qrData.type) {
        case QRDataType.singleEvent:
          final event = QRCodeService.parseSingleEvent(qrData);
          if (event != null) {
            setState(() {
              _scanResult = QRScanResult(type: QRDataType.singleEvent, data: event);
            });
          } else {
            _showError('事件数据解析失败');
          }
          break;

        case QRDataType.multipleEvents:
          final events = QRCodeService.parseMultipleEvents(qrData);
          if (events.isNotEmpty) {
            setState(() {
              _scanResult = QRScanResult(type: QRDataType.multipleEvents, data: events);
            });
          } else {
            _showError('没有找到有效的事件');
          }
          break;

        case QRDataType.sharedEvent:
          final importData = QRCodeService.parseSharedEvent(qrData);
          if (importData != null) {
            setState(() {
              _scanResult = QRScanResult(type: QRDataType.sharedEvent, data: importData);
            });
          } else {
            _showError('共享事件数据解析失败');
          }
          break;

        case QRDataType.familyGroup:
          final inviteData = QRCodeService.parseFamilyGroupInvite(qrData);
          if (inviteData != null) {
            setState(() {
              _scanResult = QRScanResult(type: QRDataType.familyGroup, data: inviteData);
            });
          } else {
            _showError('家庭组邀请数据解析失败');
          }
          break;
      }
    } catch (e) {
      _showError('扫描失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: _resetScanner,
        ),
      ),
    );
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _isScanning = true;
      _scanResult = null;
    });
  }

  void _toggleFlash() {
    _controller.toggleTorch();
    setState(() => _flashOn = !_flashOn);
    HapticFeedback.lightImpact();
  }

  void _switchCamera() {
    _controller.switchCamera();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '扫描二维码',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            tooltip: '闪光灯',
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: Icon(
              Icons.cameraswitch,
              color: Colors.white,
            ),
            tooltip: '切换摄像头',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 扫描器
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 扫描框遮罩
          _buildScanOverlay(context),

          // 底部操作区
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _scanResult != null
                ? _buildScanResultPanel(context)
                : _buildScanHint(context),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = ResponsiveUtils.scaledSize(context, 280);
    final top = (size.height - scanAreaSize) / 2 - 60;
    final left = (size.width - scanAreaSize) / 2;

    return Stack(
      children: [
        // 半透明遮罩
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                top: top,
                left: left,
                child: Container(
                  width: scanAreaSize,
                  height: scanAreaSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(
                      ResponsiveBorderRadius.lg(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 扫描框边框
        Positioned(
          top: top,
          left: left,
          child: Container(
            width: scanAreaSize,
            height: scanAreaSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(
                ResponsiveBorderRadius.lg(context),
              ),
            ),
            child: _buildCorners(context, scanAreaSize),
          ),
        ),

        // 提示文字
        Positioned(
          top: top + scanAreaSize + ResponsiveSpacing.xl(context),
          left: 0,
          right: 0,
          child: Text(
            '将二维码放入框内扫描',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: ResponsiveFontSize.base(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCorners(BuildContext context, double size) {
    final cornerLength = ResponsiveUtils.scaledSize(context, 24);
    final cornerWidth = 4.0;
    final color = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        // 左上角
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: cornerLength,
            height: cornerWidth,
            color: color,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: cornerWidth,
            height: cornerLength,
            color: color,
          ),
        ),

        // 右上角
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: cornerLength,
            height: cornerWidth,
            color: color,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: cornerWidth,
            height: cornerLength,
            color: color,
          ),
        ),

        // 左下角
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: cornerLength,
            height: cornerWidth,
            color: color,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: cornerWidth,
            height: cornerLength,
            color: color,
          ),
        ),

        // 右下角
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: cornerLength,
            height: cornerWidth,
            color: color,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: cornerWidth,
            height: cornerLength,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildScanHint(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickAction(
              icon: Icons.image,
              label: '从相册选择',
              onTap: _pickFromGallery,
            ),
            _buildQuickAction(
              icon: Icons.history,
              label: '历史记录',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveSpacing.md(context)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: ResponsiveIconSize.lg(context),
            ),
          ),
          SizedBox(height: ResponsiveSpacing.sm(context)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: ResponsiveFontSize.sm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveBorderRadius.xl(context)),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 拖动条
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveSpacing.lg(context)),

            // 结果内容
            _buildResultContent(context),

            SizedBox(height: ResponsiveSpacing.lg(context)),

            // 操作按钮
            _buildResultActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(BuildContext context) {
    final theme = Theme.of(context);

    if (_scanResult == null) return const SizedBox.shrink();

    switch (_scanResult!.type) {
      case QRDataType.singleEvent:
        final event = _scanResult!.data as CountdownEvent;
        return _buildEventPreview(context, event);

      case QRDataType.multipleEvents:
        final events = _scanResult!.data as List<CountdownEvent>;
        return _buildMultipleEventsPreview(context, events);

      case QRDataType.sharedEvent:
        final importData = _scanResult!.data as SharedEventImportData;
        return _buildSharedEventPreview(context, importData);

      case QRDataType.familyGroup:
        final inviteData = _scanResult!.data as FamilyGroupInviteData;
        return _buildFamilyGroupPreview(context, inviteData);
    }
  }

  Widget _buildEventPreview(BuildContext context, CountdownEvent event) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.sm(context)),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    ResponsiveBorderRadius.sm(context),
                  ),
                ),
                child: Icon(
                  Icons.event,
                  color: theme.colorScheme.primary,
                  size: ResponsiveIconSize.base(context),
                ),
              ),
              SizedBox(width: ResponsiveSpacing.md(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.lg(context),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${event.targetDate.year}-${event.targetDate.month.toString().padLeft(2, '0')}-${event.targetDate.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.sm(context),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleEventsPreview(BuildContext context, List<CountdownEvent> events) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSpacing.md(context),
                  vertical: ResponsiveSpacing.sm(context),
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    ResponsiveBorderRadius.sm(context),
                  ),
                ),
                child: Text(
                  '${events.length} 个事件',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSpacing.md(context)),
          ...events.take(3).map((e) => Padding(
            padding: EdgeInsets.only(bottom: ResponsiveSpacing.sm(context)),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  size: ResponsiveIconSize.sm(context),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: ResponsiveSpacing.sm(context)),
                Expanded(
                  child: Text(
                    e.title,
                    style: TextStyle(fontSize: ResponsiveFontSize.sm(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
          if (events.length > 3)
            Text(
              '还有 ${events.length - 3} 个事件...',
              style: TextStyle(
                fontSize: ResponsiveFontSize.sm(context),
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSharedEventPreview(BuildContext context, SharedEventImportData importData) {
    final theme = Theme.of(context);
    final event = importData.event;

    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.sm(context)),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    ResponsiveBorderRadius.sm(context),
                  ),
                ),
                child: Icon(
                  Icons.people,
                  color: theme.colorScheme.primary,
                  size: ResponsiveIconSize.base(context),
                ),
              ),
              SizedBox(width: ResponsiveSpacing.md(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '协作事件',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.sm(context),
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${importData.ownerDisplayName} 邀请你共同关注',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.sm(context),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSpacing.md(context)),
          Text(
            event.title,
            style: TextStyle(
              fontSize: ResponsiveFontSize.lg(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveSpacing.xs(context)),
          Text(
            '${event.targetDate.year}-${event.targetDate.month.toString().padLeft(2, '0')}-${event.targetDate.day.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: ResponsiveFontSize.sm(context),
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyGroupPreview(BuildContext context, FamilyGroupInviteData inviteData) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.sm(context)),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveBorderRadius.sm(context),
                  ),
                ),
                child: Icon(
                  Icons.family_restroom,
                  color: Colors.green,
                  size: ResponsiveIconSize.base(context),
                ),
              ),
              SizedBox(width: ResponsiveSpacing.md(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inviteData.groupName,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.lg(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${inviteData.inviterDisplayName} 邀请你加入家庭共享',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.sm(context),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSpacing.md(context)),
          Row(
            children: [
              Icon(
                Icons.event,
                size: ResponsiveIconSize.sm(context),
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: ResponsiveSpacing.sm(context)),
              Text(
                '${inviteData.eventCount} 个共享事件',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.sm(context),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultActions(BuildContext context) {
    if (_scanResult == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetScanner,
            child: const Text('继续扫描'),
          ),
        ),
        SizedBox(width: ResponsiveSpacing.md(context)),
        Expanded(
          child: FilledButton(
            onPressed: () => _importResult(context),
            child: Text(_getImportButtonText()),
          ),
        ),
      ],
    );
  }

  String _getImportButtonText() {
    if (_scanResult == null) return '导入';

    switch (_scanResult!.type) {
      case QRDataType.singleEvent:
        return '导入事件';
      case QRDataType.multipleEvents:
        return '全部导入';
      case QRDataType.sharedEvent:
        return '加入协作';
      case QRDataType.familyGroup:
        return '加入家庭';
    }
  }

  Future<void> _importResult(BuildContext context) async {
    if (_scanResult == null) return;

    final provider = context.read<EventsProvider>();

    try {
      switch (_scanResult!.type) {
        case QRDataType.singleEvent:
          final event = _scanResult!.data as CountdownEvent;
          await provider.insertEvent(event);
          break;

        case QRDataType.multipleEvents:
          final events = _scanResult!.data as List<CountdownEvent>;
          for (final event in events) {
            await provider.insertEvent(event);
          }
          break;

        case QRDataType.sharedEvent:
          // TODO: 实现共享事件加入逻辑
          final importData = _scanResult!.data as SharedEventImportData;
          await provider.insertEvent(importData.event);
          break;

        case QRDataType.familyGroup:
          // TODO: 实现家庭组加入逻辑
          break;
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getSuccessMessage())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  String _getSuccessMessage() {
    if (_scanResult == null) return '导入成功';

    switch (_scanResult!.type) {
      case QRDataType.singleEvent:
        return '事件导入成功';
      case QRDataType.multipleEvents:
        return '批量导入成功';
      case QRDataType.sharedEvent:
        return '已加入协作';
      case QRDataType.familyGroup:
        return '已加入家庭';
    }
  }

  Future<void> _pickFromGallery() async {
    // TODO: 实现从相册选择二维码图片
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('功能开发中')),
    );
  }
}

/// 打开QR扫描器
Future<bool?> openQRScanner(BuildContext context) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) => const QRScannerScreen(),
    ),
  );
}
