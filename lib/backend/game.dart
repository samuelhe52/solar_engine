//
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

enum CommandType { text, image }

const int MaxCharacters = 5;
final logger = Logger('App');
void setupLogging() {
  // 设置根日志级别（接收所有级别）
  Logger.root.level = Level.ALL;

  // 添加控制台监听器
  Logger.root.onRecord.listen((record) {
    final message = '[${record.level.name}] ${record.time}: ${record.message}';
    debugPrint(message);
    if (record.error != null) {
      debugPrint('  └─ 错误: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('  └─ 堆栈: ${record.stackTrace}');
    }
  });
}

class TextUnion {
  int type = -1; // 0: text, 1: image
  String text = "";
  List<String> characters = ["", "", "", "", ""];
  String imagePath = "";
  List<String> actions = ["", "", "", "", ""];
  List<String> charactersPath = ["", "", "", "", ""];

  TextUnion();
  TextUnion.withParams(
    this.type, {
    this.text = "",
    List<String>? characters,
    this.imagePath = "",
    List<String>? actions,
  })  : characters = characters ?? [],
        actions = actions ?? [];
  void build_character_paths() {
    for (var i = 0; i < MaxCharacters; i++) {
      if (i < characters.length) {
        charactersPath[i] = path.join(
            "assets/characters/", "${characters[i]}_${actions[i]}.png");
      }
    }
  }
}

class GameEngine {
  final settingsFilePath = 'assets/default/settings.json';
  final scenario = "text.sce";
  Map<String, dynamic> settings = {};
  Map<String, dynamic> gameState = {};
  Map<String, dynamic> globeState = {};
  GameFileManager fileManager = GameFileManager();

  List<TextUnion> currentScenario = [];

  GameEngine();
  get totalSaves => globeState["SaveCount"];
  get scenarioPath => gameState["scenarioPath"];
  int get gameIndex => gameState["index"];
  set gameDescription(String description) =>
      gameState["description"] = description;
  set gameIndex(int index) => gameState["index"] = index;
  set setSavesCount(int count) => globeState["SaveCount"] = count;
  Future<void> initialize() async {
    logger.info("Initializing game engine");
    settings = await fileManager.read_json_from_file(
      await fileManager.safe_read_file(settingsFilePath),
    );
    globeState = await fileManager.read_json_from_file(
      await fileManager.safe_read_file("assets/default/globe_save.json"),
    );
  }

  Future<String> load_game_from_save(String savePath) async {
    // both update gameState and return scenario text
    gameState = await fileManager.read_json_from_file(
      await fileManager.safe_read_file(savePath),
    );
    final scenarioFile = await fileManager.safe_read_file(
      path.join(gameState["scenarioPath"], scenario),
    );
    logger.info(
      "Game loaded successfully from $savePath, scenario: ${gameState['scenarioPath']}",
    );
    savePath = gameState["scenarioPath"];
    return await fileManager.read_all_text_from_file(scenarioFile);
  }

  List<TextUnion> explain_scenario(String scenarioText) {
    logger.info("Explaining scenario text:\n$scenarioText");
    final commands = scenarioText.split("\n");
    List<TextUnion> results = [];
    for (var command in commands) {
      command = command.trim();
      if (command.isEmpty || command.startsWith("#")) continue;
      if (command.contains(":")) {
        final parts = command.split(":");
        final cmd = parts[0].trim();
        final arg = parts[1].trim();
        if (cmd == "background") {
          results.add(
            TextUnion.withParams(CommandType.image.index, imagePath: arg),
          );
        } else if (cmd.startsWith("`") && cmd.endsWith("`")) {
          // TODO explain values , other commands
        } else {
          var textUnion = TextUnion.withParams(
            CommandType.text.index,
            text: arg,
          );
          cmd.split(',').forEach((element) {
            final parts = element.split(' ');
            textUnion.characters.add(parts[0].trim());
            textUnion.actions.add(
              parts[1].trim().substring(
                    1,
                    parts[1].length - 1,
                  ), // remove parentheses
            );
          });
          textUnion.build_character_paths();
          results.add(textUnion);
          //results.add(TextUnion.withParams(0, text: arg, character: cmd));
        }
      } else if (command.startsWith("`") && command.endsWith("`")) {
        // TODO explain values , other commands
      } else {
        results.add(
          TextUnion.withParams(CommandType.text.index, text: command),
        );
      }
    }
    return results;
  }

  void save_game_to_file(String time, String description, int saveSlot) async {
    gameState["description"] = description;
    fileManager.write_json_to_file(
      await fileManager.safe_read_file("assets/saves/save$saveSlot.json"),
      gameState,
    );
    logger.info(
      "Game saved successfully to assets/saves/save$saveSlot.json, scenario: ${gameState['scenarioPath']}",
    );
  }
}

class GameFileManager {
  Future<File> safe_read_file(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file;
      } else {
        throw Exception("File not found: $path");
      }
    } catch (e) {
      logger.severe("Error reading file: $e");
      rethrow;
    }
  }

  Future<String> read_all_text_from_file(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      logger.severe("Error reading text from file: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> read_json_from_file(File file) async {
    try {
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      logger.severe("Error parsing JSON from file: $e");
      rethrow;
    }
  }

  Future<void> write_json_to_file(File file, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
    } catch (e) {
      logger.severe("Error writing JSON to file: $e");
      rethrow;
    }
  }
}
