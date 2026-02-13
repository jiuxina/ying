import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/app_exception.dart';
import 'database_service.dart';

/// 备份服务
///
/// 提供数据备份和恢复功能，支持导出为 JSON 文件和从 JSON 文件恢复数据。
class BackupService {
  final DatabaseService _dbService = DatabaseService();

  /// 创建备份文件并分享
  ///
  /// 导出所有数据为 JSON 格式，生成带时间戳的备份文件并通过系统分享功能分享。
  /// 备份文件命名格式：`ying_backup_yyyyMMdd_HHmm.json`
  ///
  /// 抛出：
  /// - [FileSystemException] 如果文件创建失败
  /// - [AppException] 如果备份过程中发生其他错误
  Future<void> createBackup() async {
    try {
      final data = await _dbService.exportAllData();
      // Pretty print json
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'ying_backup_$timestamp.json';
      final file = File('${dir.path}/$fileName');

      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(file.path)], text: 'Ying Data Backup');
    } on FileSystemException catch (e) {
      debugPrint('Failed to create backup file: $e');
      throw FileSystemException('无法创建备份文件', originalException: e);
    } catch (e) {
      debugPrint('Backup creation failed: $e');
      throw AppException('备份创建失败', originalException: e);
    }
  }

  /// 从备份文件恢复数据
  ///
  /// 允许用户选择 JSON 格式的备份文件，验证文件格式后恢复数据。
  ///
  /// 返回：
  /// - `true` 如果恢复成功
  /// - `false` 如果用户取消选择
  ///
  /// 抛出：
  /// - [ValidationException] 如果备份文件格式无效
  /// - [FileSystemException] 如果文件不存在或无法读取
  /// - [AppException] 如果恢复过程中发生其他错误
  Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final filePath = result.files.single.path!;

      // Validate file extension
      if (!filePath.toLowerCase().endsWith('.json')) {
        throw ValidationException('文件格式错误，请选择.json文件');
      }

      final file = File(filePath);

      // Check file exists and is readable
      if (!await file.exists()) {
        throw FileSystemException('文件不存在');
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      // Validate backup data structure
      if (data is! Map<String, dynamic>) {
        throw ValidationException('备份文件格式无效');
      }

      if (!data.containsKey('version') || !data.containsKey('events')) {
        throw ValidationException('备份文件缺少必要字段');
      }

      await _dbService.importAllData(data);
      return true;
    } on ValidationException {
      rethrow;
    } on FileSystemException {
      rethrow;
    } on FormatException catch (e) {
      debugPrint('JSON parsing failed: $e');
      throw ValidationException('备份文件格式错误，无法解析JSON');
    } catch (e) {
      debugPrint('Restore failed: $e');
      throw AppException('恢复备份失败', originalException: e);
    }
  }
}
