// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '萤';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get search => '搜索';

  @override
  String get settings => '设置';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get days => '天';

  @override
  String get hours => '小时';

  @override
  String get minutes => '分钟';

  @override
  String get seconds => '秒';

  @override
  String get addEvent => '添加事件';

  @override
  String get editEvent => '编辑事件';

  @override
  String get deleteEvent => '删除事件';

  @override
  String get eventTitle => '事件名称';

  @override
  String get eventDate => '日期';

  @override
  String get eventCategory => '分类';

  @override
  String get eventNote => '备注';

  @override
  String get repeatYearly => '每年重复';

  @override
  String get repeatMonthly => '每月重复';

  @override
  String get lunarDate => '农历';

  @override
  String get solarDate => '公历';

  @override
  String get cloudSync => '云端同步';

  @override
  String get syncNow => '立即同步';

  @override
  String get autoSync => '自动同步';

  @override
  String get syncSuccess => '同步成功';

  @override
  String get syncFailed => '同步失败';

  @override
  String get exportData => '导出数据';

  @override
  String get importData => '导入数据';

  @override
  String get share => '分享';

  @override
  String get shareCard => '分享卡片';

  @override
  String get saveToAlbum => '保存到相册';

  @override
  String get savedSuccess => '保存成功';

  @override
  String get theme => '主题';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get systemMode => '跟随系统';

  @override
  String get themeColor => '主题色';

  @override
  String get batchDelete => '批量删除';

  @override
  String get batchArchive => '批量归档';

  @override
  String get batchChangeCategory => '批量更改分类';

  @override
  String get batchExport => '批量导出';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String get invertSelection => '反选';

  @override
  String selectedCount(int count) {
    return '已选择 $count 个事件';
  }

  @override
  String deletedCount(int count) {
    return '已删除 $count 个事件';
  }

  @override
  String archivedCount(int count) {
    return '已归档 $count 个事件';
  }

  @override
  String get undo => '撤销';

  @override
  String get undoSuccess => '已撤销操作';

  @override
  String get noEventsSelected => '没有选中任何事件';

  @override
  String get changeCategory => '更改分类';

  @override
  String get moveToCategory => '将选中的事件移至：';

  @override
  String get appearanceSettings => '外观设置';

  @override
  String get themeSettings => '主题设置';

  @override
  String get backgroundSettings => '背景设置';

  @override
  String get otherSettings => '其他设置';

  @override
  String get themeMode => '主题模式';

  @override
  String get lightTheme => '浅色主题';

  @override
  String get darkTheme => '深色主题';

  @override
  String get language => '语言';

  @override
  String get uiFontColor => '界面字体颜色';

  @override
  String get customColor => '自定义颜色';

  @override
  String get adaptiveGradient => '自适应渐变色';

  @override
  String get adaptiveGradientDesc => '根据背景自动调整文字颜色';

  @override
  String get buttonStyle => '按钮样式';

  @override
  String get buttonStyleClassic => '经典描边';

  @override
  String get buttonStyleModern => '简洁立体';

  @override
  String get buttonStyleClassicDesc => '经典的边框按钮风格';

  @override
  String get buttonStyleModernDesc => '现代的阴影按钮风格';

  @override
  String get cardOpacity => '卡片透明度';

  @override
  String get bottomNavOpacity => '底部导航栏透明度';

  @override
  String get opacity => '透明度';

  @override
  String get background => '背景';

  @override
  String get selectImage => '选择图片';

  @override
  String get clearBackground => '移除背景';

  @override
  String get blurEffect => '模糊效果';

  @override
  String get blurStrength => '模糊强度';

  @override
  String get brightness => '亮度';

  @override
  String get particleEffect => '粒子效果';

  @override
  String get particleType => '粒子类型';

  @override
  String get particleSpeed => '粒子速率';

  @override
  String get off => '关闭';

  @override
  String get particleSakura => '樱花';

  @override
  String get particleRain => '雨滴';

  @override
  String get particleFirefly => '萤火虫';

  @override
  String get particleSnow => '雪花';

  @override
  String get preview => '预览';

  @override
  String get previewText => '预览文字';

  @override
  String get selectColor => '选择颜色';

  @override
  String get alreadySet => '已设置';

  @override
  String get useDefaultGradient => '使用默认渐变';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get followSystem => '跟随系统';

  @override
  String get themeSettingsSubtitle => '主题模式、主题色、界面字体颜色、按钮样式';

  @override
  String get backgroundSettingsSubtitle => '背景图片、模糊效果、粒子特效';

  @override
  String get otherSettingsSubtitle => '底部导航栏透明度、卡片透明度';

  @override
  String get orUseClassicView => '或使用传统视图';
}
