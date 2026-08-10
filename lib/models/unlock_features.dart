import 'app_settings.dart';
import 'widget_element_style.dart';

/// 需要赞助解锁的小部件样式。
const sponsorWidgetStyles = <WidgetStyle>{
  WidgetStyle.envelope,
  WidgetStyle.capsule,
  WidgetStyle.crt,
  WidgetStyle.neonSign,
  WidgetStyle.pixelHealth,
  WidgetStyle.mirror,
};

/// 未解锁时把赞助相关设置强制回退为免费默认值。
AppSettings sanitizeSponsorSettings(AppSettings settings) {
  var result = settings;
  if (sponsorWidgetStyles.contains(result.widgetStyle)) {
    result = result.copyWith(widgetStyle: WidgetStyle.card);
  }
  if (result.widgetMysteryMode) {
    result = result.copyWith(widgetMysteryMode: false);
  }
  if (result.widgetQuoteMode) {
    result = result.copyWith(widgetQuoteMode: false);
  }
  if (result.widgetFontFamily != 'system') {
    result = result.copyWith(widgetFontFamily: 'system');
  }
  if (result.widgetTextOutline) {
    result = result.copyWith(widgetTextOutline: false);
  }
  if (result.widgetWallpaperColor != -1 ||
      result.widgetWallpaperDarkColor != -1 ||
      result.widgetWallpaperTextColor != -1) {
    result = result.copyWith(
      widgetWallpaperColor: -1,
      widgetWallpaperDarkColor: -1,
      widgetWallpaperTextColor: -1,
    );
  }
  final needsVisibilityReset = result.widgetElementStyles.values.any(
    (style) => style.visible != WidgetElementVisible.follow,
  );
  if (needsVisibilityReset) {
    result = result.copyWith(
      widgetElementStyles: {
        for (final entry in result.widgetElementStyles.entries)
          entry.key: entry.value.copyWith(visible: WidgetElementVisible.follow),
      },
    );
  }
  return result;
}
