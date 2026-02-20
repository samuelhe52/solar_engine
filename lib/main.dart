// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ui/CGPage.dart';
import 'ui/GalleryPage.dart';
import 'ui/SettingsPage.dart';
import 'ui/SaveLoadPage.dart';

void main() {
  runApp(
    GetMaterialApp(
      // 将 MaterialApp 替换为 GetMaterialApp
      home: HomePage(),
    ),
  );
}

class HomePageController extends GetxController {}

class HomePage extends StatelessWidget {
  // 使用 Get.put 实例化控制器，并使其在整个应用程序中可用
  late final HomePageController controller;

  HomePage({super.key}) {
    if (Get.isRegistered<HomePageController>()) {
      controller = Get.find<HomePageController>();
    } else {
      controller = Get.put(HomePageController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('solar galgame engine')),
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
                onPressed: () => Get.to(() => CGPage(), binding: CGBinding()),
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
