import 'package:get/get.dart';
import 'package:solar_engine/backend/game.dart';

class SaveLoadController extends GetxController {
  late GameEngine _gameEngine;
  var savedGames = <String>[].obs; // 使用 RxList 来存储保存游戏列表
  var saveCount = 0.obs;
  SaveLoadController() {
    logger.info("Initializing SaveLoadController");
    _gameEngine = Get.find<GameEngine>(); // 获取 GameEngine 实例
    load_saved_games().then((games) {
      savedGames.value = games; // 更新保存游戏列表
      saveCount.value = games.length; // 更新保存游戏数量
    });
  }
  Future<List<String>> load_saved_games() async {
    // 这里应该实现加载保存游戏列表的逻辑
    // 例如，读取保存游戏文件夹中的文件，并返回它们的名称或路径
    var saves = _gameEngine.totalSaves; // 访问 GameEngine 的 total_saves 属性
    List<String> descriptions = [];
    for (int i = 1; i <= saves; i++) {
      String filePath = "assets/saves/save$i.json";
      descriptions.add(
        (await _gameEngine.fileManager.read_json_from_file(
          await _gameEngine.fileManager.safe_read_file(filePath),
        ))["description"]
            .toString(),
      );
    }
    return descriptions;
  }

  Future<void> load_game(int saveSlot) async {
    // 这里应该实现加载游戏的逻辑
    // 例如，读取指定路径的保存游戏文件，并将其内容加载到游戏引擎中
    String savePath = "assets/saves/save$saveSlot.json";
    _gameEngine.currentScenario = _gameEngine.explain_scenario(
      await _gameEngine.load_game_from_save(savePath),
    );
  }

  Future<void> save_game(String description, int saveSlot) async {
    // 这里应该实现保存游戏的逻辑
    // 例如，将当前游戏状态保存到指定路径的文件中
    if (saveSlot > saveCount.value) {
      saveCount.value = saveSlot;
      _gameEngine.setSavesCount = saveSlot;
    }
    _gameEngine.save_game_to_file(
      DateTime.now().toString(),
      description,
      saveSlot,
    );
  }
}
