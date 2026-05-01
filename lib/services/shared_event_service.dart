import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/countdown_event.dart';
import '../models/shared_event.dart';
import 'webdav_service.dart';
import 'database_service.dart';

/// 共享事件服务
/// 管理事件共享、协作和WebDAV同步
class SharedEventService {
  final WebDAVService _webdavService;
  final DatabaseService _databaseService;
  static const _uuid = Uuid();

  /// WebDAV共享目录名
  static const String _sharedDir = 'shared_events';
  static const String _familyGroupsDir = 'family_groups';
  static const String _metadataFile = 'metadata.json';

  /// 本地设备ID（缓存）
  String? _deviceId;
  String? _displayName;

  SharedEventService({
    required WebDAVService webdavService,
    required DatabaseService databaseService,
  })  : _webdavService = webdavService,
        _databaseService = databaseService;

  /// 初始化服务，获取或创建设备ID
  Future<void> initialize() async {
    // 从SharedPreferences获取设备ID
    // 如果不存在则创建新的
    // TODO: 实现设备ID持久化
  }

  /// 设置当前设备信息
  void setDeviceInfo(String deviceId, String displayName) {
    _deviceId = deviceId;
    _displayName = displayName;
  }

  String get _currentDeviceId => _deviceId ?? _uuid.v4();
  String get _currentDisplayName => _displayName ?? '用户';

  // ==================== 共享事件创建 ====================

  /// 创建共享事件
  Future<SharedEventMetadata> createSharedEvent({
    required CountdownEvent event,
    String? displayName,
  }) async {
    final shareId = _uuid.v4();
    final now = DateTime.now();

    final metadata = SharedEventMetadata(
      eventId: event.id,
      shareId: shareId,
      ownerDeviceId: _currentDeviceId,
      ownerDisplayName: displayName ?? _currentDisplayName,
      members: [
        SharedEventMember(
          id: _currentDeviceId,
          displayName: displayName ?? _currentDisplayName,
          permission: SharePermission.admin,
          joinedAt: now,
          lastSyncAt: now,
          isOwner: true,
        ),
      ],
      createdAt: now,
      updatedAt: now,
      version: 1,
    );

    // 保存到本地数据库
    await _saveSharedEventMetadataLocal(metadata);

    // 上传到WebDAV
    await _uploadSharedEventToWebDAV(event, metadata);

    return metadata;
  }

  /// 加入共享事件
  Future<SharedEventMetadata?> joinSharedEvent({
    required SharedEventImportData importData,
    String? displayName,
  }) async {
    try {
      // 检查是否已加入
      final existing = await _getSharedEventMetadataLocal(importData.shareId);
      if (existing != null) {
        return existing; // 已存在
      }

      final now = DateTime.now();

      // 创建新的成员记录
      final newMember = SharedEventMember(
        id: _currentDeviceId,
        displayName: displayName ?? _currentDisplayName,
        permission: importData.permission,
        joinedAt: now,
        lastSyncAt: now,
        isOwner: false,
      );

      // 从WebDAV获取最新的元数据
      final remoteMetadata = await _downloadSharedEventMetadata(importData.shareId);
      if (remoteMetadata == null) {
        return null; // 远程不存在
      }

      // 添加新成员
      final updatedMetadata = remoteMetadata.copyWith(
        members: [...remoteMetadata.members, newMember],
        updatedAt: now,
      );

      // 保存事件到本地
      await _databaseService.insertEvent(importData.event);

      // 保存元数据到本地
      await _saveSharedEventMetadataLocal(updatedMetadata);

      // 更新WebDAV上的成员列表
      await _uploadSharedEventMetadataToWebDAV(updatedMetadata);

      return updatedMetadata;
    } catch (e) {
      debugPrint('joinSharedEvent error: $e');
      return null;
    }
  }

  // ==================== 事件协作 ====================

