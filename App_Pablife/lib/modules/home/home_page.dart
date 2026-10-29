import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const route = '/home';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return controller.homePage ?? const SizedBox.shrink();
      },
    );
  }
}
