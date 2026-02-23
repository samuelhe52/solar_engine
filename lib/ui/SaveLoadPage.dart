import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_engine/controller/CGController.dart';
import 'package:solar_engine/controller/SaveLoadController.dart';
import 'package:solar_engine/ui/CGPage.dart';

class SaveLoadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SaveLoadController>(() => SaveLoadController());
  }
}

class SaveLoadPage extends StatelessWidget {
  // 使用 Get.put 实例化控制器，并使其在整个应用程序中可用
  late final SaveLoadController controller;
  final bool isSave;
  SaveLoadPage({super.key, required this.isSave}) {
    controller = Get.find<SaveLoadController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSave ? "Save" : "Load"),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.saveCount.value,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Save Slot ${index + 1}'),
                    subtitle: Text(controller.savedGames[index]),
                    onTap: () async {
                      final confirmed = await Get.dialog<bool>(
                        AlertDialog(
                          title: Text(isSave ? "Save Game" : "Load Game"),
                          content: Text(
                            isSave
                                ? "Do you want to save the game in this slot?"
                                : "Do you want to load the game from this slot?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: Text('Confirm'),
                            ),
                          ],
                        ),
                        barrierDismissible: true,
                      );

                      if (confirmed == true) {
                        if (isSave) {
                          controller.save_game(
                            "Saved at ${DateTime.now()}",
                            index + 1,
                          );
                        } else {
                          await controller.load_game(index + 1);
                        }
                        if (Get.isRegistered<CGController>()) {
                          Get.back();
                        } else {
                          Get.to(
                            () => CGPage(
                              firstLoad: true,
                            ),
                            binding: CGBinding(),
                          ); // 关闭 SaveLoadPage，返回上一页
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Visibility(
        visible: isSave,
        child: FloatingActionButton(
          onPressed: () {
            controller.save_game(
              "Saved at ${DateTime.now()}",
              controller.saveCount.value + 1,
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
