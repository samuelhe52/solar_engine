//
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class GameEngine {
  final String gameName = "";
  final String gameVersion = "";
  final String gameAuthor = "";
  final settingsFilePath = 'assets/default/settings.json';
  GameFileManager fileManager = GameFileManager();
  GameEngine() {
    print("nothing to do");
  }
  void init_game() {
    // 读取设置文件
    File(settingsFilePath)
        .readAsString()
        .then((String contents) {
          Map<String, dynamic> settings = jsonDecode(contents);
          print("Game Name: ${settings['gameName']}");
          print("Game Version: ${settings['gameVersion']}");
          print("Game Author: ${settings['gameAuthor']}");
        })
        .catchError((error) {
          print("Error reading settings file: $error");
        });
  }
}

class GameFileManager {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/savegame.json');
  }

  Future<Map<String, dynamic>> readGameData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        String contents = await file.readAsString();
        return jsonDecode(contents);
      } else {
        return {};
      }
    } catch (e) {
      print("Error reading game data: $e");
      return {};
    }
  }

  Future<void> writeGameData(Map<String, dynamic> data) async {
    try {
      final file = await _localFile;
      String jsonData = jsonEncode(data);
      await file.writeAsString(jsonData);
    } catch (e) {
      print("Error writing game data: $e");
    }
  }
}
