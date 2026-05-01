import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:uuid/uuid.dart';
import '../models/event_memory.dart';
import 'database_service.dart';

/// 记忆服务 - 管理事件记忆的存储和检索
/// 
/// 提供以下功能：
/// - 照片拍摄和选择
/// - 图片压缩和存储
/// - 记忆CRUD操作
/// - 存储空间管理
/// 
/// 示例:
/// ```dart
/// final memoryService = MemoryService();
/// 
/// // 添加照片记忆
/// final memory = await memoryService.addPhotoMemory(
///   eventId: 'event-123',
///   content: '美好的一天',
/// );
/// ```
class MemoryService {
  /// 单例实例
  static final MemoryService _instance = MemoryService._internal();
  
  /// 工厂构造函数
  factory MemoryService() => _instance;
  
  /// 私有构造函数
  MemoryService._internal();

  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  
  /// 图片存储目录名称
  static const String _memoryImagesDir = 'memory_images';
  
  /// 最大图片宽度（1080p）
  static const int _maxImageWidth = 1920;
  
  /// 最大图片高度（1080p）
  static const int _maxImageHeight = 1080;
  
  /// 图片压缩质量 (0-100)
  static const int _imageQuality = 85;
  
  /// 单个事件最大照片数
  static const int maxPhotosPerEvent = 50;

