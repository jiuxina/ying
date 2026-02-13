// ============================================================================
// 应用异常类
// ============================================================================
// 
// 统一异常处理，区分不同类型的错误，便于上层捕获和展示。
// ============================================================================

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

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
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.originalException})
      : super(code: 'DATABASE_ERROR');
}

/// 网络异常
class NetworkException extends AppException {
  final int? statusCode;

  NetworkException(super.message, {this.statusCode, super.originalException})
      : super(code: 'NETWORK_ERROR');
}

/// 业务逻辑异常
class BusinessException extends AppException {
  BusinessException(super.message, {String? code})
      : super(code: code ?? 'BUSINESS_ERROR');
}

/// 权限异常
class PermissionException extends AppException {
  PermissionException(super.message)
      : super(code: 'PERMISSION_DENIED');
}

/// 文件系统异常
class FileSystemException extends AppException {
  FileSystemException(super.message, {super.originalException})
      : super(code: 'FILE_SYSTEM_ERROR');
}

/// 云同步异常
class CloudSyncException extends AppException {
  CloudSyncException(super.message, {super.originalException})
      : super(code: 'CLOUD_SYNC_ERROR');
}

/// 输入验证异常
class ValidationException extends AppException {
  ValidationException(super.message)
      : super(code: 'VALIDATION_ERROR');
}
