import 'dart:convert';
import 'countdown_event.dart';

/// 共享权限级别
enum SharePermission {
  view,   // 只读
  edit,   // 可编辑
  admin,  // 管理员（可邀请新成员）
}

/// 共享事件成员
class SharedEventMember {
  final String id;          // 成员唯一标识
  final String displayName; // 显示名称
  final SharePermission permission;
  final DateTime joinedAt;
  final DateTime lastSyncAt;
  final bool isOwner;

  const SharedEventMember({
    required this.id,
    required this.displayName,
    required this.permission,
    required this.joinedAt,
    required this.lastSyncAt,
    this.isOwner = false,
  });

  factory SharedEventMember.fromMap(Map<String, dynamic> map) {
    return SharedEventMember(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      permission: SharePermission.values[map['permission'] as int? ?? 0],
      joinedAt: DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] as int),
      lastSyncAt: DateTime.fromMillisecondsSinceEpoch(map['lastSyncAt'] as int),
      isOwner: (map['isOwner'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'permission': permission.index,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'lastSyncAt': lastSyncAt.millisecondsSinceEpoch,
      'isOwner': isOwner ? 1 : 0,
    };
  }

  SharedEventMember copyWith({
    String? id,
    String? displayName,
    SharePermission? permission,
    DateTime? joinedAt,
    DateTime? lastSyncAt,
    bool? isOwner,
  }) {
    return SharedEventMember(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      permission: permission ?? this.permission,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}

/// 共享事件变更记录
class SharedEventChange {
  final String id;
  final String eventId;
  final String memberId;
  final String field;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime changedAt;
  final bool isConflict;

  const SharedEventChange({
    required this.id,
    required this.eventId,
    required this.memberId,
    required this.field,
    this.oldValue,
    this.newValue,
    required this.changedAt,
    this.isConflict = false,
  });

  factory SharedEventChange.fromMap(Map<String, dynamic> map) {
    return SharedEventChange(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      memberId: map['memberId'] as String,
      field: map['field'] as String,
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      changedAt: DateTime.fromMillisecondsSinceEpoch(map['changedAt'] as int),
      isConflict: (map['isConflict'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'memberId': memberId,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'changedAt': changedAt.millisecondsSinceEpoch,
      'isConflict': isConflict ? 1 : 0,
    };
  }
}

/// 共享事件元数据
class SharedEventMetadata {
  final String eventId;           // 关联的事件ID
  final String shareId;           // 共享ID（用于WebDAV路径）
  final String ownerDeviceId;     // 创建者设备ID
  final String ownerDisplayName; // 创建者显示名称
  final List<SharedEventMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;              // 版本号，用于冲突检测
  final bool isSynced;            // 是否已同步到WebDAV
  final DateTime? lastSyncAt;     // 最后同步时间

  const SharedEventMetadata({
    required this.eventId,
    required this.shareId,
    required this.ownerDeviceId,
    required this.ownerDisplayName,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isSynced = false,
    this.lastSyncAt,
  });

  factory SharedEventMetadata.fromMap(Map<String, dynamic> map) {
    return SharedEventMetadata(
      eventId: map['eventId'] as String,
      shareId: map['shareId'] as String,
      ownerDeviceId: map['ownerDeviceId'] as String,
      ownerDisplayName: map['ownerDisplayName'] as String,
      members: (map['members'] as List<dynamic>?)
          ?.map((m) => SharedEventMember.fromMap(m as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      version: map['version'] as int? ?? 1,
      isSynced: (map['isSynced'] as int?) == 1,
      lastSyncAt: map['lastSyncAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSyncAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'shareId': shareId,
      'ownerDeviceId': ownerDeviceId,
      'ownerDisplayName': ownerDisplayName,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'version': version,
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAt': lastSyncAt?.millisecondsSinceEpoch,
    };
  }

  /// 转换为JSON字符串（用于WebDAV同步）
  String toJsonString() => jsonEncode(toMap());

  /// 从JSON字符串创建
  factory SharedEventMetadata.fromJsonString(String json) {
    return SharedEventMetadata.fromMap(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  SharedEventMetadata copyWith({
    String? eventId,
    String? shareId,
    String? ownerDeviceId,
    String? ownerDisplayName,
    List<SharedEventMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isSynced,
    DateTime? lastSyncAt,
  }) {
    return SharedEventMetadata(
      eventId: eventId ?? this.eventId,
      shareId: shareId ?? this.shareId,
      ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  /// 检查用户是否有指定权限
  bool hasPermission(String memberId, SharePermission permission) {
    final member = members.where((m) => m.id == memberId).firstOrNull;
    if (member == null) return false;
    
    // 权限等级：view < edit < admin
    return member.permission.index >= permission.index;
  }

  /// 获取成员数量
  int get memberCount => members.length;
}

/// 家庭共享组
class FamilyShareGroup {
  final String id;
  final String name;
  final String ownerDeviceId;
  final String ownerDisplayName;
  final List<SharedEventMember> members;
  final List<String> sharedEventIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? lastSyncAt;

  const FamilyShareGroup({
    required this.id,
    required this.name,
    required this.ownerDeviceId,
    required this.ownerDisplayName,
    required this.members,
    required this.sharedEventIds,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.lastSyncAt,
  });

  factory FamilyShareGroup.fromMap(Map<String, dynamic> map) {
    return FamilyShareGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerDeviceId: map['ownerDeviceId'] as String,
      ownerDisplayName: map['ownerDisplayName'] as String,
      members: (map['members'] as List<dynamic>?)
          ?.map((m) => SharedEventMember.fromMap(m as Map<String, dynamic>))
          .toList() ?? [],
      sharedEventIds: (map['sharedEventIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isSynced: (map['isSynced'] as int?) == 1,
      lastSyncAt: map['lastSyncAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSyncAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerDeviceId': ownerDeviceId,
      'ownerDisplayName': ownerDisplayName,
      'members': members.map((m) => m.toMap()).toList(),
      'sharedEventIds': sharedEventIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAt': lastSyncAt?.millisecondsSinceEpoch,
    };
  }

  String toJsonString() => jsonEncode(toMap());

  factory FamilyShareGroup.fromJsonString(String json) {
    return FamilyShareGroup.fromMap(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  FamilyShareGroup copyWith({
    String? id,
    String? name,
    String? ownerDeviceId,
    String? ownerDisplayName,
    List<SharedEventMember>? members,
    List<String>? sharedEventIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncAt,
  }) {
    return FamilyShareGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
      members: members ?? this.members,
      sharedEventIds: sharedEventIds ?? this.sharedEventIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

/// 分享历史记录
class ShareHistoryEntry {
  final String id;
  final String eventId;
  final String shareMethod;     // qr, link, family
  final String? recipientName;  // 接收者名称
  final DateTime sharedAt;
  final bool wasImported;       // 是否被成功导入

  const ShareHistoryEntry({
    required this.id,
    required this.eventId,
    required this.shareMethod,
    this.recipientName,
    required this.sharedAt,
    this.wasImported = false,
  });

  factory ShareHistoryEntry.fromMap(Map<String, dynamic> map) {
    return ShareHistoryEntry(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      shareMethod: map['shareMethod'] as String,
      recipientName: map['recipientName'] as String?,
      sharedAt: DateTime.fromMillisecondsSinceEpoch(map['sharedAt'] as int),
      wasImported: (map['wasImported'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'shareMethod': shareMethod,
      'recipientName': recipientName,
      'sharedAt': sharedAt.millisecondsSinceEpoch,
      'wasImported': wasImported ? 1 : 0,
    };
  }
}

/// 冲突解决策略
enum ConflictResolution {
  keepLocal,     // 保留本地版本
  keepRemote,    // 使用远程版本
  merge,         // 合并（尽可能保留双方的修改）
  keepNewer,     // 保留较新的版本
}

/// 冲突检测结果
class ConflictResult {
  final bool hasConflict;
  final String? field;
  final dynamic localValue;
  final dynamic remoteValue;
  final DateTime? localTime;
  final DateTime? remoteTime;
  final ConflictResolution? suggestedResolution;

  const ConflictResult({
    this.hasConflict = false,
    this.field,
    this.localValue,
    this.remoteValue,
    this.localTime,
    this.remoteTime,
    this.suggestedResolution,
  });

  factory ConflictResult.conflict({
    required String field,
    required dynamic localValue,
    required dynamic remoteValue,
    DateTime? localTime,
    DateTime? remoteTime,
    ConflictResolution? suggestedResolution,
  }) {
    return ConflictResult(
      hasConflict: true,
      field: field,
      localValue: localValue,
      remoteValue: remoteValue,
      localTime: localTime,
      remoteTime: remoteTime,
      suggestedResolution: suggestedResolution,
    );
  }

  const factory ConflictResult.noConflict() = ConflictResult;
}

/// 共享事件导入数据
class SharedEventImportData {
  final CountdownEvent event;
  final String shareId;
  final String ownerDeviceId;
  final String ownerDisplayName;
  final int version;
  final SharePermission permission;
  final String inviterDeviceId;
  final String inviterDisplayName;

  const SharedEventImportData({
    required this.event,
    required this.shareId,
    required this.ownerDeviceId,
    required this.ownerDisplayName,
    required this.version,
    required this.permission,
    required this.inviterDeviceId,
    required this.inviterDisplayName,
  });
}

/// 家庭组邀请数据
class FamilyGroupInviteData {
  final String groupId;
  final String groupName;
  final String ownerDeviceId;
  final String ownerDisplayName;
  final int eventCount;
  final String inviterDeviceId;
  final String inviterDisplayName;

  const FamilyGroupInviteData({
    required this.groupId,
    required this.groupName,
    required this.ownerDeviceId,
    required this.ownerDisplayName,
    required this.eventCount,
    required this.inviterDeviceId,
    required this.inviterDisplayName,
  });
}
