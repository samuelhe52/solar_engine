// main.dart
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'ui/CGPage.dart';
import 'ui/GalleryPage.dart';
import 'ui/SettingsPage.dart';
import 'ui/SaveLoadPage.dart';
import 'controller/HomeController.dart';
import 'backend/game.dart';

void main() {
  setupLogging();
  WidgetsFlutterBinding.ensureInitialized();
  // 锁定为横屏 （左右两个方向）
  if (isMobileDevice()) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]).then((_) {
      runApp(buildApp());
    });
  } else {
    // 非移动端直接运行，不锁定方向
    runApp(buildApp());
  }
}

Widget buildApp() {
  return GetMaterialApp(
    home: MainPage(),
    builder: (context, child) {
      if (!isMobileDevice()) {
        return child ?? const SizedBox.shrink();
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          var targetWidth = maxWidth;
          var targetHeight = targetWidth * 9 / 16;
          if (targetHeight > maxHeight) {
            targetHeight = maxHeight;
            targetWidth = targetHeight * 16 / 9;
          }
          return Center(
            child: SizedBox(
              width: targetWidth,
              height: targetHeight,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      );
    },
  );
}

bool isMobileDevice() {
  if (kIsWeb) return false; // Web 环境（包括手机浏览器）不算
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}

class MainPage extends StatelessWidget {
  late final HomePageController controller;
  MainPage({super.key}) {
    if (Get.isRegistered<HomePageController>()) {
      controller = Get.find<HomePageController>();
    } else {
      controller = Get.put(HomePageController());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              ElevatedButton(
                onPressed: () {
                  controller.load_default_scenario().then((_) {
                    Get.to(
                        () => CGPage(
                              firstLoad: false,
                            ),
                        binding: CGBinding());
                  });
                },
                child: Text('Start game'),
              ),
              ElevatedButton(
                onPressed: () => Get.to(
                  () => SaveLoadPage(isSave: false),
                  binding: SaveLoadBinding(),
                ),
                child: Text('Continue game'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Get.to(() => GalleryPage(), binding: GalleryBinding()),
                child: Text('Gallery'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Get.to(() => SettingsPage(), binding: SettingsBinding()),
                child: Text('Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
