// ============================================================================
// 云同步服务
// 
// 协调本地事件数据与 WebDAV 远程服务器的同步
// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'webdav_service.dart';

/// 同步状态枚举
enum SyncStatus {
  idle,       // 空闲
  syncing,    // 同步中
  success,    // 成功
  error,      // 错误
}

/// 同步结果
class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final String? errorMessage;
  
  const SyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.errorMessage,
  });
  
  factory SyncResult.failed(String message) {
    return SyncResult(success: false, errorMessage: message);
  }
  
  factory SyncResult.empty() {
    return const SyncResult(success: true);
  }
}

/// 云同步服务类
class CloudSyncService {
  final WebDAVService _webdavService;
  
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;
  
  /// 同步状态变化回调
  ValueNotifier<SyncStatus> statusNotifier = ValueNotifier(SyncStatus.idle);
  
  CloudSyncService({
    required WebDAVService webdavService,
  }) : _webdavService = webdavService;
  
  /// 获取本地数据库路径
  Future<String> _getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/events.db';
  }
  
  /// 执行备份
  Future<SyncResult> backup() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult.failed('同步进行中，请稍候');
    }
    
    _setStatus(SyncStatus.syncing);
    
    try {
      // 测试连接
      if (!await _webdavService.testConnection()) {
        _setStatus(SyncStatus.error);
        return SyncResult.failed('无法连接到 WebDAV 服务器');
      }
      
      // 确保远程工作区存在
      await _webdavService.ensureRemoteWorkspace();
      
      // 上传数据库文件
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        _setStatus(SyncStatus.error);
        return SyncResult.failed('本地数据库不存在');
      }
      
      final success = await _webdavService.uploadFile(dbPath, 'events.db');
      
      if (success) {
        _setStatus(SyncStatus.success);
        return const SyncResult(success: true, uploadedCount: 1);
      } else {
        _setStatus(SyncStatus.error);
        return SyncResult.failed('上传数据库失败');
      }
    } catch (e) {
      debugPrint('CloudSync 备份失败: $e');
      _setStatus(SyncStatus.error);
      return SyncResult.failed('备份失败: $e');
    }
  }
  
  /// 执行恢复
  Future<SyncResult> restore() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult.failed('同步进行中，请稍候');
    }
    
    _setStatus(SyncStatus.syncing);
    
    try {
      // 测试连接
      if (!await _webdavService.testConnection()) {
        _setStatus(SyncStatus.error);
        return SyncResult.failed('无法连接到 WebDAV 服务器');
      }
      
      // 下载数据库文件
      final dbPath = await _getDatabasePath();
      
      // 备份本地数据库
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.copy('$dbPath.backup');
      }
      
      final success = await _webdavService.downloadFile('events.db', dbPath);
      
      if (success) {
        _setStatus(SyncStatus.success);
        return const SyncResult(success: true, downloadedCount: 1);
      } else {
        // 恢复备份
        final backupFile = File('$dbPath.backup');
        if (await backupFile.exists()) {
          await backupFile.copy(dbPath);
        }
        _setStatus(SyncStatus.error);
        return SyncResult.failed('下载数据库失败');
      }
    } catch (e) {
      debugPrint('CloudSync 恢复失败: $e');
      _setStatus(SyncStatus.error);
      return SyncResult.failed('恢复失败: $e');
    }
  }
  
  // ==================== 私有方法 ====================
  
  void _setStatus(SyncStatus status) {
    _status = status;
    statusNotifier.value = status;
  }
}
