import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UpdateDownloadResult {
  const UpdateDownloadResult({
    required this.file,
    required this.bytes,
    required this.totalBytes,
  });

  final File file;
  final int bytes;
  final int? totalBytes;
}

typedef UpdateProgress = void Function(int received, int? total);

/// 流式下载 APK 到应用文档目录，失败时清理半成品并抛错。
Future<UpdateDownloadResult?> downloadUpdate({
  required Uri uri,
  required String version,
  required String abi,
  UpdateProgress? onProgress,
  bool Function()? shouldCancel,
  http.Client? client,
  Duration timeout = const Duration(minutes: 15),
}) async {
  final active = client ?? http.Client();
  final documents = await getApplicationDocumentsDirectory();
  final updateDir = Directory(
    '${documents.path}${Platform.pathSeparator}updates',
  );
  await updateDir.create(recursive: true);
  final safeAbi = abi.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
  final file = File(
    '${updateDir.path}${Platform.pathSeparator}ying-$version-$safeAbi.apk',
  );
  if (await file.exists()) await file.delete();
  final request = http.Request('GET', uri)
    ..headers['User-Agent'] = 'ying-update-download';
  final completer = Completer<UpdateDownloadResult?>();
  StreamSubscription<List<int>>? subscription;
  var received = 0;
  IOSink? sink;

  Future<void> cleanup() async {
    subscription?.cancel();
    await sink?.close();
    if (await file.exists()) await file.delete();
  }

  try {
    final response = await active
        .send(request)
        .timeout(const Duration(seconds: 20), onTimeout: () {
      throw const UpdateDownloadException('连接超时，请稍后重试');
    });
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw UpdateDownloadException('下载失败（HTTP ${response.statusCode}）');
    }
    sink = file.openWrite();
    final total = response.contentLength;
    subscription = response.stream.listen(
      (chunk) {
        if (shouldCancel?.call() ?? false) {
          unawaited(cleanup());
          if (!completer.isCompleted) completer.complete(null);
          return;
        }
        received += chunk.length;
        sink?.add(chunk);
        onProgress?.call(received, total);
      },
      onError: (Object error) {
        unawaited(cleanup());
        if (!completer.isCompleted) {
          completer.completeError(
            const UpdateDownloadException('网络错误，请稍后重试'),
          );
        }
      },
      onDone: () async {
        await sink?.close();
        if (await file.exists()) {
          final magic = await _apkMagic(file);
          if (magic != 'PK\u0003\u0004') {
            await cleanup();
            if (!completer.isCompleted) {
              completer.completeError(
                const UpdateDownloadException('下载内容不是有效的 APK'),
              );
            }
            return;
          }
        }
        if (!completer.isCompleted) {
          completer.complete(
            UpdateDownloadResult(
              file: file,
              bytes: received,
              totalBytes: total,
            ),
          );
        }
      },
    );
    return await completer.future.timeout(timeout, onTimeout: () async {
      await cleanup();
      return null;
    });
  } catch (error) {
    await cleanup();
    if (error is UpdateDownloadException) rethrow;
    throw const UpdateDownloadException('下载失败，请检查网络后重试');
  } finally {
    if (client == null) active.close();
  }
}

Future<String> _apkMagic(File file) async {
  final raf = await file.open();
  try {
    final bytes = await raf.read(4);
    return String.fromCharCodes(bytes);
  } finally {
    await raf.close();
  }
}