  /// 获取图片存储目录
  Future<Directory> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path_pkg.join(appDir.path, _memoryImagesDir));
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    return imagesDir;
  }

  /// 生成唯一的图片文件名
  String _generateImageFileName(String eventId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomId = const Uuid().v4().substring(0, 8);
    return '${eventId}_${timestamp}_$randomId.jpg';
  }

  /// 压缩并保存图片
  /// 
  /// 将图片压缩至1080p以下，并保存到应用文档目录
  /// 
  /// 注意：image_picker 已在 pickImage 时自动压缩图片，
  /// 这里主要处理文件存储和命名
  Future<String?> _compressAndSaveImage(File imageFile, String eventId) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final fileName = _generateImageFileName(eventId);
      final targetPath = path_pkg.join(imagesDir.path, fileName);
      
      // 复制文件到目标位置
      // image_picker 已在 pickImage 时通过 maxWidth/maxHeight/imageQuality 参数压缩
      await imageFile.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      debugPrint('保存图片失败: $e');
      return null;
    }
  }

  /// 从相机拍照
  /// 
  /// 返回拍摄的照片文件，如果取消则返回null
  Future<XFile?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxImageWidth.toDouble(),
        maxHeight: _maxImageHeight.toDouble(),
        imageQuality: _imageQuality,
      );
      return image;
    } catch (e) {
      debugPrint('拍照失败: $e');
      return null;
    }
  }

  /// 从相册选择单张图片
  /// 
  /// 返回选中的图片文件，如果取消则返回null
  Future<XFile?> pickSingleImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxImageWidth.toDouble(),
        maxHeight: _maxImageHeight.toDouble(),
        imageQuality: _imageQuality,
      );
      return image;
    } catch (e) {
      debugPrint('选择图片失败: $e');
      return null;
    }
  }

  /// 从相册选择多张图片
  /// 
  /// [maxImages] 最大选择数量，默认10张
  /// 返回选中的图片文件列表
  Future<List<XFile>> pickMultipleImages({int maxImages = 10}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: _maxImageWidth.toDouble(),
        maxHeight: _maxImageHeight.toDouble(),
        imageQuality: _imageQuality,
      );
      
      // 限制数量
      if (images.length > maxImages) {
        return images.sublist(0, maxImages);
      }
      return images;
    } catch (e) {
      debugPrint('选择多张图片失败: $e');
      return [];
    }
  }

  /// 添加照片记忆
  /// 
  /// [eventId] 关联的事件ID
  /// [imageFiles] 图片文件列表
  /// [content] 文字描述
  Future<EventMemory?> addPhotoMemory({
    required String eventId,
    required List<XFile> imageFiles,
    String? content,
  }) async {
    // 检查照片数量限制
    final currentCount = await _db.getPhotoCount(eventId);
    final remaining = maxPhotosPerEvent - currentCount;
    
    if (remaining <= 0) {
      throw StateError('该事件已达到最大照片数量限制 ($maxPhotosPerEvent 张)');
    }
    
    // 限制本次添加的数量
    final filesToProcess = imageFiles.length > remaining
        ? imageFiles.sublist(0, remaining)
        : imageFiles;
    
    // 保存图片并收集路径
    final imagePaths = <String>[];
    for (final file in filesToProcess) {
      final savedPath = await _compressAndSaveImage(File(file.path), eventId);
      if (savedPath != null) {
        imagePaths.add(savedPath);
      }
    }
    
    if (imagePaths.isEmpty) {
      return null;
    }
    
    // 创建记忆对象
    final memory = EventMemory.create(
      eventId: eventId,
      type: MemoryType.photo,
      content: content,
      imagePaths: imagePaths,
    );
    
    // 保存到数据库
    await _db.insertMemory(memory);
    
    return memory;
  }

  /// 添加故事/日记记忆
  /// 
  /// [eventId] 关联的事件ID
  /// [content] 故事内容
  /// [imageFiles] 可选的配图
  Future<EventMemory?> addStoryMemory({
    required String eventId,
    required String content,
    List<XFile>? imageFiles,
  }) async {
    // 处理可选的配图
    List<String> imagePaths = [];
    if (imageFiles != null && imageFiles.isNotEmpty) {
      final currentCount = await _db.getPhotoCount(eventId);
      final remaining = maxPhotosPerEvent - currentCount;
      
      if (remaining > 0) {
        final filesToProcess = imageFiles.length > remaining
            ? imageFiles.sublist(0, remaining)
            : imageFiles;
        
        for (final file in filesToProcess) {
          final savedPath = await _compressAndSaveImage(File(file.path), eventId);
          if (savedPath != null) {
            imagePaths.add(savedPath);
          }
        }
      }
    }
    
    // 创建记忆对象
    final memory = EventMemory.create(
      eventId: eventId,
      type: MemoryType.story,
      content: content,
      imagePaths: imagePaths.isNotEmpty ? imagePaths : null,
    );
    
    // 保存到数据库
    await _db.insertMemory(memory);
    
    return memory;
  }

  /// 添加备注记忆
  /// 
  /// [eventId] 关联的事件ID
  /// [content] 备注内容
  Future<EventMemory?> addNoteMemory({
    required String eventId,
    required String content,
  }) async {
    final memory = EventMemory.create(
      eventId: eventId,
      type: MemoryType.note,
      content: content,
    );
    
    await _db.insertMemory(memory);
    
    return memory;
  }

  /// 获取事件的所有记忆
  /// 
  /// 按时间倒序排列
  Future<List<EventMemory>> getMemories(String eventId) async {
    return await _db.getMemories(eventId);
  }

  /// 获取特定类型的记忆
  Future<List<EventMemory>> getMemoriesByType(String eventId, MemoryType type) async {
    return await _db.getMemoriesByType(eventId, type);
  }

  /// 更新记忆内容
  Future<void> updateMemoryContent(String memoryId, String? newContent) async {
    final memories = await _db.getAllMemories();
    final memory = memories.firstWhere(
      (m) => m.id == memoryId,
      orElse: () => throw StateError('记忆不存在'),
    );
    
    final updatedMemory = memory.updateContent(newContent);
    await _db.updateMemory(updatedMemory);
  }

  /// 添加图片到现有记忆
  /// 
  /// [memoryId] 记忆ID
  /// [imageFile] 图片文件
  Future<EventMemory?> addImageToMemory(String memoryId, XFile imageFile) async {
    final memories = await _db.getAllMemories();
    final memory = memories.firstWhere(
      (m) => m.id == memoryId,
      orElse: () => throw StateError('记忆不存在'),
    );
    
    // 检查照片数量限制
    final currentCount = await _db.getPhotoCount(memory.eventId);
    if (currentCount >= maxPhotosPerEvent) {
      throw StateError('该事件已达到最大照片数量限制 ($maxPhotosPerEvent 张)');
    }
    
    // 保存图片
    final savedPath = await _compressAndSaveImage(
      File(imageFile.path),
      memory.eventId,
    );
    
    if (savedPath == null) {
      return null;
    }
    
    // 更新记忆
    final updatedMemory = memory.addImage(savedPath);
    await _db.updateMemory(updatedMemory);
    
    return updatedMemory;
  }

  /// 从记忆中移除图片
  /// 
  /// [memoryId] 记忆ID
  /// [imagePath] 要移除的图片路径
  Future<void> removeImageFromMemory(String memoryId, String imagePath) async {
    final memories = await _db.getAllMemories();
    final memory = memories.firstWhere(
      (m) => m.id == memoryId,
      orElse: () => throw StateError('记忆不存在'),
    );
    
    // 从记忆中移除图片路径
    final updatedMemory = memory.removeImage(imagePath);
    
    // 删除物理文件
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    // 如果记忆没有图片且没有内容，删除整个记忆
    if (!updatedMemory.hasImages && !updatedMemory.hasContent) {
      await _db.deleteMemory(memoryId);
    } else {
      await _db.updateMemory(updatedMemory);
    }
  }

  /// 删除记忆
  /// 
  /// 同时删除关联的图片文件
  Future<void> deleteMemory(String memoryId) async {
    final memories = await _db.getAllMemories();
    final memory = memories.firstWhere(
      (m) => m.id == memoryId,
      orElse: () => throw StateError('记忆不存在'),
    );
    
    // 删除所有关联的图片文件
    for (final imagePath in memory.imagePaths) {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    // 从数据库删除
    await _db.deleteMemory(memoryId);
  }

  /// 删除事件的所有记忆
  /// 
  /// 同时删除所有关联的图片文件
  Future<void> deleteEventMemories(String eventId) async {
    final memories = await _db.getMemories(eventId);
    
    // 删除所有图片文件
    for (final memory in memories) {
      for (final imagePath in memory.imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    
    // 从数据库删除
    await _db.deleteEventMemories(eventId);
  }

  /// 批量删除记忆
  /// 
  /// [memoryIds] 要删除的记忆ID列表
  Future<void> deleteMemories(List<String> memoryIds) async {
    for (final id in memoryIds) {
      await deleteMemory(id);
    }
  }

  /// 获取事件的记忆统计信息
  Future<MemoryStats> getMemoryStats(String eventId) async {
    final memories = await _db.getMemories(eventId);
    
    int photoCount = 0;
    int storyCount = 0;
    int noteCount = 0;
    
    for (final memory in memories) {
      switch (memory.type) {
        case MemoryType.photo:
          photoCount += memory.imageCount;
          break;
        case MemoryType.story:
          storyCount++;
          photoCount += memory.imageCount;
          break;
        case MemoryType.note:
          noteCount++;
          break;
      }
    }
    
    return MemoryStats(
      totalMemories: memories.length,
      photoCount: photoCount,
      storyCount: storyCount,
      noteCount: noteCount,
    );
  }

  /// 计算存储空间使用情况
  Future<StorageInfo> getStorageInfo() async {
    final imagesDir = await _getImagesDirectory();
    int totalSize = 0;
    int fileCount = 0;
    
    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
          fileCount++;
        }
      }
    }
    
    // 转换为MB
    final sizeInMB = totalSize / (1024 * 1024);
    
    return StorageInfo(
      totalSizeInBytes: totalSize,
      totalSizeInMB: sizeInMB,
      fileCount: fileCount,
    );
  }

  /// 清理所有记忆和图片
  /// 
  /// 危险操作！仅用于测试或重置
  Future<void> clearAllMemories() async {
    // 删除所有记忆记录
    final memories = await _db.getAllMemories();
    for (final memory in memories) {
      await deleteMemory(memory.id);
    }
    
    // 清空图片目录
    final imagesDir = await _getImagesDirectory();
    if (await imagesDir.exists()) {
      await imagesDir.delete(recursive: true);
    }
  }

  /// 检查图片文件是否存在
  Future<bool> imageExists(String imagePath) async {
    final file = File(imagePath);
    return await file.exists();
  }

  /// 获取图片文件
  File? getImageFile(String imagePath) {
    final file = File(imagePath);
    return file.existsSync() ? file : null;
  }
}

