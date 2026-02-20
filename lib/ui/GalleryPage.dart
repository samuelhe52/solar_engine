import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_engine/controller/GalleryController.dart';

class GalleryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GalleryController>(() => GalleryController());
  }
}

class GalleryPage extends StatelessWidget {
  // 使用 Get.put 实例化控制器，并使其在整个应用程序中可用
  late final GalleryController controller;

  GalleryPage({super.key}) {
    controller = Get.find<GalleryController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: Text('This is the Gallery Page.\nNothing is complete yet.'),
      ),
    );
  }
}
