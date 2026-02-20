import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_engine/main.dart';
import 'package:solar_engine/ui/SettingsPage.dart';
import 'package:solar_engine/ui/SaveLoadPage.dart';
import 'package:solar_engine/controller/CGController.dart';

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

  CGPage({super.key}) {
    controller = Get.find<CGController>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/cg.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CharacterRow(
            name: ["wow", "test", "demo", "user", "player"],
            imagePath: [
              'assets/images/home.png',
              'assets/images/home.png',
              'assets/images/home.png',
              'assets/images/home.png',
              'assets/images/home.png',
            ],
          ),
          DialDock(),
        ],
      ),
    );
  }
}

class CharacterRow extends StatelessWidget {
  final List<String> name;
  final List<String> imagePath;

  const CharacterRow({super.key, required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.45, // 父容器高度的 40%
      alignment: Alignment.bottomCenter,
      child: Row(
        spacing: 5,
        children: [
          for (var i = 0; i < MaxCharacters; i++)
            AspectRatio(
              aspectRatio: 9 / 16, // 设定宽高比为 9:16
              child: Character(name: name[i], imagePath: imagePath[i]),
            ),
        ],
      ),
    );
  }
}

class Character extends StatelessWidget {
  final String name;
  final String imagePath;

  const Character({super.key, required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
    );
  }
}

class DialDock extends StatelessWidget {
  const DialDock({super.key});

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
              child: Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Character Name",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Text content goes here. This is a sample dialogue text to demonstrate the layout of the dialogue dock in the visual novel engine.",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    //TODO: skip function
                    onPressed: () {},
                    icon: Icon(Icons.skip_next),
                    color: Colors.white,
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
                    icon: Icon(Icons.title),
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
          ],
        ),
      ),
    );
  }
}
