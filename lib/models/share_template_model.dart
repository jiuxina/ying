/// 分享卡片模板模型
class ShareTemplate {
  final String id;
  final String name;
  final ShareTemplateStyle style;
  final ShareTemplateAspectRatio aspectRatio;
  final ShareTemplateTheme theme;

  const ShareTemplate({
    required this.id,
    required this.name,
    required this.style,
    this.aspectRatio = ShareTemplateAspectRatio.square,
    this.theme = ShareTemplateTheme.light,
  });

  /// 预设模板列表
  static const List<ShareTemplate> presets = [
    ShareTemplate(
      id: 'minimal',
      name: '极简',
      style: ShareTemplateStyle.minimal,
      theme: ShareTemplateTheme.light,
    ),
    ShareTemplate(
      id: 'gradient',
      name: '渐变',
      style: ShareTemplateStyle.gradient,
      theme: ShareTemplateTheme.colorful,
    ),
    ShareTemplate(
      id: 'dark',
      name: '暗黑',
      style: ShareTemplateStyle.minimal,
      theme: ShareTemplateTheme.dark,
    ),
    ShareTemplate(
      id: 'card',
      name: '卡片',
      style: ShareTemplateStyle.card,
      theme: ShareTemplateTheme.light,
    ),
    ShareTemplate(
      id: 'festive',
      name: '节日',
      style: ShareTemplateStyle.festive,
      theme: ShareTemplateTheme.colorful,
    ),
    ShareTemplate(
      id: 'poster',
      name: '海报',
      style: ShareTemplateStyle.poster,
      aspectRatio: ShareTemplateAspectRatio.portrait,
      theme: ShareTemplateTheme.light,
    ),
  ];
}

/// 模板样式
enum ShareTemplateStyle {
  minimal,   // 极简
  gradient,  // 渐变
  card,      // 卡片
  festive,   // 节日
  poster,    // 海报
}

/// 模板宽高比
enum ShareTemplateAspectRatio {
  square,    // 1:1 (适合微信朋友圈)
  portrait,  // 3:4 (适合小红书)
  landscape, // 16:9 (适合微博)
}

/// 模板主题
enum ShareTemplateTheme {
  light,
  dark,
  colorful,
}

/// 分享平台
enum SharePlatform {
  general,   // 通用分享
  wechat,    // 微信
  weibo,     // 微博
  xiaohongshu, // 小红书
  qq,        // QQ
}

extension SharePlatformExtension on SharePlatform {
  String get displayName {
    switch (this) {
      case SharePlatform.general:
        return '分享';
      case SharePlatform.wechat:
        return '微信';
      case SharePlatform.weibo:
        return '微博';
      case SharePlatform.xiaohongshu:
        return '小红书';
      case SharePlatform.qq:
        return 'QQ';
    }
  }

  String get iconAsset {
    switch (this) {
      case SharePlatform.general:
        return 'share';
      case SharePlatform.wechat:
        return 'wechat';
      case SharePlatform.weibo:
        return 'weibo';
      case SharePlatform.xiaohongshu:
        return 'xiaohongshu';
      case SharePlatform.qq:
        return 'qq';
    }
  }

  /// 推荐的宽高比
  ShareTemplateAspectRatio get recommendedAspectRatio {
    switch (this) {
      case SharePlatform.xiaohongshu:
        return ShareTemplateAspectRatio.portrait;
      case SharePlatform.weibo:
        return ShareTemplateAspectRatio.landscape;
      default:
        return ShareTemplateAspectRatio.square;
    }
  }
}

extension ShareTemplateAspectRatioExtension on ShareTemplateAspectRatio {
  double get value {
    switch (this) {
      case ShareTemplateAspectRatio.square:
        return 1.0;
      case ShareTemplateAspectRatio.portrait:
        return 3 / 4;
      case ShareTemplateAspectRatio.landscape:
        return 16 / 9;
    }
  }

  String get displayName {
    switch (this) {
      case ShareTemplateAspectRatio.square:
        return '1:1';
      case ShareTemplateAspectRatio.portrait:
        return '3:4';
      case ShareTemplateAspectRatio.landscape:
        return '16:9';
    }
  }
}