/// 记忆统计信息
class MemoryStats {
  /// 总记忆数量
  final int totalMemories;
  
  /// 照片总数
  final int photoCount;
  
  /// 故事数量
  final int storyCount;
  
  /// 备注数量
  final int noteCount;

  const MemoryStats({
    required this.totalMemories,
    required this.photoCount,
    required this.storyCount,
    required this.noteCount,
  });

  /// 是否有任何记忆
  bool get hasMemories => totalMemories > 0;

  /// 是否有照片
  bool get hasPhotos => photoCount > 0;

  /// 是否有故事
  bool get hasStories => storyCount > 0;

  /// 是否有备注
  bool get hasNotes => noteCount > 0;
}

/// 存储空间信息
class StorageInfo {
  /// 总大小（字节）
  final int totalSizeInBytes;
  
  /// 总大小（MB）
  final double totalSizeInMB;
  
  /// 文件数量
  final int fileCount;

  const StorageInfo({
    required this.totalSizeInBytes,
    required this.totalSizeInMB,
    required this.fileCount,
  });

  /// 格式化的存储大小
  String get formattedSize {
    if (totalSizeInMB < 1) {
      return '${totalSizeInBytes ~/ 1024} KB';
    } else if (totalSizeInMB < 1024) {
      return '${totalSizeInMB.toStringAsFixed(2)} MB';
    } else {
      return '${(totalSizeInMB / 1024).toStringAsFixed(2)} GB';
    }
  }
}