  /// 更新共享事件
  Future<bool> updateSharedEvent({
    required String shareId,
    required CountdownEvent updatedEvent,
    required String deviceId,
  }) async {
    try {
      final metadata = await _getSharedEventMetadataLocal(shareId);
      if (metadata == null) return false;

      // 检查权限
      if (!metadata.hasPermission(deviceId, SharePermission.edit)) {
        return false;
      }

      // 更新本地数据库
      await _databaseService.updateEvent(updatedEvent);

      // 更新版本号
      final newMetadata = metadata.copyWith(
        updatedAt: DateTime.now(),
        version: metadata.version + 1,
      );
      await _saveSharedEventMetadataLocal(newMetadata);

      // 上传到WebDAV
      await _uploadSharedEventToWebDAV(updatedEvent, newMetadata);

      return true;
    } catch (e) {
      debugPrint('updateSharedEvent error: $e');
      return false;
    }
  }

  /// 同步共享事件更新
  Future<List<ConflictResult>> syncSharedEvent(String shareId) async {
    try {
      final localMetadata = await _getSharedEventMetadataLocal(shareId);
      if (localMetadata == null) return [];

      // 从WebDAV获取最新版本
      final remoteMetadata = await _downloadSharedEventMetadata(shareId);
      if (remoteMetadata == null) return [];

      // 检查版本差异
      if (remoteMetadata.version <= localMetadata.version) {
        return []; // 本地已是最新
      }

      // 检测冲突
      final conflicts = await _detectConflicts(localMetadata, remoteMetadata);

      if (conflicts.isEmpty) {
        // 无冲突，直接应用远程更新
        await _applyRemoteChanges(localMetadata, remoteMetadata);
      }

      return conflicts;
    } catch (e) {
      debugPrint('syncSharedEvent error: $e');
      return [];
    }
  }

  /// 解决冲突
  Future<bool> resolveConflict({
    required String shareId,
    required String field,
    required ConflictResolution resolution,
    dynamic customValue,
  }) async {
    try {
      final localMetadata = await _getSharedEventMetadataLocal(shareId);
      if (localMetadata == null) return false;

      // 根据策略应用解决
      // TODO: 实现冲突解决逻辑

      return true;
    } catch (e) {
      debugPrint('resolveConflict error: $e');
      return false;
    }
  }

  // ==================== 冲突检测 ====================

  /// 检测冲突
  Future<List<ConflictResult>> _detectConflicts(
    SharedEventMetadata local,
    SharedEventMetadata remote,
  ) async {
    final conflicts = <ConflictResult>[];

    // 简单版本检测：如果远程版本更新且时间更新，可能有冲突
    if (remote.version > local.version) {
      // 获取本地事件
      final events = await _databaseService.getAllEvents();
      final localEvent = events.where((e) => e.id == local.eventId).firstOrNull;

      if (localEvent != null && localEvent.updatedAt.isAfter(local.updatedAt)) {
        // 本地有未同步的修改
        conflicts.add(ConflictResult.conflict(
          field: 'event',
          localValue: localEvent,
          remoteValue: null,
          localTime: localEvent.updatedAt,
          remoteTime: remote.updatedAt,
          suggestedResolution: ConflictResolution.keepNewer,
        ));
      }
    }

    return conflicts;
  }

  /// 应用远程变更
  Future<void> _applyRemoteChanges(
    SharedEventMetadata local,
    SharedEventMetadata remote,
  ) async {
    // 更新本地元数据
    await _saveSharedEventMetadataLocal(remote);

    // 下载最新的事件数据
    final remoteEvent = await _downloadSharedEventData(remote.shareId);
    if (remoteEvent != null) {
      await _databaseService.updateEvent(remoteEvent);
    }
  }

  // ==================== 家庭共享组 ====================

