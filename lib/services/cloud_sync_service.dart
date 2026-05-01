// ============================================================================
// 云同步服务
// 
// 协调本地事件数据与 WebDAV 远程服务器的同步
// 支持冲突检测和智能合并策略
// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'webdav_service.dart';

/// 同步状态枚举
enum SyncStatus {
  idle,       // 空闲
  syncing,    // 同步中
  success,    // 成功
  error,      // 错误
  conflict,   // 冲突需要用户决定
}

/// 冲突类型
enum ConflictType {
  none,           // 无冲突
  localNewer,     // 本地更新
  remoteNewer,    // 远程更新
  bothModified,   // 双方都有修改
}

/// 同步结果
class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final String? errorMessage;
  final ConflictType? conflictType;
  final DateTime? localModifiedTime;
  final DateTime? remoteModifiedTime;
  
  const SyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.errorMessage,
    this.conflictType,
    this.localModifiedTime,
    this.remoteModifiedTime,
  });
  
  factory SyncResult.failed(String message) {
    return SyncResult(success: false, errorMessage: message);
  }
  
  factory SyncResult.empty() {
    return const SyncResult(success: true);
  }
  
  factory SyncResult.conflict({
    required ConflictType conflictType,
    required DateTime localTime,
    required DateTime remoteTime,
  }) {
    return SyncResult(
      success: false,
      conflictType: conflictType,
      localModifiedTime: localTime,
      remoteModifiedTime: remoteTime,
    );
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
  
  /// 获取本地数据库最后修改时间
  Future<DateTime?> _getLocalModifiedTime() async {
    try {
      final dbPath = await _getDatabasePath();
      final file = File(dbPath);
      if (!await file.exists()) {
        return null;
      }
      
      // 尝试从数据库元数据获取最后更新时间
      final db = await openDatabase(dbPath);
      try {
        // 查询所有事件的最后更新时间，取最大值
        final result = await db.rawQuery(
          'SELECT MAX(updatedAt) as maxUpdatedAt FROM countdown_events'
        );
        
        if (result.isNotEmpty && result.first['maxUpdatedAt'] != null) {
          final timestamp = result.first['maxUpdatedAt'] as int;
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      } finally {
        await db.close();
      }
      
      // 如果数据库没有数据，使用文件修改时间
      return await file.lastModified();
    } catch (e) {
      debugPrint('获取本地修改时间失败: $e');
      return null;
    }
  }
  
  /// 获取远程数据库的修改时间
  Future<DateTime?> _getRemoteModifiedTime() async {
    try {
      final files = await _webdavService.listRemoteFiles();
      if (files == null || files.isEmpty) {
        return null;
      }
      
      final dbFile = files.cast<dynamic>().firstWhere(
        (f) => f.toString().contains('events.db'),
        orElse: () => null,
      );
      
      if (dbFile == null) {
        return null;
      }
      
      // WebDAV 通常会在文件列表中返回修改时间
      // 这里我们尝试下载文件头来获取信息
      // 简化版：假设远程文件存在则返回当前时间
      // 实际实现需要 WebDAV 服务支持获取文件元数据
      return DateTime.now(); // 占位符，实际应从 WebDAV 获取
    } catch (e) {
      debugPrint('获取远程修改时间失败: $e');
      return null;
    }
  }
  
  /// 检测冲突
  Future<ConflictType> _detectConflict() async {
    final localTime = await _getLocalModifiedTime();
    final remoteTime = await _getRemoteModifiedTime();
    
    // 如果本地或远程不存在，无冲突
    if (localTime == null || remoteTime == null) {
      return ConflictType.none;
    }
    
    // 检查远程文件是否存在
    try {
      final files = await _webdavService.listRemoteFiles();
      final hasRemote = files?.any((f) => f.toString().contains('events.db')) ?? false;
      
      if (!hasRemote) {
        // 远程不存在，直接上传
        return ConflictType.none;
      }
    } catch (e) {
      debugPrint('检查远程文件失败: $e');
    }
    
    // 简单冲突检测：比较最后修改时间
    // 如果相差超过1分钟，认为有冲突
    final diff = localTime.difference(remoteTime).abs();
    if (diff.inMinutes <= 1) {
      // 时间接近，假设无冲突
      return ConflictType.none;
    }
    
    if (localTime.isAfter(remoteTime)) {
      return ConflictType.localNewer;
    } else {
      return ConflictType.remoteNewer;
    }
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
      
      // 上传前先备份远程文件（如果存在）
      try {
        final files = await _webdavService.listRemoteFiles();
        if (files?.any((f) => f.toString().contains('events.db')) ?? false) {
          // 下载远程文件作为备份
          final backupPath = '$dbPath.remote_backup';
          await _webdavService.downloadFile('events.db', backupPath);
          debugPrint('已备份远程数据库');
        }
      } catch (e) {
        debugPrint('备份远程文件失败（继续上传）: $e');
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
  
  /// 执行恢复（带冲突检测）
  /// [force] 强制恢复，忽略冲突
  Future<SyncResult> restore({bool force = false}) async {
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
      
      // 检查远程文件是否存在
      final files = await _webdavService.listRemoteFiles();
      if (!(files?.any((f) => f.toString().contains('events.db')) ?? false)) {
        _setStatus(SyncStatus.error);
        return SyncResult.failed('远程数据库不存在');
      }
      
      // 冲突检测（除非强制恢复）
      if (!force) {
        final conflictType = await _detectConflict();
        final localTime = await _getLocalModifiedTime();
        final remoteTime = await _getRemoteModifiedTime();
        
        if (conflictType == ConflictType.bothModified || 
            conflictType == ConflictType.localNewer) {
          _setStatus(SyncStatus.conflict);
          return SyncResult.conflict(
            conflictType: conflictType,
            localTime: localTime ?? DateTime.now(),
            remoteTime: remoteTime ?? DateTime.now(),
          );
        }
      }
      
      // 下载数据库文件
      final dbPath = await _getDatabasePath();
      
      // 备份本地数据库
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.copy('$dbPath.backup');
        debugPrint('已备份本地数据库');
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
  
  /// 强制恢复（忽略冲突，覆盖本地）
  Future<SyncResult> forceRestore() async {
    return restore(force: true);
  }
  
  /// 智能同步（双向同步）
  /// 自动选择最新的数据
  Future<SyncResult> smartSync() async {
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
      
      // 检测冲突
      final conflictType = await _detectConflict();
      
      switch (conflictType) {
        case ConflictType.none:
        case ConflictType.localNewer:
          // 本地更新或无冲突，上传本地数据
          return await backup();
          
        case ConflictType.remoteNewer:
          // 远程更新，下载远程数据
          return await restore(force: true);
          
        case ConflictType.bothModified:
          // 双方都有修改，返回冲突让用户决定
          final localTime = await _getLocalModifiedTime();
          final remoteTime = await _getRemoteModifiedTime();
          _setStatus(SyncStatus.conflict);
          return SyncResult.conflict(
            conflictType: conflictType,
            localTime: localTime ?? DateTime.now(),
            remoteTime: remoteTime ?? DateTime.now(),
          );
      }
    } catch (e) {
      debugPrint('CloudSync 智能同步失败: $e');
      _setStatus(SyncStatus.error);
      return SyncResult.failed('同步失败: $e');
    }
  }
  
  // ==================== 私有方法 ====================
  
  void _setStatus(SyncStatus status) {
    _status = status;
    statusNotifier.value = status;
  }
}
