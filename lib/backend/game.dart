//
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'branches.dart';

enum CommandType { text, image, audio, cg, jump, branches }

const characterPath = "assets/characters/";
const imagePath = "assets/images/";
const audioPath = "assets/audio/";

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
  int type = -1; // 0: text
  String text = "";
  String charactersAudioPath = "";

  List<String> characters = ["", "", "", "", ""];
  List<String> actions = ["", "", "", "", ""];
  List<String> charactersPath = ["", "", "", "", ""];
  TextUnion.withParams(
    this.type, {
    this.text = "",
    List<String>? characters,
    List<String>? actions,
  })  : characters = characters ?? [],
        actions = actions ?? [];
  void build_character_paths() {
    for (var i = 0; i < MaxCharacters; i++) {
      if (i < characters.length) {
        charactersPath[i] =
            path.join(characterPath, "${characters[i]}_${actions[i]}.png");
      }
    }
  }
}

class ResourceUnion {
  int type = -1; // 1 : image , 2: audio ,3 image and cg
  String resourcePath = "";
  ResourceUnion(this.type, this.resourcePath);
  ResourceUnion.withParams(this.type, {required this.resourcePath});
}

class chooseUnion {
  int type = -1; // 5 jump ,6 branches
  String id = ""; // for branches
  List<String> sourceList = [];
  chooseUnion(this.sourceList);
  chooseUnion.withParams(this.type, {required this.sourceList});
}

class GameEngine {
  final settingsAssetPath = 'assets/default/settings.json';
  final globalSaveAssetPath = 'assets/default/globe_save.json';
  final defaultSaveAssetPath = 'assets/default/save.json';
  late final String savePath;
  late final String rootPath;
  late final String globalSavePath;
  late final String settingsPath;
  late final String defaultSavePath;
  Map<String, dynamic> settings = {};
  Map<String, dynamic> gameState = {};
  Map<String, dynamic> globalState = {};
  Set<String> cgSet = {};
  GameFileManager fileManager = GameFileManager();

  List<dynamic> currentScenario = [];

  GameEngine();
  int get totalSaves => globalState["SaveCount"];
  String get scenarioPath => gameState["scenarioPath"];
  int get gameIndex => gameState["index"];
  String get gameBackground => gameState["background"];
  String get gameAudio => gameState["audio"];

  set gameDescription(String description) =>
      gameState["description"] = description;
  set gameIndex(int index) => gameState["index"] = index;
  set setSavesCount(int count) => globalState["SaveCount"] = count;
  set setBackground(String path) => gameState["background"] = path;
  set setAudio(String path) => gameState["audio"] = path;
  Future<void> initialize() async {
    logger.info("Initializing game engine");
    await environment_check();
    settings = await fileManager.read_json_from_file(
      await fileManager.safe_read_file(settingsPath),
    );
    globalState = await fileManager.read_json_from_file(
      await fileManager.safe_read_file(globalSavePath),
    );
    cgSet = {...globalState["cg"]};
  }

  Future<void> add_cg_to_state(String path) async {
    if (!cgSet.contains(path)) {
      cgSet.add(path);
      globalState["cg"].add(path);
      fileManager.safe_read_file(globalSavePath).then((file) {
        fileManager.write_json_to_file(file, globalState);
      });
    }
  }

  String saveSlotPath(int saveSlot) =>
      path.join(savePath, "save$saveSlot.json");
  Future<void> environment_check() async {
    logger.info("Performing environment check");

    try {
      final directory = await getApplicationDocumentsDirectory();
      logger.info("Documents directory: ${directory.path}");
      rootPath = path.join(directory.path, "solar_engine");
      if (!await fileManager.directory_exists(rootPath)) {
        await Directory(rootPath).create(recursive: true);
      }
      savePath = path.join(rootPath, "saves");

      if (!await fileManager.directory_exists(savePath)) {
        await Directory(savePath).create(recursive: true);
      }
      globalSavePath = path.join(savePath, "globe_save.json");
      settingsPath = path.join(rootPath, "settings.json");
      defaultSavePath = path.join(savePath, "default_save.json");
      await fileManager.check_and_copy(globalSaveAssetPath, globalSavePath);
      await fileManager.check_and_copy(settingsAssetPath, settingsPath);
      await fileManager.check_and_copy(defaultSaveAssetPath, defaultSavePath);
    } catch (e) {
      logger.severe("Environment check failed: $e");
    }
  }

  Future<List<String>> get_all_save_decriptions() async {
    List<String> descriptions = [];
    for (int i = 1; i <= totalSaves; i++) {
      final filePath = saveSlotPath(i);
      if (!await fileManager.file_exists_and_not_empty(filePath)) {
        setSavesCount = i - 1; // 更新保存游戏数量
        logger
            .warning("Save slot $i does not exist or is empty. Stopping scan.");
        break;
      }
      descriptions.add(
        (await fileManager.read_json_from_file(
          await fileManager.safe_read_file(filePath),
        ))["description"]
            .toString(),
      );
    }
    return descriptions;
  }

  Future<String> load_game_from_save(
    String savePath,
  ) async {
    // both update gameState and return scenario text
    gameState = await fileManager.read_json_from_file(
      await fileManager.safe_read_file(savePath),
    );
    logger.info(
      "Game loaded successfully from $savePath, scenario: ${gameState['scenarioPath']}",
    );
    return await rootBundle.loadString(
      path.join(gameState["scenarioPath"], gameState["scenario"]),
    );
  }

