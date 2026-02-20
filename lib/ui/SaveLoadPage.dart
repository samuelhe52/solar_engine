import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SaveLoadController extends GetxController {}

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
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Save Slot ${index + 1}'),
                  subtitle: Text('Saved at 2024-06-01 12:00:00'),
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
                      // TODO: save/load logic
                      Get.back(); // 关闭 SaveLoadPage，返回上一页
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: Visibility(
        visible: isSave,
        child: FloatingActionButton(
          onPressed: () {
            // TODO : new save slot
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
