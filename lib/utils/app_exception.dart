// ============================================================================
// 应用异常类
// ============================================================================
//
// 统一异常处理，区分不同类型的错误，便于上层捕获和展示。
// ============================================================================

/// 应用基础异常类
///
/// 所有自定义异常的基类，提供统一的异常处理接口。
/// 包含错误消息、错误代码和原始异常信息。
class AppException implements Exception {
  /// 错误消息
  final String message;

  /// 错误代码（可选）
  final String? code;

  /// 原始异常（可选，用于调试）
  final dynamic originalException;

  /// 创建一个应用异常
  ///
  /// [message] 错误消息
  /// [code] 错误代码（可选）
  /// [originalException] 原始异常（可选）
  AppException(this.message, {this.code, this.originalException});

  @override
  String toString() {
    if (code != null) {
      return 'AppException($code): $message';
    }
    return 'AppException: $message';
  }
}

/// 数据库异常
///
/// 数据库操作失败时抛出此异常。
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.originalException})
      : super(code: 'DATABASE_ERROR');
}

/// 网络异常
///
/// 网络请求失败时抛出此异常。
class NetworkException extends AppException {
  /// HTTP 状态码（如果有）
  final int? statusCode;

  NetworkException(super.message, {this.statusCode, super.originalException})
      : super(code: 'NETWORK_ERROR');
}

/// 业务逻辑异常
///
/// 业务规则验证失败时抛出此异常。
class BusinessException extends AppException {
  BusinessException(super.message, {String? code})
      : super(code: code ?? 'BUSINESS_ERROR');
}

/// 权限异常
///
/// 权限被拒绝时抛出此异常。
class PermissionException extends AppException {
  PermissionException(super.message)
      : super(code: 'PERMISSION_DENIED');
}

/// 文件系统异常
///
/// 文件系统操作失败时抛出此异常。
class FileSystemException extends AppException {
  FileSystemException(super.message, {super.originalException})
      : super(code: 'FILE_SYSTEM_ERROR');
}

/// 云同步异常
///
/// 云端同步操作失败时抛出此异常。
class CloudSyncException extends AppException {
  CloudSyncException(super.message, {super.originalException})
      : super(code: 'CLOUD_SYNC_ERROR');
}

/// 输入验证异常
///
/// 用户输入验证失败时抛出此异常。
class ValidationException extends AppException {
  ValidationException(super.message)
      : super(code: 'VALIDATION_ERROR');
}