  /// 创建家庭共享组
  Future<FamilyShareGroup> createFamilyGroup({
    required String name,
    required List<String> eventIds,
    String? displayName,
  }) async {
    final groupId = _uuid.v4();
    final now = DateTime.now();

    final group = FamilyShareGroup(
      id: groupId,
      name: name,
      ownerDeviceId: _currentDeviceId,
      ownerDisplayName: displayName ?? _currentDisplayName,
      members: [
        SharedEventMember(
          id: _currentDeviceId,
          displayName: displayName ?? _currentDisplayName,
          permission: SharePermission.admin,
          joinedAt: now,
          lastSyncAt: now,
          isOwner: true,
        ),
      ],
      sharedEventIds: eventIds,
      createdAt: now,
      updatedAt: now,
    );

    // 保存到本地
    await _saveFamilyGroupLocal(group);

    // 上传到WebDAV
    await _uploadFamilyGroupToWebDAV(group);

    // 为每个事件创建共享元数据
    for (final eventId in eventIds) {
      final events = await _databaseService.getAllEvents();
      final event = events.where((e) => e.id == eventId).firstOrNull;
      if (event != null) {
        await createSharedEvent(event: event, displayName: displayName);
      }
    }

    return group;
  }

  /// 加入家庭共享组
  Future<FamilyShareGroup?> joinFamilyGroup({
    required FamilyGroupInviteData inviteData,
    String? displayName,
  }) async {
    try {
      // 从WebDAV获取组信息
      final remoteGroup = await _downloadFamilyGroup(inviteData.groupId);
      if (remoteGroup == null) return null;

      final now = DateTime.now();

      // 添加新成员
      final newMember = SharedEventMember(
        id: _currentDeviceId,
        displayName: displayName ?? _currentDisplayName,
        permission: SharePermission.edit, // 家庭组成员默认可编辑
        joinedAt: now,
        lastSyncAt: now,
        isOwner: false,
      );

      final updatedGroup = remoteGroup.copyWith(
        members: [...remoteGroup.members, newMember],
        updatedAt: now,
      );

      // 保存到本地
      await _saveFamilyGroupLocal(updatedGroup);

      // 更新WebDAV
      await _uploadFamilyGroupToWebDAV(updatedGroup);

      // 下载所有共享事件
      for (final eventId in remoteGroup.sharedEventIds) {
        final metadata = await _downloadSharedEventMetadata(
          '$eventId-shared',
        );
        if (metadata != null) {
          final event = await _downloadSharedEventData(metadata.shareId);
          if (event != null) {
            await _databaseService.insertEvent(event);
            await _saveSharedEventMetadataLocal(metadata);
          }
        }
      }

      return updatedGroup;
    } catch (e) {
      debugPrint('joinFamilyGroup error: $e');
      return null;
    }
  }

  /// 同步家庭组
  Future<void> syncFamilyGroup(String groupId) async {
    try {
      final localGroup = await _getFamilyGroupLocal(groupId);
      if (localGroup == null) return;

      final remoteGroup = await _downloadFamilyGroup(groupId);
      if (remoteGroup == null) return;

      // 更新成员列表
      final mergedMembers = _mergeMembers(localGroup.members, remoteGroup.members);

      final updatedGroup = localGroup.copyWith(
        members: mergedMembers,
        updatedAt: DateTime.now(),
      );

      await _saveFamilyGroupLocal(updatedGroup);

      // 同步所有事件
      for (final eventId in localGroup.sharedEventIds) {
        await syncSharedEvent('$eventId-shared');
      }
    } catch (e) {
      debugPrint('syncFamilyGroup error: $e');
    }
  }

  /// 合并成员列表
  List<SharedEventMember> _mergeMembers(
    List<SharedEventMember> local,
    List<SharedEventMember> remote,
  ) {
    final merged = <String, SharedEventMember>{};

    for (final member in local) {
      merged[member.id] = member;
    }

    for (final member in remote) {
      final existing = merged[member.id];
      if (existing == null || member.lastSyncAt.isAfter(existing.lastSyncAt)) {
        merged[member.id] = member;
      }
    }

    return merged.values.toList();
  }

  // ==================== WebDAV操作 ====================

  /// 确保共享目录存在
  Future<void> _ensureSharedDir() async {
    try {
      await _webdavService.ensureRemoteWorkspace();
      // 创建共享目录
      await _webdavService.uploadFile(
        '', // 空内容表示创建目录
        '$_sharedDir/.keep',
      );
    } catch (e) {
      debugPrint('_ensureSharedDir error: $e');
    }
  }

