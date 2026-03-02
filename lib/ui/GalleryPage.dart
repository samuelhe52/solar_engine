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

  String _thumbnailAssetPath(String cgPath) {
    if (cgPath.trim().isEmpty) {
      return 'assets/images/default_cg.png';
    }
    if (cgPath.startsWith('assets/')) {
      return cgPath;
    }
    return 'assets/images/$cgPath';
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
      body: Obx(
        () => GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          itemCount: controller.galleryState.length,
          itemBuilder: (context, index) {
            final cgPath = controller.galleryState[index];
            final assetPath = _thumbnailAssetPath(cgPath);
            return Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                onTap: () {
                  Get.dialog(
                    Dialog(
                      child: InteractiveViewer(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/default_cg.png',
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/default_cg.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
