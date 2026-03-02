import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:solar_engine/backend/game.dart';
import 'package:solar_engine/main.dart';
import 'package:solar_engine/ui/SettingsPage.dart';
import 'package:solar_engine/ui/SaveLoadPage.dart';
import 'package:solar_engine/controller/CGController.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:solar_engine/controller/SettingsController.dart';

const int MaxCharacters = 5;

class CGBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CGController>(() => CGController());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}

class CGPage extends StatelessWidget {
  // 使用 Get.put 实例化控制器，并使其在整个应用程序中可用
  late final CGController controller;
  final bool firstLoad;
  final String defaultBackgroundImagePath = "assets/images/default_cg.png";
  final Duration scrollNextCooldown = Duration(milliseconds: 300);
  final RxInt _lastScrollNextMs = 0.obs;
  CGPage({super.key, required this.firstLoad}) {
    controller = Get.find<CGController>();
    if (firstLoad) {
      controller.load_initial_scenario();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        // 1. 判断是否是鼠标滚轮事件
        if (pointerSignal is PointerScrollEvent) {
          // 2. 获取滚动的偏移量
          if (!controller.isHistoryMode.value) {
            final scrollDelta = pointerSignal.scrollDelta;
            // 3. 根据滚动的方向和距离执行相应的操作
            logger.info("Pointer scroll detected: $scrollDelta");
            if (scrollDelta.dy > 0) {
              final nowMs = DateTime.now().millisecondsSinceEpoch;
              if (nowMs - _lastScrollNextMs.value <
                  scrollNextCooldown.inMilliseconds) {
                return;
              }
              _lastScrollNextMs.value = nowMs;
              // 向下滚动，执行下一步操作
              controller.all_stop();
              controller.next();
            } else if (scrollDelta.dy < 0) {
              controller.isHistoryMode.value = true;
              // 向上滚动，执行历史记录查看操作
            }
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          KeyboardTackle(
            child: Container(),
          ),
          Obx(
            () => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(controller.backgroundImagePath.value.isEmpty
                      ? defaultBackgroundImagePath
                      : controller.backgroundImagePath.value),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          CharacterRow(),
          Obx(() => Offstage(
                offstage: controller.barIsHiden.value,
                child: DialDock(),
              )),
          NavigationContainer(),
          Obx(() => Offstage(
                offstage: !controller.isHistoryMode.value,
                child: HistoryContainer(),
              )),
        ],
      ),
    );
  }
}

class CharacterRow extends StatelessWidget {
  late final CGController controller;
  late final SettingsController settingsController;

  CharacterRow({super.key}) {
    controller = Get.find<CGController>();
    settingsController = Get.find<SettingsController>();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: settingsController.characterRowHeight.value,
      alignment: Alignment.bottomLeft,
      child: Row(
        spacing: 5,
        children: [
          for (var i = 0; i < MaxCharacters; i++)
            Obx(
              () => Expanded(
                child: controller.currentScenario.value.charactersPath[i] != ""
                    ? Image.asset(
                        controller.currentScenario.value.charactersPath[i],
                        fit: BoxFit.contain,
                      )
                    : Container(),
              ),
            ),
        ],
      ),
    );
  }
}