  /// 上传共享事件到WebDAV
  Future<void> _uploadSharedEventToWebDAV(
    CountdownEvent event,
    SharedEventMetadata metadata,
  ) async {
    try {
      await _ensureSharedDir();

      // 上传事件数据
      final eventData = jsonEncode(event.toMap());
      final eventPath = '$_sharedDir/${metadata.shareId}/event.json';
      await _uploadDataToWebDAV(eventPath, eventData);

      // 上传元数据
      await _uploadSharedEventMetadataToWebDAV(metadata);
    } catch (e) {
      debugPrint('_uploadSharedEventToWebDAV error: $e');
    }
  }

  /// 上传共享事件元数据到WebDAV
  Future<void> _uploadSharedEventMetadataToWebDAV(
    SharedEventMetadata metadata,
  ) async {
    try {
      final metadataPath = '$_sharedDir/${metadata.shareId}/$_metadataFile';
      await _uploadDataToWebDAV(metadataPath, metadata.toJsonString());
    } catch (e) {
      debugPrint('_uploadSharedEventMetadataToWebDAV error: $e');
    }
  }

  /// 上传家庭组到WebDAV
  Future<void> _uploadFamilyGroupToWebDAV(FamilyShareGroup group) async {
    try {
      await _ensureSharedDir();
      final groupPath = '$_familyGroupsDir/${group.id}.json';
      await _uploadDataToWebDAV(groupPath, group.toJsonString());
    } catch (e) {
      debugPrint('_uploadFamilyGroupToWebDAV error: $e');
    }
  }

  /// 下载数据从WebDAV
  Future<String?> _downloadFromWebDAV(String remotePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/temp_download.json';

      final success = await _webdavService.downloadFile(remotePath, localPath);
      if (!success) return null;

      final file = File(localPath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      await file.delete();
      return content;
    } catch (e) {
      debugPrint('_downloadFromWebDAV error: $e');
      return null;
    }
  }

  /// 上传数据到WebDAV
  Future<void> _uploadDataToWebDAV(String remotePath, String data) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/temp_upload.json';

      final file = File(localPath);
      await file.writeAsString(data);

