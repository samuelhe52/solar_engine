import 'dart:async';

import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:solar_engine/backend/game.dart';

class CGController extends GetxController {
  final GameEngine _gameEngine = Get.find<GameEngine>();

  Timer? _fastForwardTimer;
  Timer? _autoModeTimer;
  var _isAdvancing = false;
  var isFastForwarding = false.obs;
  var currentIndex = 0.obs;
  var currentScenarios = <TextUnion>[];
  var currentScenario = Rx<TextUnion>(TextUnion());
  var charactersName = "".obs;
  var backgroundImagePath = "".obs;
  var audioPath = "";
  var scenarioPath = "";
  var isAutoMode = false.obs;
  var barIsHiden = false.obs;
  var isHistoryMode = false.obs;
  var isMute = false.obs;
  var is_text_animating = false;
  List<String> history = [];
  List<String> histroy_characters = [];
  final AudioPlayer characterPlayer = AudioPlayer();
  final AudioPlayer bgmPlayer = AudioPlayer();
  CGController() {
    logger.info("Initializing CGController");
    currentScenarios = _gameEngine.currentScenario;
    currentIndex.value = _gameEngine.gameIndex;
    scenarioPath = _gameEngine.scenarioPath;
    _autoModeTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (isAutoMode.value) {
        if (!is_text_animating && !await is_character_audio_playing()) {
          next();
        }
      }
    });
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
    all_stop();
    if (_fastForwardTimer?.isActive ?? false) {
      return;
    }
    isFastForwarding.value = true;
    _fastForwardTimer = Timer.periodic(interval, (_) {
      _advanceStep();
    });
  }

  void stop_auto_mode() {
    if (isAutoMode.value) switch_auto_mode();
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
      history.add(currentScenario.value.text);
      histroy_characters.add(charactersName.value);
      is_text_animating = true;
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

  Future<bool> is_character_audio_playing() async {
    bool isPlaying = false;
    characterPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        isPlaying = true;
      } else {
        isPlaying = false;
      }
    });
    return isPlaying;
  }

  void switch_hide_status() {
    barIsHiden.value = !barIsHiden.value;
  }

  void switch_auto_mode() {
    isAutoMode.value = !isAutoMode.value;
  }

  void stop_hiden_bar() {
    if (barIsHiden.value) {
      switch_hide_status();
    }
  }

  void switch_mute() {
    isMute.value = !isMute.value;
    if (isMute.value) {
      characterPlayer.setVolume(0);
      bgmPlayer.setVolume(0);
    } else {
      characterPlayer.setVolume(1);
      bgmPlayer.setVolume(1);
    }
  }

  // stop auto,fastforward,hidenbar
  void all_stop() {
    stop_auto_mode();
    stopFastForward();
    stop_hiden_bar();
  }

  @override
  void onClose() {
    stopFastForward();
    _autoModeTimer?.cancel();
    characterPlayer.dispose();
    bgmPlayer.dispose();
    super.onClose();
  }
}
