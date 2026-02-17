// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(
    GetMaterialApp(
      // 将 MaterialApp 替换为 GetMaterialApp
      home: HomePage(),
    ),
  );
}

class CounterController extends GetxController {
  var count = 0.obs; // 使变量变得可观察

  void increment() {
    count.value++; // 增加数值
  }
}

class HomePage extends StatelessWidget {
  // 使用 Get.put 实例化控制器，并使其在整个应用程序中可用
  final CounterController controller = Get.put(CounterController());

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GetX 安装示例')),
      body: Center(
        // 使用 Obx 来监听 count 的变化并自动更新 UI
        child: Obx(
          () => Text(
            '你点击了 ${controller.count} 次',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment, // 点击时调用 increment 方法
        child: Icon(Icons.add),
      ),
    );
  }
}