class DialDock extends StatelessWidget {
  late final CGController controller;
  late final SettingsController settingsController;
  DialDock({super.key}) {
    controller = Get.find<CGController>();
    settingsController = Get.find<SettingsController>();
  }
  @override
  Widget build(BuildContext context) {
    return Obx(() => FractionallySizedBox(
          heightFactor: settingsController.dialogDockHeight.value, // 父容器高度的 30%
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            color: Colors.black.withAlpha(50),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.charactersName.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Expanded(
                    child: Container(
                  alignment: Alignment.topLeft,
                  child: Obx(
                    () => AnimatedTextKit(
                      key: ValueKey(controller.currentScenario.value.text),
                      displayFullTextOnTap: true,
                      isRepeatingAnimation: false,
                      onFinished: () => controller.is_text_animating = false,
                      animatedTexts: [
                        TyperAnimatedText(
                          controller.currentScenario.value.text,
                          speed: Duration(
                              milliseconds:
                                  settingsController.textAnimationSpeed.value),
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            decoration: TextDecoration.none,
                          ),
                        )
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ));
  }
}

class KeyboardTackle extends StatefulWidget {
  final Widget child;
  const KeyboardTackle({super.key, required this.child});
  @override
  State<KeyboardTackle> createState() => _KeyboardTackleState();
}

class _KeyboardTackleState extends State<KeyboardTackle> {
  late final CGController controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CGController>();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    final isCtrl = event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight;
    if (event is KeyDownEvent) {
      if (!controller.isHistoryMode.value) {
        if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          controller.all_stop();
          controller.next();
          return true;
        } else if (isCtrl) {
          controller.isFastForwarding.value
              ? controller.stopFastForward()
              : controller.startFastForward();
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
          Get.to(
            () => SaveLoadPage(isSave: true),
            binding: SaveLoadBinding(),
          );
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          Get.to(
            () => SaveLoadPage(isSave: false),
            binding: SaveLoadBinding(),
          );
          return true;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (controller.isHistoryMode.value) {
          controller.isHistoryMode.value = false;
        } else {
          Get.to(
            () => SettingsPage(),
            binding: SettingsBinding(),
          );
        }
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: widget.child);
  }
}

class NavigationContainer extends StatelessWidget {
  late final CGController controller;
  NavigationContainer({super.key}) {
    controller = Get.find<CGController>();
  }
  dynamic switch_hide_method(bool isMobile) {
    controller.stop_auto_mode();
    return isMobile
        ? () {
            controller.stopFastForward();
            controller.switch_hide_status();
          }
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          controller.all_stop();
          await controller.next();
        },
        onLongPressStart: (_) {
          controller.startFastForward();
        },
        onLongPressEnd: (_) {
          controller.stopFastForward();
        },
        // Use correct named gesture callbacks based on device type
        onDoubleTap: switch_hide_method(isMobileDevice()),
        onSecondaryTap: switch_hide_method(!isMobileDevice()),
        onVerticalDragUpdate: (details) {},
        child: Obx(() => Offstage(
            offstage: controller.barIsHiden.value,
            child: Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        //Obx(
                        IconButton(
                          onPressed: () => controller.isFastForwarding.value
                              ? controller.stopFastForward()
                              : controller.startFastForward(),
                          icon: Icon(controller.isFastForwarding.value
                              ? Icons.pause
                              : Icons.skip_next),
                          color: Colors.white,
                        ),
                        IconButton(
                          onPressed: () {
                            controller.all_stop();
                            controller.switch_auto_mode();
                          },
                          icon: Icon(Icons.auto_mode),
                          color: Colors.white,
                          style: ButtonStyle(
                            backgroundColor: controller.isAutoMode.value
                                ? WidgetStateColor.resolveWith(
                                    (states) => Colors.white.withAlpha(30))
                                : null,
                          ),
                        ),
                        IconButton(
                          //TODO: save page
                          onPressed: () {
                            controller.all_stop();
                            Get.to(
                              () => SaveLoadPage(isSave: true),
                              binding: SaveLoadBinding(),
                            );
                          },
                          icon: Icon(Icons.save),
                          color: Colors.white,
                        ),
                        IconButton(
                          //TODO: load page
                          onPressed: () {
                            controller.all_stop();
                            Get.to(
                              () => SaveLoadPage(isSave: false),
                              binding: SaveLoadBinding(),
                            );
                          },
                          icon: Icon(Icons.file_upload),
                          color: Colors.white,
                        ),
                        IconButton(
                          //TODO: volume control
                          onPressed: () => controller.switch_mute(),
                          icon: Icon(controller.isMute.value
                              ? Icons.volume_off
                              : Icons.volume_up),
                          color: Colors.white,
                        ),
                        IconButton(
                          //TODO: settings page
                          onPressed: () {
                            controller.all_stop();
                            Get.to(
                              () => SettingsPage(),
                              binding: SettingsBinding(),
                            );
                          },
                          icon: Icon(Icons.settings),
                          color: Colors.white,
                        ),
                        IconButton(
                          //return to home page
                          onPressed: () {
                            controller.all_stop();
                            Get.offAll(() => MainPage());
                          },
                          icon: Icon(Icons.home),
                          color: Colors.white,
                        ),
                        IconButton(
                          // TODO: hide/show dilaogue dock
                          onPressed: () {
                            controller.all_stop();
                            controller.switch_hide_status();
                          },
                          icon: Icon(Icons.hide_image),
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                )))));
  }
}

class HistoryContainer extends StatelessWidget {
  late final CGController controller;
  HistoryContainer({super.key}) {
    controller = Get.find<CGController>();
  }
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(150),
      child: Column(children: [
        Row(
          children: [
            IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                onPressed: () {
                  controller.isHistoryMode.value = false;
                }),
            Text(
              "History",
              style: TextStyle(color: Colors.white, fontSize: 18),
            )
          ],
        ),
        Expanded(
          child: ListView.builder(
              itemCount: controller.history.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(controller.histroy_characters[index],
                      style: TextStyle(color: Colors.white70, fontSize: 18)),
                  subtitle: Text(
                    controller.history[index],
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  onTap: () {
                    controller.play_character_audio(
                        controller.currentScenario.value.charactersAudioPath);
                  },
                );
              }),
        )
      ]),
    );
  }
}