  Future<List<dynamic>> explain_scenario(String scenarioText) async {
    logger.info("Explaining scenario text:\n$scenarioText");
    final commands = scenarioText.split("\n");
    List<dynamic> results = [];
    for (var command in commands) {
      command = command.trim();
      if (command.isEmpty || command.startsWith("#")) continue;
      if (command.contains(":")) {
        final parts = command.split(":");
        final cmd = parts[0].trim();
        final arg = parts[1].trim();
        if (cmd.startsWith("background")) {
          if (cmd.lastIndexOf("(cg)") > 0) {
            results.add(ResourceUnion.withParams(CommandType.cg.index,
                resourcePath: arg));
          } else {
            results.add(ResourceUnion.withParams(CommandType.image.index,
                resourcePath: arg));
          }
        } else if (cmd == "audio") {
          results.add(ResourceUnion.withParams(CommandType.audio.index,
              resourcePath: arg));
        } else if (cmd.startsWith("`") && cmd.endsWith("`")) {
          // TODO explain values , other commands
        } else if (cmd.startsWith("jump")) {
          // TODO jump command
          results.add(chooseUnion.withParams(
            CommandType.jump.index,
            sourceList: arg.split(',').map((e) => e.trim()).toList(),
          ));
        } else if (cmd.startsWith("branches")) {
          String id = cmd.split(' ')[1];
          results.add(chooseUnion.withParams(
            CommandType.branches.index,
            sourceList: arg.split(',').map((e) => e.trim()).toList(),
          )..id = id);
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
          final audioPath =
              path.join(scenarioPath, "${results.length + 1}.mp3");
          textUnion.charactersAudioPath =
              await fileManager.file_exists_and_not_empty(audioPath)
                  ? audioPath
                  : "";

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

  Future<void> select_branch(String branchID, int index) async {
    // TODO implement branch selection logic
    logger.info("Branch selected: index $index");
    final branches = currentScenario[gameIndex].sourceList;
    if (index < 0 || index >= branches.length) {
      logger
          .warning("Branch index $index out of range for branches: $branches");
      return;
    }
    final selectedBranch = branches[index];
    logger.info("Selected branch: $selectedBranch");
    BranchesDecide.branches_tackle(
        branchID, index, gameState["variables"], globalState["variables"]);
  }

  Future<void> jump_to_scenario(List<String> jumpScenarioPath) async {
    int index = BranchesDecide.jump_decide(gameState["scenario"],
        gameState["variables"], globalState["variables"]);
    if (index < jumpScenarioPath.length) {
      final scenarioText = await rootBundle.loadString(
        path.join(gameState["scenarioPath"], jumpScenarioPath[index]),
      );
      currentScenario = await explain_scenario(scenarioText);
      gameState["scenario"] = jumpScenarioPath[index];
      gameState["index"] = 0;
    } else {
      logger.warning(
          "Jump index $index out of range for jump paths: $jumpScenarioPath");
    }
  }

  Future<void> save_game_to_file(String time, int saveSlot) async {
    gameState["description"] = "$time\n${currentScenario[gameIndex].text}";
    fileManager.write_json_to_file(
      await fileManager.safe_read_file(saveSlotPath(saveSlot)),
      gameState,
    );
    logger.info(
      "Game saved successfully to ${path.join(savePath, "save$saveSlot.json")}, scenario: ${gameState['scenarioPath']}",
    );
    fileManager.write_json_to_file(
      await fileManager.safe_read_file(globalSavePath),
      globalState,
    );
  }

  Future<void> load_default_settings() async {
    final assetData = await rootBundle.loadString(settingsAssetPath);
    final defaultSettings = jsonDecode(assetData);
    settings = defaultSettings;
  }

  Future<void> save_settings() async {
    fileManager.write_json_to_file(
      await fileManager.safe_read_file(settingsPath),
      settings,
    );
    logger.info("Settings saved successfully to $settingsPath");
  }
}

class GameFileManager {
  Future<bool> directory_exists(String path) async {
    try {
      final directory = Directory(path);
      return directory.existsSync();
    } catch (e) {
      logger.severe("Error checking directory existence: $e");
      return false;
    }
  }

  Future<bool> file_exists_and_not_empty(String path) async {
    try {
      final file = File(path);
      return file.existsSync() && file.lengthSync() > 0;
    } catch (e) {
      logger.severe("Error checking file existence: $e");
      return false;
    }
  }

  Future<void> check_and_copy(String assetPath, String targetPath) async {
    try {
      //final assetPath = path.join(directory.path, "globe_state.json");
      if (!await file_exists_and_not_empty(targetPath)) {
        var file = await safe_read_file(targetPath);
        final assetData = await rootBundle.loadString(assetPath);
        file.writeAsStringSync(assetData);
      }
    } catch (e) {
      logger.severe("Error copying asset: $e");
      rethrow;
    }
  }

  Future<String> read_asset_as_string(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      logger.severe("Error reading asset as string: $e");
      rethrow;
    }
  }

  Future<File> safe_read_file(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file;
      } else {
        return await file.create();
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
