import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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

  Future<void> _writeSigils(List<SavedSigil> sigils) async {
    final file = await _localFile;
    final String jsonString = jsonEncode(
      sigils.map((e) => e.toJson()).toList(),
    );
    await file.writeAsString(jsonString);
  }
}
