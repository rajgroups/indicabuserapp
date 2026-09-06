import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_html/flutter_html.dart';
import '../controllers/cms_controller.dart';
import '../../../core/constants/Colors.dart';

class CmsView extends GetView<CmsController> {
  const CmsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final title = controller.title.value.isEmpty 
          ? (Get.arguments?['title'] ?? 'Page') 
          : controller.title.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Html(
                    data: controller.content.value,
                    style: {
                      "body": Style(
                        fontSize: FontSize(16.0),
                        color: Colors.black87,
                        lineHeight: LineHeight.number(1.5),
                      ),
                      "h1": Style(
                        fontSize: FontSize(24.0),
                        fontWeight: FontWeight.bold,
                      ),
                    },
                  ),
                ),
              ),
      );
    });
  }
}