      await _webdavService.uploadFile(localPath, remotePath);
      await file.delete();
    } catch (e) {
      debugPrint('_uploadDataToWebDAV error: $e');
    }
  }

  /// 下载共享事件元数据
  Future<SharedEventMetadata?> _downloadSharedEventMetadata(
    String shareId,
  ) async {
    try {
      final metadataPath = '$_sharedDir/$shareId/$_metadataFile';
      final json = await _downloadFromWebDAV(metadataPath);
      if (json == null) return null;

      return SharedEventMetadata.fromJsonString(json);
    } catch (e) {
      debugPrint('_downloadSharedEventMetadata error: $e');
      return null;
    }
  }

  /// 下载共享事件数据
  Future<CountdownEvent?> _downloadSharedEventData(String shareId) async {
    try {
      final eventPath = '$_sharedDir/$shareId/event.json';
      final json = await _downloadFromWebDAV(eventPath);
      if (json == null) return null;

      final map = jsonDecode(json) as Map<String, dynamic>;
      return CountdownEvent.fromMap(map);
    } catch (e) {
      debugPrint('_downloadSharedEventData error: $e');
      return null;
    }
  }

  /// 下载家庭组
  Future<FamilyShareGroup?> _downloadFamilyGroup(String groupId) async {
    try {
      final groupPath = '$_familyGroupsDir/$groupId.json';
      final json = await _downloadFromWebDAV(groupPath);
      if (json == null) return null;

      return FamilyShareGroup.fromJsonString(json);
    } catch (e) {
      debugPrint('_downloadFamilyGroup error: $e');
      return null;
    }
  }

  // ==================== 本地存储 ====================

  /// 保存共享事件元数据到本地
  Future<void> _saveSharedEventMetadataLocal(SharedEventMetadata metadata) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/shared_events/${metadata.shareId}.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(metadata.toJsonString());
    } catch (e) {
      debugPrint('_saveSharedEventMetadataLocal error: $e');
    }
  }

  /// 获取本地共享事件元数据
  Future<SharedEventMetadata?> _getSharedEventMetadataLocal(
    String shareId,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/shared_events/$shareId.json');
      if (!await file.exists()) return null;

      final json = await file.readAsString();
      return SharedEventMetadata.fromJsonString(json);
    } catch (e) {
      debugPrint('_getSharedEventMetadataLocal error: $e');
      return null;
    }
  }

  /// 获取所有本地共享事件元数据
  Future<List<SharedEventMetadata>> getAllSharedEventsLocal() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory('${tempDir.path}/shared_events');
      if (!await dir.exists()) return [];

      final files = await dir.list().where((f) => f.path.endsWith('.json')).toList();
      final results = <SharedEventMetadata>[];

      for (final file in files) {
        try {
          final json = await File(file.path).readAsString();
          results.add(SharedEventMetadata.fromJsonString(json));
        } catch (e) {
          debugPrint('Error reading shared event file: $e');
        }
      }

      return results;
    } catch (e) {
      debugPrint('getAllSharedEventsLocal error: $e');
      return [];
    }
  }

  /// 保存家庭组到本地
  Future<void> _saveFamilyGroupLocal(FamilyShareGroup group) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/family_groups/${group.id}.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(group.toJsonString());
    } catch (e) {
      debugPrint('_saveFamilyGroupLocal error: $e');
    }
  }

  /// 获取本地家庭组
  Future<FamilyShareGroup?> _getFamilyGroupLocal(String groupId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/family_groups/$groupId.json');
      if (!await file.exists()) return null;

      final json = await file.readAsString();
      return FamilyShareGroup.fromJsonString(json);
    } catch (e) {
      debugPrint('_getFamilyGroupLocal error: $e');
      return null;
    }
  }

  /// 获取所有本地家庭组
  Future<List<FamilyShareGroup>> getAllFamilyGroupsLocal() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory('${tempDir.path}/family_groups');
      if (!await dir.exists()) return [];

      final files = await dir.list().where((f) => f.path.endsWith('.json')).toList();
      final results = <FamilyShareGroup>[];

      for (final file in files) {
        try {
          final json = await File(file.path).readAsString();
          results.add(FamilyShareGroup.fromJsonString(json));
        } catch (e) {
          debugPrint('Error reading family group file: $e');
        }
      }

      return results;
    } catch (e) {
      debugPrint('getAllFamilyGroupsLocal error: $e');
      return [];
    }
  }

  // ==================== 分享历史 ====================

  /// 记录分享历史
  Future<void> recordShareHistory({
    required String eventId,
    required String shareMethod,
    String? recipientName,
  }) async {
    try {
      final history = ShareHistoryEntry(
        id: _uuid.v4(),
        eventId: eventId,
        shareMethod: shareMethod,
        recipientName: recipientName,
        sharedAt: DateTime.now(),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_history.json');
      
      List<dynamic> historyList = [];
      if (await file.exists()) {
        final json = await file.readAsString();
        historyList = jsonDecode(json) as List<dynamic>;
      }

      historyList.add(history.toMap());
      await file.writeAsString(jsonEncode(historyList));
    } catch (e) {
      debugPrint('recordShareHistory error: $e');
    }
  }

  /// 获取分享历史
  Future<List<ShareHistoryEntry>> getShareHistory({String? eventId}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_history.json');
      if (!await file.exists()) return [];

      final json = await file.readAsString();
      final historyList = jsonDecode(json) as List<dynamic>;

      final history = historyList
          .map((h) => ShareHistoryEntry.fromMap(h as Map<String, dynamic>))
          .toList();

      if (eventId != null) {
        return history.where((h) => h.eventId == eventId).toList();
      }

      return history;
    } catch (e) {
      debugPrint('getShareHistory error: $e');
      return [];
    }
  }
}
