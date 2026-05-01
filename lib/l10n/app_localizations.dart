import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用名称
  ///
  /// In zh, this message translates to:
  /// **'萤'**
  String get appName;

  /// 取消按钮
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// 确认按钮
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// 保存按钮
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// 删除按钮
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// 编辑按钮
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// 搜索
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// 设置
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// 关于
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// 版本
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version;

  /// 天数单位
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get days;

  /// 小时单位
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get hours;

  /// 分钟单位
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get minutes;

  /// 秒单位
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get seconds;

  /// 添加事件
  ///
  /// In zh, this message translates to:
  /// **'添加事件'**
  String get addEvent;

  /// 编辑事件
  ///
  /// In zh, this message translates to:
  /// **'编辑事件'**
  String get editEvent;

  /// 删除事件
  ///
  /// In zh, this message translates to:
  /// **'删除事件'**
  String get deleteEvent;

  /// 事件名称
  ///
  /// In zh, this message translates to:
  /// **'事件名称'**
  String get eventTitle;

  /// 事件日期
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get eventDate;

  /// 事件分类
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get eventCategory;

  /// 事件备注
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get eventNote;

  /// 每年重复
  ///
  /// In zh, this message translates to:
  /// **'每年重复'**
  String get repeatYearly;

  /// 每月重复
  ///
  /// In zh, this message translates to:
  /// **'每月重复'**
  String get repeatMonthly;

  /// 农历日期
  ///
  /// In zh, this message translates to:
  /// **'农历'**
  String get lunarDate;

  /// 公历日期
  ///
  /// In zh, this message translates to:
  /// **'公历'**
  String get solarDate;

  /// 云端同步
  ///
  /// In zh, this message translates to:
  /// **'云端同步'**
  String get cloudSync;

  /// 立即同步
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get syncNow;

  /// 自动同步
  ///
  /// In zh, this message translates to:
  /// **'自动同步'**
  String get autoSync;

  /// 同步成功
  ///
  /// In zh, this message translates to:
  /// **'同步成功'**
  String get syncSuccess;

  /// 同步失败
  ///
  /// In zh, this message translates to:
  /// **'同步失败'**
  String get syncFailed;

  /// 导出数据
  ///
  /// In zh, this message translates to:
  /// **'导出数据'**
  String get exportData;

  /// 导入数据
  ///
  /// In zh, this message translates to:
  /// **'导入数据'**
  String get importData;

  /// 分享
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// 分享卡片
  ///
  /// In zh, this message translates to:
  /// **'分享卡片'**
  String get shareCard;

  /// 保存到相册
  ///
  /// In zh, this message translates to:
  /// **'保存到相册'**
  String get saveToAlbum;

  /// 保存成功
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get savedSuccess;

  /// 主题
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// 深色模式
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// 浅色模式
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get lightMode;

  /// 跟随系统
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get systemMode;

  /// 主题色
  ///
  /// In zh, this message translates to:
  /// **'主题色'**
  String get themeColor;

  /// 批量删除
  ///
  /// In zh, this message translates to:
  /// **'批量删除'**
  String get batchDelete;

  /// 批量归档
  ///
  /// In zh, this message translates to:
  /// **'批量归档'**
  String get batchArchive;

  /// 批量更改分类
  ///
  /// In zh, this message translates to:
  /// **'批量更改分类'**
  String get batchChangeCategory;

  /// 批量导出
  ///
  /// In zh, this message translates to:
  /// **'批量导出'**
  String get batchExport;

  /// 全选
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get selectAll;

  /// 取消全选
  ///
  /// In zh, this message translates to:
  /// **'取消全选'**
  String get deselectAll;

  /// 反选
  ///
  /// In zh, this message translates to:
  /// **'反选'**
  String get invertSelection;

  /// 已选择事件数量
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 个事件'**
  String selectedCount(int count);

  /// 已删除事件数量
  ///
  /// In zh, this message translates to:
  /// **'已删除 {count} 个事件'**
  String deletedCount(int count);

  /// 已归档事件数量
  ///
  /// In zh, this message translates to:
  /// **'已归档 {count} 个事件'**
  String archivedCount(int count);

  /// 撤销
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get undo;

  /// 撤销成功
  ///
  /// In zh, this message translates to:
  /// **'已撤销操作'**
  String get undoSuccess;

  /// 没有选中任何事件
  ///
  /// In zh, this message translates to:
  /// **'没有选中任何事件'**
  String get noEventsSelected;

  /// 更改分类
  ///
  /// In zh, this message translates to:
  /// **'更改分类'**
  String get changeCategory;

  /// 将选中的事件移至
  ///
  /// In zh, this message translates to:
  /// **'将选中的事件移至：'**
  String get moveToCategory;

  /// 外观设置
  ///
  /// In zh, this message translates to:
  /// **'外观设置'**
  String get appearanceSettings;

  /// 主题设置
  ///
  /// In zh, this message translates to:
  /// **'主题设置'**
  String get themeSettings;

  /// 背景设置
  ///
  /// In zh, this message translates to:
  /// **'背景设置'**
  String get backgroundSettings;

  /// 其他设置
  ///
  /// In zh, this message translates to:
  /// **'其他设置'**
  String get otherSettings;

  /// 主题模式
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// 浅色主题
  ///
  /// In zh, this message translates to:
  /// **'浅色主题'**
  String get lightTheme;

  /// 深色主题
  ///
  /// In zh, this message translates to:
  /// **'深色主题'**
  String get darkTheme;

  /// 语言
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// 界面字体颜色
  ///
  /// In zh, this message translates to:
  /// **'界面字体颜色'**
  String get uiFontColor;

  /// 自定义颜色
  ///
  /// In zh, this message translates to:
  /// **'自定义颜色'**
  String get customColor;

  /// 自适应渐变色
  ///
  /// In zh, this message translates to:
  /// **'自适应渐变色'**
  String get adaptiveGradient;

  /// 根据背景自动调整文字颜色
  ///
  /// In zh, this message translates to:
  /// **'根据背景自动调整文字颜色'**
  String get adaptiveGradientDesc;

  /// 按钮样式
  ///
  /// In zh, this message translates to:
  /// **'按钮样式'**
  String get buttonStyle;

  /// 经典描边
  ///
  /// In zh, this message translates to:
  /// **'经典描边'**
  String get buttonStyleClassic;

  /// 简洁立体
  ///
  /// In zh, this message translates to:
  /// **'简洁立体'**
  String get buttonStyleModern;

  /// 经典的边框按钮风格
  ///
  /// In zh, this message translates to:
  /// **'经典的边框按钮风格'**
  String get buttonStyleClassicDesc;

  /// 现代的阴影按钮风格
  ///
  /// In zh, this message translates to:
  /// **'现代的阴影按钮风格'**
  String get buttonStyleModernDesc;

  /// 卡片透明度
  ///
  /// In zh, this message translates to:
  /// **'卡片透明度'**
  String get cardOpacity;

  /// 底部导航栏透明度
  ///
  /// In zh, this message translates to:
  /// **'底部导航栏透明度'**
  String get bottomNavOpacity;

  /// 透明度
  ///
  /// In zh, this message translates to:
  /// **'透明度'**
  String get opacity;

  /// 背景
  ///
  /// In zh, this message translates to:
  /// **'背景'**
  String get background;

  /// 选择图片
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get selectImage;

  /// 移除背景
  ///
  /// In zh, this message translates to:
  /// **'移除背景'**
  String get clearBackground;

  /// 模糊效果
  ///
  /// In zh, this message translates to:
  /// **'模糊效果'**
  String get blurEffect;

  /// 模糊强度
  ///
  /// In zh, this message translates to:
  /// **'模糊强度'**
  String get blurStrength;

  /// 亮度
  ///
  /// In zh, this message translates to:
  /// **'亮度'**
  String get brightness;

  /// 粒子效果
  ///
  /// In zh, this message translates to:
  /// **'粒子效果'**
  String get particleEffect;

  /// 粒子类型
  ///
  /// In zh, this message translates to:
  /// **'粒子类型'**
  String get particleType;

  /// 粒子速率
  ///
  /// In zh, this message translates to:
  /// **'粒子速率'**
  String get particleSpeed;

  /// 关闭
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get off;

  /// 樱花
  ///
  /// In zh, this message translates to:
  /// **'樱花'**
  String get particleSakura;

  /// 雨滴
  ///
  /// In zh, this message translates to:
  /// **'雨滴'**
  String get particleRain;

  /// 萤火虫
  ///
  /// In zh, this message translates to:
  /// **'萤火虫'**
  String get particleFirefly;

  /// 雪花
  ///
  /// In zh, this message translates to:
  /// **'雪花'**
  String get particleSnow;

  /// 预览
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// 预览文字
  ///
  /// In zh, this message translates to:
  /// **'预览文字'**
  String get previewText;

  /// 选择颜色
  ///
  /// In zh, this message translates to:
  /// **'选择颜色'**
  String get selectColor;

  /// 已设置
  ///
  /// In zh, this message translates to:
  /// **'已设置'**
  String get alreadySet;

  /// 使用默认渐变
  ///
  /// In zh, this message translates to:
  /// **'使用默认渐变'**
  String get useDefaultGradient;

  /// 浅色
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get light;

  /// 深色
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get dark;

  /// 跟随系统
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// 主题设置副标题
  ///
  /// In zh, this message translates to:
  /// **'主题模式、主题色、界面字体颜色、按钮样式'**
  String get themeSettingsSubtitle;

  /// 背景设置副标题
  ///
  /// In zh, this message translates to:
  /// **'背景图片、模糊效果、粒子特效'**
  String get backgroundSettingsSubtitle;

  /// 其他外观设置副标题
  ///
  /// In zh, this message translates to:
  /// **'底部导航栏透明度、卡片透明度'**
  String get otherSettingsSubtitle;

  /// 或使用传统视图
  ///
  /// In zh, this message translates to:
  /// **'或使用传统视图'**
  String get orUseClassicView;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
