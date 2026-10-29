import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/widgets/app_logo.dart';
import '../../widgets/app_text_vector.dart';
import 'splash_controller.dart';
import '../../shared/themes/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const route = '/splash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aqua,
      body: GetBuilder<SplashController>(
        builder: (controller) {
          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLogo(),
                  const SizedBox(height: 32),
                  AppTextVector(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
