import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
  CGPage({super.key, required this.firstLoad}) {
    controller = Get.find<CGController>();
    if (firstLoad) {
      controller.load_initial_scenario();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        fit: StackFit.expand,
        children: [
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
            color: Colors.black.withOpacity(0.5),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
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
                ),
                Expanded(
                    flex: 6,
                    child: Container(
                      alignment: Alignment.topLeft,
                      child: Obx(
                        () => AnimatedTextKit(
                          key: ValueKey(controller.currentScenario.value.text),
                          displayFullTextOnTap: true,
                          isRepeatingAnimation: false,
                          animatedTexts: [
                            TyperAnimatedText(
                              controller.currentScenario.value.text,
                              speed: Duration(milliseconds: 10),
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

class NavigationContainer extends StatefulWidget {
  const NavigationContainer({super.key});

  @override
  State<NavigationContainer> createState() => _NavigationContainerState();
}

class _NavigationContainerState extends State<NavigationContainer> {
  late final CGController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CGController>();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  bool _handleKey(KeyEvent event) {
    final isCtrl = event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        controller.next();
        return true;
      } else if (isCtrl) {
        controller.isFastForwarding.value
            ? controller.stopFastForward()
            : controller.startFastForward();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Get.to(
          () => SettingsPage(),
          binding: SettingsBinding(),
        );
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

    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  dynamic switch_hide_method(bool isMobile) {
    return isMobile
        ? () {
            controller.stopFastForward();
            controller.swith_hide_status();
          }
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
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
                        //),
                        IconButton(
                          //TODO: save page
                          onPressed: () => Get.to(
                            () => SaveLoadPage(isSave: true),
                            binding: SaveLoadBinding(),
                          ),
                          icon: Icon(Icons.save),
                          color: Colors.white,
                        ),
                        IconButton(
                          //TODO: load page
                          onPressed: () => Get.to(
                            () => SaveLoadPage(isSave: false),
                            binding: SaveLoadBinding(),
                          ),
                          icon: Icon(Icons.file_upload),
                          color: Colors.white,
                        ),
                        IconButton(
                          //TODO: volume control
                          onPressed: () {},
                          icon: Icon(Icons.volume_up),
                          color: Colors.white,
                        ),
                        IconButton(
                          //TODO: settings page
                          onPressed: () => Get.to(
                            () => SettingsPage(),
                            binding: SettingsBinding(),
                          ),
                          icon: Icon(Icons.settings),
                          color: Colors.white,
                        ),
                        IconButton(
                          //return to home page
                          onPressed: () => Get.offAll(() => MainPage()),
                          icon: Icon(Icons.home),
                          color: Colors.white,
                        ),
                        IconButton(
                          // TODO: hide/show dilaogue dock
                          onPressed: () {},
                          icon: Icon(Icons.hide_image),
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                )))));
  }
}
