import 'package:get/get.dart';
import 'package:solar_engine/backend/game.dart';

class SettingsController extends GetxController {
  var dialogDockHeight = 0.25.obs;
  var characterRowHeight = 0.45.obs;
  late final GameEngine _gameEngine;
  SettingsController() {
    _gameEngine = Get.find<GameEngine>();
    dialogDockHeight.value = _gameEngine.settings['DockHeight'];
    characterRowHeight.value = _gameEngine.settings['CharacterRowHeight'];
    logger.info("Initializing SettingsController");
  }
  bool CheckHeightText(double? value) {
    if (value != null && value > 0 && value < 1) return true;
    return false;
  }

  Future<void> updateDialogDockHeight(double? value) async {
    if (CheckHeightText(value)) {
      dialogDockHeight.value = value!;
      _gameEngine.settings['DockHeight'] = value;
      _gameEngine.save_settings();
    }
  }

  Future<void> updateCharacterRowHeight(double? value) async {
    if (CheckHeightText(value)) {
      characterRowHeight.value = value!;
      _gameEngine.settings['CharacterRowHeight'] = value;
      _gameEngine.save_settings();
    }
  }
}
