import 'package:get/get.dart';
import 'package:solar_engine/backend/game.dart';

class HomePageController extends GetxController {
  late final GameEngine _gameEngine;
  HomePageController() {
    _gameEngine = Get.put(GameEngine()); // 在控制器中实例化 GameEngine，并使其在整个应用程序中可用
  }
  @override
  void onInit() {
    super.onInit();
    _gameEngine.initialize(); // 初始化游戏引擎
  }

  Future<void> load_default_scenario() async {
    // 加载默认场景的逻辑
    _gameEngine.currentScenario = await _gameEngine.explain_scenario(
      await _gameEngine.load_game_from_save(_gameEngine.defaultSavePath),
    );
  }
}
