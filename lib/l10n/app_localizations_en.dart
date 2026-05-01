// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Ying';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get days => 'days';

  @override
  String get hours => 'hours';

  @override
  String get minutes => 'minutes';

  @override
  String get seconds => 'seconds';

  @override
  String get addEvent => 'Add Event';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get deleteEvent => 'Delete Event';

  @override
  String get eventTitle => 'Event Title';

  @override
  String get eventDate => 'Date';

  @override
  String get eventCategory => 'Category';

  @override
  String get eventNote => 'Note';

  @override
  String get repeatYearly => 'Repeat Yearly';

  @override
  String get repeatMonthly => 'Repeat Monthly';

  @override
  String get lunarDate => 'Lunar';

  @override
  String get solarDate => 'Solar';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get autoSync => 'Auto Sync';

  @override
  String get syncSuccess => 'Sync Successful';

  @override
  String get syncFailed => 'Sync Failed';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get share => 'Share';

  @override
  String get shareCard => 'Share Card';

  @override
  String get saveToAlbum => 'Save to Album';

  @override
  String get savedSuccess => 'Saved Successfully';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System';

  @override
  String get themeColor => 'Theme Color';

  @override
  String get batchDelete => 'Batch Delete';

  @override
  String get batchArchive => 'Batch Archive';

  @override
  String get batchChangeCategory => 'Batch Change Category';

  @override
  String get batchExport => 'Batch Export';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get invertSelection => 'Invert Selection';

  @override
  String selectedCount(int count) {
    return '$count events selected';
  }

  @override
  String deletedCount(int count) {
    return '$count events deleted';
  }

  @override
  String archivedCount(int count) {
    return '$count events archived';
  }

  @override
  String get undo => 'Undo';

  @override
  String get undoSuccess => 'Operation undone';

  @override
  String get noEventsSelected => 'No events selected';

  @override
  String get changeCategory => 'Change Category';

  @override
  String get moveToCategory => 'Move selected events to:';

  @override
  String get appearanceSettings => 'Appearance';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get backgroundSettings => 'Background Settings';

  @override
  String get otherSettings => 'Other Settings';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get language => 'Language';

  @override
  String get uiFontColor => 'UI Font Color';

  @override
  String get customColor => 'Custom Color';

  @override
  String get adaptiveGradient => 'Adaptive Gradient';

  @override
  String get adaptiveGradientDesc =>
      'Automatically adjust text color based on background';

  @override
  String get buttonStyle => 'Button Style';

  @override
  String get buttonStyleClassic => 'Classic';

  @override
  String get buttonStyleModern => 'Modern';

  @override
  String get buttonStyleClassicDesc => 'Classic bordered button style';

  @override
  String get buttonStyleModernDesc => 'Modern shadow button style';

  @override
  String get cardOpacity => 'Card Opacity';

  @override
  String get bottomNavOpacity => 'Bottom Navigation Opacity';

  @override
  String get opacity => 'Opacity';

  @override
  String get background => 'Background';

  @override
  String get selectImage => 'Select Image';

  @override
  String get clearBackground => 'Remove Background';

  @override
  String get blurEffect => 'Blur Effect';

  @override
  String get blurStrength => 'Blur Strength';

  @override
  String get brightness => 'Brightness';

  @override
  String get particleEffect => 'Particle Effect';

  @override
  String get particleType => 'Particle Type';

  @override
  String get particleSpeed => 'Particle Speed';

  @override
  String get off => 'Off';

  @override
  String get particleSakura => 'Sakura';

  @override
  String get particleRain => 'Rain';

  @override
  String get particleFirefly => 'Firefly';

  @override
  String get particleSnow => 'Snow';

  @override
  String get preview => 'Preview';

  @override
  String get previewText => 'Preview Text';

  @override
  String get selectColor => 'Select Color';

  @override
  String get alreadySet => 'Set';

  @override
  String get useDefaultGradient => 'Use Default Gradient';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get followSystem => 'Follow System';

  @override
  String get themeSettingsSubtitle =>
      'Theme mode, theme color, UI font color, button style';

  @override
  String get backgroundSettingsSubtitle =>
      'Background image, blur effect, particle effect';

  @override
  String get otherSettingsSubtitle => 'Bottom navigation opacity, card opacity';

  @override
  String get orUseClassicView => 'Or use classic view';
}
