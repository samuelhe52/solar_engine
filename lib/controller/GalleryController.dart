import 'package:get/get.dart';
import 'package:solar_engine/backend/game.dart';

class GalleryController extends GetxController {
  RxList<String> galleryState = [""].obs;
  late final GameEngine _gameEngine;
  GalleryController() {
    logger.info("Initializing GalleryController");
    _gameEngine = Get.find<GameEngine>();
    galleryState.value = List<String>.from(_gameEngine.globalState["cg"] ?? [""]);
  }
}
