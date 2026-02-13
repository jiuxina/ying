// ============================================================================
// WebDAV 服务
//
// 封装 WebDAV 客户端操作，提供：
// - 连接测试
// - 文件上传/下载
// - 目录列表
// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../utils/app_exception.dart';

/// WebDAV 连接配置
class WebDAVConfig {
  final String url;
  final String username;
  final String password;

  const WebDAVConfig({
    required this.url,
    required this.username,
    required this.password,
  });

  /// 检查配置是否完整
  bool get isValid => url.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  /// 验证 URL 格式
  bool get isUrlValid {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 从 Map 创建配置
  factory WebDAVConfig.fromMap(Map<String, dynamic> map) {
    return WebDAVConfig(
      url: map['url'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'username': username,
      'password': password,
    };
  }
}

/// WebDAV 服务类
class WebDAVService {
  webdav.Client? _client;

  /// 云端工作区目录名称
  static const String remoteWorkspaceName = 'Ying-Countdown';

  /// 初始化 WebDAV 客户端
  void initialize(WebDAVConfig config) {
    if (!config.isValid) {
      _client = null;
      return;
    }

    if (!config.isUrlValid) {
      throw ValidationException('WebDAV URL 格式无效');
    }

    _client = webdav.newClient(
      config.url,
      user: config.username,
      password: config.password,
      debug: false,
    );

    // 设置公共请求头
    _client!.setHeaders({'accept-charset': 'utf-8'});
  }

  /// 测试连接
  Future<bool> testConnection() async {
    if (_client == null) {
      throw CloudSyncException('WebDAV 客户端未初始化');
    }

    try {
      await _client!.ping();
      return true;
    } on SocketException catch (e) {
      debugPrint('WebDAV 网络连接失败: $e');
      throw NetworkException('无法连接到 WebDAV 服务器，请检查网络连接', originalException: e);
    } catch (e) {
      debugPrint('WebDAV 连接测试失败: $e');
      throw CloudSyncException('WebDAV 连接测试失败', originalException: e);
    }
  }

  /// 确保远程工作区目录存在
  Future<void> ensureRemoteWorkspace() async {
    if (_client == null) {
      throw CloudSyncException('WebDAV 客户端未初始化');
    }

    try {
      await _client!.mkdir('/$remoteWorkspaceName');
    } catch (e) {
      // 目录可能已存在，忽略错误
      debugPrint('WebDAV 创建远程目录: $e');
    }
  }

  /// 列出远程目录内容
  Future<List<webdav.File>?> listRemoteFiles({String remotePath = ''}) async {
    if (_client == null) {
      throw CloudSyncException('WebDAV 客户端未初始化');
    }

    try {
      // Sanitize path to prevent directory traversal
      final sanitizedPath = _sanitizePath(remotePath);
      final path = sanitizedPath.isEmpty
          ? '/$remoteWorkspaceName'
          : '/$remoteWorkspaceName/$sanitizedPath';

      return await _client!.readDir(path);
    } on SocketException catch (e) {
      debugPrint('WebDAV 网络错误: $e');
      throw NetworkException('网络连接失败', originalException: e);
    } catch (e) {
      debugPrint('WebDAV 列出目录失败: $e');
      throw CloudSyncException('无法列出远程目录', originalException: e);
    }
  }

  /// 上传文件
  Future<bool> uploadFile(String localPath, String remotePath) async {
    if (_client == null) {
      throw CloudSyncException('WebDAV 客户端未初始化');
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        debugPrint('WebDAV 上传失败：本地文件不存在 $localPath');
        throw FileSystemException('本地文件不存在: $localPath');
      }

      // Sanitize remote path
      final sanitizedPath = _sanitizePath(remotePath);
      final fullRemotePath = '/$remoteWorkspaceName/$sanitizedPath';

      // 确保父目录存在
      final parentPath = fullRemotePath.substring(0, fullRemotePath.lastIndexOf('/'));
      await _ensureRemoteDir(parentPath);

      // 上传文件
      await _client!.writeFromFile(localPath, fullRemotePath);
      debugPrint('WebDAV 上传成功: $localPath -> $fullRemotePath');
      return true;
    } on FileSystemException {
      rethrow;
    } on SocketException catch (e) {
      debugPrint('WebDAV 网络错误: $e');
      throw NetworkException('网络连接失败', originalException: e);
    } catch (e) {
      debugPrint('WebDAV 上传失败: $e');
      throw CloudSyncException('文件上传失败', originalException: e);
    }
  }

  /// 下载文件
  Future<bool> downloadFile(String remotePath, String localPath) async {
    if (_client == null) {
      throw CloudSyncException('WebDAV 客户端未初始化');
    }

    try {
      // Sanitize remote path
      final sanitizedPath = _sanitizePath(remotePath);
      final fullRemotePath = '/$remoteWorkspaceName/$sanitizedPath';

      // 确保本地父目录存在
      final localDir = localPath.substring(0, localPath.lastIndexOf(Platform.pathSeparator));
      await Directory(localDir).create(recursive: true);

      // 下载文件
      await _client!.read2File(fullRemotePath, localPath);
      debugPrint('WebDAV 下载成功: $fullRemotePath -> $localPath');
      return true;
    } on SocketException catch (e) {
      debugPrint('WebDAV 网络错误: $e');
      throw NetworkException('网络连接失败', originalException: e);
    } catch (e) {
      debugPrint('WebDAV 下载失败: $e');
      throw CloudSyncException('文件下载失败', originalException: e);
    }
  }

  /// 删除远程文件或目录
  Future<bool> deleteRemote(String remotePath) async {
    if (_client == null) {
      throw CloudSyncException('WebDAV 客户端未初始化');
    }

    try {
      // Sanitize remote path
      final sanitizedPath = _sanitizePath(remotePath);
      final fullRemotePath = '/$remoteWorkspaceName/$sanitizedPath';
      await _client!.remove(fullRemotePath);
      debugPrint('WebDAV 删除成功: $fullRemotePath');
      return true;
    } on SocketException catch (e) {
      debugPrint('WebDAV 网络错误: $e');
      throw NetworkException('网络连接失败', originalException: e);
    } catch (e) {
      debugPrint('WebDAV 删除失败: $e');
      throw CloudSyncException('删除失败', originalException: e);
    }
  }

  // ==================== 私有方法 ====================

  /// 清理路径，防止路径遍历攻击
  String _sanitizePath(String path) {
    // Remove leading/trailing slashes and whitespace
    String sanitized = path.trim().replaceAll(RegExp(r'^/+|/+$'), '');

    // Remove any .. or . path traversal attempts
    sanitized = sanitized.replaceAll('..', '').replaceAll(RegExp(r'\.{2,}'), '');

    // Remove multiple consecutive slashes
    sanitized = sanitized.replaceAll(RegExp(r'/+'), '/');

    return sanitized;
  }

  /// 确保远程目录存在（递归创建）
  Future<void> _ensureRemoteDir(String remotePath) async {
    if (_client == null) return;

    final parts = remotePath.split('/').where((p) => p.isNotEmpty).toList();
    String currentPath = '';

    for (final part in parts) {
      currentPath += '/$part';
      try {
        await _client!.mkdir(currentPath);
      } catch (e) {
        // 目录可能已存在
      }
    }
  }
}
