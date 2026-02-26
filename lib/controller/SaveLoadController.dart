import 'package:get/get.dart';
import 'package:solar_engine/backend/game.dart';

class SaveLoadController extends GetxController {
  late GameEngine _gameEngine;
  var loadedDescriptions = <String>[].obs; // 使用 RxList 来存储保存游戏列表
  var saveCount = 0.obs;
  SaveLoadController() {
    logger.info("Initializing SaveLoadController");
    _gameEngine = Get.find<GameEngine>(); // 获取 GameEngine 实例
    load_saved_games();
  }
  Future<void> load_saved_games() async {
    // 这里应该实现加载保存游戏列表的逻辑
    // 例如，读取保存游戏文件夹中的文件，并返回它们的名称或路径
    final descriptions = await _gameEngine.get_all_save_decriptions();
    loadedDescriptions.value = descriptions;
    saveCount.value = descriptions.length;
  }

  Future<void> load_game(int saveSlot) async {
    // 这里应该实现加载游戏的逻辑
    // 例如，读取指定路径的保存游戏文件，并将其内容加载到游戏引擎中
    _gameEngine.currentScenario = await _gameEngine.explain_scenario(
      await _gameEngine.load_game_from_save(_gameEngine.saveSlotPath(saveSlot)),
    );
  }

  Future<void> save_game(int saveSlot) async {
    // 这里应该实现保存游戏的逻辑
    if (saveSlot > _gameEngine.totalSaves) {
      _gameEngine.setSavesCount = saveSlot;
    }
    await _gameEngine.save_game_to_file(
      DateTime.now().toString(),
      saveSlot,
    );
    await load_saved_games(); // 刷新保存游戏列表
    // 例如，将当前游戏状态保存到指定路径的文件中
  }
}
