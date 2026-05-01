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
}
