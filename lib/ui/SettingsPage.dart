import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            onPressed: () {
              controller.save_settings();
              Get.back();
            },
            icon: Icon(Icons.arrow_back),
          ),
        ),
        body: KeyboardTackle(
          child: Row(
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
        ));
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
        child: Column(
          children: [
            TextButton(
              child: Text('Reset All Settings'),
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: Text('Reset Settings'),
                    content:
                        Text('Are you sure you want to reset all settings?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          controller.reset_settings();
                          Get.back();
                        },
                        child: Text('Confirm'),
                      ),
                    ],
                  ),
                );
              },
            )
          ],
        ));
  }
}

class DisplaySettingsPage extends StatelessWidget {
  late final SettingsController controller;
  final dialogDockFormKey = GlobalKey<FormState>();
  final _characterRowFormKey = GlobalKey<FormState>();
  DisplaySettingsPage({super.key}) {
    controller = Get.find<SettingsController>();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        children: [
          Expanded(
              child: Form(
            key: dialogDockFormKey,
            child: TextFormField(
              autofocus: true,
              initialValue: controller.dialogDockHeight.value.toString(),
              decoration: InputDecoration(
                labelText: 'Dialog Dock Height (Relative to Screen Height)',
                hintText: 'Enter a value between 0 and 1',
              ),
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final parsedValue = double.tryParse(value ?? '');
                return controller.CheckHeightText(parsedValue)
                    ? null
                    : 'Please enter a valid number between 0 and 1';
              },
              onFieldSubmitted: (value) {
                final parsedValue = double.tryParse(value);
                controller.updateDialogDockHeight(parsedValue);
              },
            ),
          )),
          Expanded(
              child: Form(
            key: _characterRowFormKey,
            child: TextFormField(
              autofocus: true,
              initialValue: controller.characterRowHeight.value.toString(),
              decoration: InputDecoration(
                labelText: 'Character Row Height (Relative to Screen Height)',
                hintText: 'Enter a value between 0 and 1',
              ),
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final parsedValue = double.tryParse(value ?? '');
                return controller.CheckHeightText(parsedValue)
                    ? null
                    : 'Please enter a valid number between 0 and 1';
              },
              onFieldSubmitted: (value) {
                final parsedValue = double.tryParse(value);
                controller.updateCharacterRowHeight(parsedValue);
              },
            ),
          )),
        ],
      ),
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
        child: Column(children: [
          Expanded(
              child: Obx(() => Column(
                    children: [
                      Text('Text Animation Speed (ms per character)'),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                                min: 1,
                                max: 100,
                                divisions: 99,
                                value: controller.textAnimationSpeed.value
                                    .toDouble(),
                                label:
                                    "${controller.textAnimationSpeed.value}  ms/character",
                                onChanged: (value) {
                                  controller
                                      .updateTextAnimationSpeed(value.toInt());
                                }),
                          ),
                          Expanded(
                              child: AnimatedTextKit(
                            isRepeatingAnimation: true,
                            repeatForever: true,
                            animatedTexts: [
                              TyperAnimatedText(
                                "我能吞下玻璃而不伤身体",
                                speed: Duration(
                                    milliseconds:
                                        controller.textAnimationSpeed.value),
                                textStyle: TextStyle(
                                  decoration: TextDecoration.none,
                                ),
                              )
                            ],
                          ))
                        ],
                      )
                    ],
                  )))
        ]));
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

class KeyboardTackle extends StatefulWidget {
  final Widget child;
  const KeyboardTackle({super.key, required this.child});
  @override
  State<KeyboardTackle> createState() => _KeyboardTackleState();
}

class _KeyboardTackleState extends State<KeyboardTackle> {
  late final SettingsController controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SettingsController>();
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
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        controller.save_settings();
        Get.back();
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
      child: widget.child,
    );
  }
}
