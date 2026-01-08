import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';

class BackupService {
  final DatabaseService _dbService = DatabaseService();

  /// Create a backup file and share it
  Future<void> createBackup() async {
    final data = await _dbService.exportAllData();
    // Pretty print json
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'ying_backup_$timestamp.json';
    final file = File('${dir.path}/$fileName');
    
    await file.writeAsString(jsonString);
    
    await Share.shareXFiles([XFile(file.path)], text: 'Ying Data Backup');
  }

  /// Restore backup from file
  /// Returns true if successful
  Future<bool> restoreBackup() async {
    try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final jsonString = await file.readAsString();
          final data = jsonDecode(jsonString);
          
          if (data is Map<String, dynamic> && data.containsKey('version') && data.containsKey('events')) {
             await _dbService.importAllData(data);
             return true;
          }
        }
    } catch (e) {
        // print('Restore failed: $e');
        rethrow;
    }
    return false;
  }
}
