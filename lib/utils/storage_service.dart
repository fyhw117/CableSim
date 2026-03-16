import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class StorageService {
  static const String _extension = '.json';

  // In-memory storage for Web fallback
  static final Map<String, String> _webStorage = {};

  Future<String?> get _localPath async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/CableSimSaves';
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return path;
    } catch (e) {
      debugPrint('Storage path error: $e');
      return null;
    }
  }

  Future<List<String>> listSaveFiles() async {
    if (kIsWeb) {
      return _webStorage.keys.toList();
    }
    try {
      final path = await _localPath;
      if (path == null) return [];
      final dir = Directory(path);
      final List<FileSystemEntity> entities = await dir.list().toList();
      return entities
          .whereType<File>()
          .where((file) => file.path.endsWith(_extension))
          .map((file) => file.path.split(Platform.pathSeparator).last.replaceAll(_extension, ''))
          .toList();
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }

  Future<void> saveWorkspace({
    required String fileName,
    required List<DeviceNode> devices,
    required List<Cable> cables,
    required List<DeviceTemplate> customTemplates,
    required List<CableType> customCableTypes,
  }) async {
    final data = {
      'version': '1.1',
      'devices': devices.map((d) => d.toMap()).toList(),
      'cables': cables.map((c) => c.toMap()).toList(),
      'customTemplates': customTemplates.map((t) => t.toMap()).toList(),
      'customCableTypes': customCableTypes.map((ct) => ct.toMap()).toList(),
    };

    final jsonString = jsonEncode(data);

    if (kIsWeb) {
      _webStorage[fileName] = jsonString;
      return;
    }

    final path = await _localPath;
    if (path == null) return;
    final file = File('$path/$fileName$_extension');
    await file.writeAsString(jsonString);
  }

  Future<Map<String, dynamic>?> loadWorkspace(String fileName) async {
    try {
      String? jsonString;

      if (kIsWeb) {
        jsonString = _webStorage[fileName];
      } else {
        final path = await _localPath;
        if (path == null) return null;
        final file = File('$path/$fileName$_extension');
        if (await file.exists()) {
          jsonString = await file.readAsString();
        }
      }

      if (jsonString != null) {
        final Map<String, dynamic> data = jsonDecode(jsonString);

        final devices = (data['devices'] as List)
            .map((item) => DeviceNode.fromMap(item as Map<String, dynamic>))
            .toList();

        final cables = (data['cables'] as List)
            .map((item) => Cable.fromMap(item as Map<String, dynamic>))
            .toList();

        final customTemplates = (data['customTemplates'] as List?)
                ?.map((item) => DeviceTemplate.fromMap(item as Map<String, dynamic>))
                .toList() ??
            [];

        final customCableTypes = (data['customCableTypes'] as List?)
                ?.map((item) => CableType.fromMap(item as Map<String, dynamic>))
                .toList() ??
            [];

        return {
          'devices': devices,
          'cables': cables,
          'customTemplates': customTemplates,
          'customCableTypes': customCableTypes,
        };
      }
    } catch (e) {
      debugPrint('Error loading workspace: $e');
    }
    return null;
  }

  Future<void> deleteSave(String fileName) async {
    if (kIsWeb) {
      _webStorage.remove(fileName);
      return;
    }
    final path = await _localPath;
    if (path == null) return;
    final file = File('$path/$fileName$_extension');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
