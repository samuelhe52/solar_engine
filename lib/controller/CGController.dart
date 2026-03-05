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
  var currentScenarios = <dynamic>[];
  var currentScenario = Rx<dynamic>(null);
  var charactersName = "".obs;
  var backgroundImagePath = "".obs;
  var bgmPath = "";
  var scenarioPath = "";
  var isAutoMode = false.obs;
  var barIsHiden = false.obs;
  var isHistoryMode = false.obs;
  var isMute = false.obs;
  var isTextAnimating = false;
  var isChooseBranch = false.obs;
  var inputText = "".obs;
  var characterVoiceVolume = 100.obs; // percentage
  var musicVolume = 100.obs; // percentage
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
        if (!isTextAnimating && !await is_character_audio_playing()) {
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
    if (currentScenario.value.type == CommandType.image.index ||
        currentScenario.value.type == CommandType.cg.index) {
      backgroundImagePath.value =
          imagePath + currentScenario.value.resourcePath;
      _gameEngine.setBackground = currentScenario.value.resourcePath;
      if (currentScenario.value.type == CommandType.cg.index) {
        _gameEngine.add_cg_to_state(currentScenario.value.resourcePath);
      }
      await next();
    } else if (currentScenario.value.type == CommandType.audio.index) {
      bgmPath = audioPath + currentScenario.value.resourcePath;
      if (_gameEngine.gameAudio.trim().isNotEmpty) {
        play_bgm(bgmPath);
      }
      _gameEngine.setAudio = audioPath;

      await next();
    } else if (currentScenario.value.type == CommandType.jump.index) {
      await _gameEngine.jump_to_scenario(currentScenario.value.sourceList);
      currentIndex.value = 0;
      currentScenarios = _gameEngine.currentScenario;
      await updateStates();
    } else if (currentScenario.value.type == CommandType.branches.index ||
        currentScenario.value.type == CommandType.input.index) {
      // do nothing,wait for user to select branch
      all_stop();
      if (currentScenario.value.type == CommandType.input.index) {
        inputText.value = currentScenario.value.text;
      }
      isChooseBranch.value = true;
    } else {
      _gameEngine.gameIndex = currentIndex.value;
      charactersName.value = currentScenario.value.characters.join(", ");
      play_character_audio(currentScenario.value.charactersAudioPath);
      history.add(currentScenario.value.text);
      histroy_characters.add(charactersName.value);
      isTextAnimating = true;
    }
  }

  void load_initial_scenario() {
    backgroundImagePath.value = imagePath + _gameEngine.gameBackground;
    bgmPath = audioPath + _gameEngine.gameAudio;
    if (_gameEngine.gameAudio.trim().isNotEmpty) {
      play_bgm(bgmPath);
    }
  }

  Future<void> play_bgm(String bgmPath) async {
    await bgmPlayer.stop();
    // 可以设置为循环播放
    bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await bgmPlayer.play(AssetSource(bgmPath),
        volume: isMute.value ? 0 : musicVolume.value / 100);
  }

  Future<void> play_character_audio(String path) async {
    if (path.isEmpty) return;
    await characterPlayer.stop();
    await characterPlayer.play(AssetSource(path),
        volume: isMute.value ? 0 : characterVoiceVolume.value / 100);
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
      characterPlayer.setVolume(characterVoiceVolume.value / 100);
      bgmPlayer.setVolume(musicVolume.value / 100);
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

  Future<void> select_branch(int index) async {
    isChooseBranch.value = false;
    // Handle branch selection logic here
    await _gameEngine.select_branch(currentScenario.value.id, index);
    await next();
    updateStates();
  }

  Future<void> select_input(String input) async {
    isChooseBranch.value = false;
    // Handle input logic here
    await _gameEngine.select_input(currentScenario.value.id, input);
    await next();
    updateStates();
  }
}
