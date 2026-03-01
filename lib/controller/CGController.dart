import 'dart:async';

import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:solar_engine/backend/game.dart';

class CGController extends GetxController {
  final GameEngine _gameEngine = Get.find<GameEngine>();

  Timer? _fastForwardTimer;
  var _isAdvancing = false;
  var isFastForwarding = false.obs;
  var currentIndex = 0.obs;
  var currentScenarios = <TextUnion>[];
  var currentScenario = Rx<TextUnion>(TextUnion());
  var charactersName = "".obs;
  var backgroundImagePath = "".obs;
  var audioPath = "";
  var scenarioPath = "";
  var barIsHiden = false.obs;
  final AudioPlayer characterPlayer = AudioPlayer();
  final AudioPlayer bgmPlayer = AudioPlayer();
  CGController() {
    logger.info("Initializing CGController");
    currentScenarios = _gameEngine.currentScenario;
    currentIndex.value = _gameEngine.gameIndex;
    scenarioPath = _gameEngine.scenarioPath;
    updateStates();
  }
  Future<void> next() async {
    if (currentIndex.value < currentScenarios.length - 1) {
      currentIndex.value++;
      _gameEngine.gameIndex = currentIndex.value;
      await updateStates();
    } else {
      stopFastForward();
    }
  }

  void startFastForward(
      {Duration interval = const Duration(milliseconds: 120)}) {
    if (_fastForwardTimer?.isActive ?? false) {
      return;
    }
    isFastForwarding.value = true;
    _fastForwardTimer = Timer.periodic(interval, (_) {
      _advanceStep();
    });
  }

  void stopFastForward() {
    _fastForwardTimer?.cancel();
    _fastForwardTimer = null;
    isFastForwarding.value = false;
  }

  Future<void> _advanceStep() async {
    if (_isAdvancing) {
      return;
    }
    if (currentIndex.value >= currentScenarios.length - 1) {
      stopFastForward();
      return;
    }
    _isAdvancing = true;
    try {
      await next();
    } finally {
      _isAdvancing = false;
    }
  }

  Future<void> updateStates() async {
    currentScenario.value = currentScenarios[currentIndex.value];
    if (currentScenario.value.type == CommandType.image.index) {
      backgroundImagePath.value =
          scenarioPath + currentScenario.value.resourcePath;
      await next();
    } else if (currentScenario.value.type == CommandType.audio.index) {
      audioPath = scenarioPath + currentScenario.value.resourcePath;
      play_bgm(audioPath);

      await next();
    } else {
      _gameEngine.gameIndex = currentIndex.value;
      charactersName.value = currentScenario.value.characters.join(", ");
      play_character_audio(currentScenario.value.charactersAudioPath);
    }
  }

  void load_initial_scenario() {
    for (int i = currentIndex.value; i >= 0; i--) {
      if (currentScenarios[i].type == CommandType.image.index) {
        backgroundImagePath.value =
            scenarioPath + currentScenarios[i].resourcePath;
        break;
      } else if (currentScenarios[i].type == CommandType.audio.index) {
        audioPath = scenarioPath + currentScenarios[i].resourcePath;
        play_bgm(audioPath);
        break;
      }
    }
  }

  Future<void> play_bgm(String bgmPath) async {
    bgmPlayer.stop();
    await bgmPlayer.setSource(AssetSource(bgmPath));
    // 可以设置为循环播放
    bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> play_character_audio(String path) async {
    if (path.isEmpty) return;
    await characterPlayer.stop();
    await characterPlayer.play(AssetSource(path));
  }

  void swith_hide_status() {
    barIsHiden.value = !barIsHiden.value;
  }

  @override
  void onClose() {
    stopFastForward();
    super.onClose();
  }
}
