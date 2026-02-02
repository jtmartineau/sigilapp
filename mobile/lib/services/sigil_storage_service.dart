import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/saved_sigil.dart';

class SigilStorageService {
  static const String _fileName = 'saved_sigils.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<List<SavedSigil>> loadSigils() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((e) => SavedSigil.fromJson(e)).toList();
    } catch (e) {
      // If error, return empty list
      return [];
    }
  }

  Future<void> saveSigil(SavedSigil sigil) async {
    final sigils = await loadSigils();
    sigils.add(sigil);
    await _writeSigils(sigils);
  }

  Future<void> deleteSigil(String id) async {
    final sigils = await loadSigils();
    sigils.removeWhere((s) => s.id == id);
    await _writeSigils(sigils);
  }

  Future<void> syncSigils(List<dynamic> apiSigils) async {
    final localSigils = await loadSigils();
    final directory = await getApplicationDocumentsDirectory();
    final List<SavedSigil> newLocalList = [];

    for (var item in apiSigils) {
      final String id = item['id'];
      final String? imageUrl = item['image'];

      SavedSigil? existing;
      try {
        existing = localSigils.firstWhere((s) => s.id == id);
      } catch (e) {
        existing = null;
      }

      String? imagePath;
      if (existing != null && await File(existing.imagePath).exists()) {
        imagePath = existing.imagePath;
      } else if (imageUrl != null) {
        try {
          String downloadUrl = imageUrl;
          // Fix localhost for Android Emulator
          if (Platform.isAndroid) {
            downloadUrl = downloadUrl
                .replaceAll('localhost', '10.0.2.2')
                .replaceAll('127.0.0.1', '10.0.2.2');
          }

          final response = await http.get(Uri.parse(downloadUrl));
          if (response.statusCode == 200) {
            final fileName = 'sigil_$id.png';
            final file = File('${directory.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);
            imagePath = file.path;
          }
        } catch (e) {
          print('Error downloading image: $e');
        }
      }

      if (imagePath != null) {
        newLocalList.add(
          SavedSigil(
            id: id,
            incantation: item['incantation'],
            imagePath: imagePath,
            dateCreated: DateTime.parse(item['created_at']),
          ),
        );
      }
    }

    await _writeSigils(newLocalList);
  }

  Future<void> _writeSigils(List<SavedSigil> sigils) async {
    final file = await _localFile;
    final String jsonString = jsonEncode(
      sigils.map((e) => e.toJson()).toList(),
    );
    await file.writeAsString(jsonString);
  }

  Future<void> clearSigils() async {
    final file = await _localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
