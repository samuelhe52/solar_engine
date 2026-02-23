import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:solar_engine/controller/SettingsController.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}

class SettingsPage extends StatelessWidget {
  // 使用 Get.put 实例化控制器，并使其在整个应用程序中可用
  late final SettingsController controller;
  final _controller = SidebarXController(selectedIndex: 0);
  final double sidebarWidthRatio = 0.2;
  SettingsPage({super.key}) {
    controller = Get.find<SettingsController>();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Row(
        children: [
          SidebarX(
            extendedTheme: SidebarXTheme(
              width: screenWidth * sidebarWidthRatio,
              margin: EdgeInsets.only(right: 10),
            ),
            headerBuilder: (context, extended) {
              return SizedBox(
                height: 100,
                child: Padding(padding: const EdgeInsets.all(16.0)),
              );
            },
            controller: _controller,
            items: const [
              SidebarXItem(icon: Icons.settings, label: 'General'),
              SidebarXItem(icon: Icons.display_settings, label: 'Display'),
              SidebarXItem(icon: Icons.text_snippet, label: 'Text'),
              SidebarXItem(icon: Icons.audio_file, label: 'Audio'),
            ],
          ),

          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                switch (_controller.selectedIndex) {
                  case 0:
                    return GeneralSettingsPage();
                  case 1:
                    return DisplaySettingsPage();
                  case 2:
                    return TextSettingsPage();
                  case 3:
                    return AudioSettingsPage();
                  default:
                    return Container(
                      color: Colors.grey[200],
                      child: Center(child: Text('? How did you get here?')),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GeneralSettingsPage extends StatelessWidget {
  late final SettingsController controller;
  GeneralSettingsPage({super.key}) {
    controller = Get.find<SettingsController>();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Text('General Settings')),
    );
  }
}

class DisplaySettingsPage extends StatelessWidget {
  late final SettingsController controller;
  DisplaySettingsPage({super.key}) {
    controller = Get.find<SettingsController>();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Text('Display Settings')),
    );
  }
}

class TextSettingsPage extends StatelessWidget {
  late final SettingsController controller;
  TextSettingsPage({super.key}) {
    controller = Get.find<SettingsController>();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Text('Text Settings')),
    );
  }
}

class AudioSettingsPage extends StatelessWidget {
  late final SettingsController controller;
  AudioSettingsPage({super.key}) {
    controller = Get.find<SettingsController>();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(child: Text('Audio Settings')),
    );
  }
}
