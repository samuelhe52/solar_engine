import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_engine/main.dart';
import 'package:solar_engine/ui/SettingsPage.dart';
import 'package:solar_engine/ui/SaveLoadPage.dart';
import 'package:solar_engine/controller/CGController.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

const int MaxCharacters = 5;

class CGBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CGController>(() => CGController());
  }
}

class CGPage extends StatelessWidget {
  // 使用 Get.put 实例化控制器，并使其在整个应用程序中可用
  late final CGController controller;
  final bool firstLoad;

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
                      ? "assets/images/default_cg.png"
                      : controller.backgroundImagePath.value),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          CharacterRow(),
          DialDock(),
          NavigationContainer(),
        ],
      ),
    );
  }
}

class CharacterRow extends StatelessWidget {
  late final CGController controller;
  CharacterRow({super.key}) {
    controller = Get.find<CGController>();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.45, // 父容器高度的 40%
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
  DialDock({super.key}) {
    controller = Get.find<CGController>();
  }
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.25, // 父容器高度的 30%
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        color: Colors.black.withOpacity(0.5),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Obx(
                () => Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.charactersName.value,
                    style: TextStyle(color: Colors.white, fontSize: 18),
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
                          textStyle:
                              TextStyle(color: Colors.white, fontSize: 18),
                        )
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class NavigationContainer extends StatelessWidget {
  late final CGController controller;
  NavigationContainer({super.key}) {
    controller = Get.find<CGController>();
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
        child: Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Obx(
                      () => IconButton(
                        onPressed: () => controller.isFastForwarding.value
                            ? controller.stopFastForward()
                            : controller.startFastForward(),
                        icon: Icon(controller.isFastForwarding.value
                            ? Icons.pause
                            : Icons.skip_next),
                        color: Colors.white,
                      ),
                    ),
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
                      onPressed: () => Get.offAll(() => HomePage()),
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
            )));
  }
}
