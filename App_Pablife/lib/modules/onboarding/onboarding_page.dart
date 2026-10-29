import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/edge_button_rounded.dart';
import '../../widgets/design_system/text_default.dart';
import '../auth/pages/email_input_page.dart';
import 'onboarding_controller.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const route = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.second,
      body: GetBuilder<OnboardingController>(
        builder: (controller) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: _ProgressIndicator(
                    currentPage: controller.currentPage,
                    totalPages: controller.onboardingPages.length,
                    onSkip: controller.skipOnboarding,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: (index) {
                      controller.currentPage = index;
                      controller.update();
                    },
                    itemCount: controller.onboardingPages.length,
                    itemBuilder: (context, index) {
                      final page = controller.onboardingPages[index];
                      return _OnboardingSlide(
                        title: page.title,
                        description: page.description,
                        imagePath: page.imagePath,
                      );
                    },
                  ),
                ),
                // const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _BottomButtons(onNext: controller.nextPage),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onSkip;

  const _ProgressIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextDefault(
              '${currentPage + 1}/$totalPages',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.aquaText,
            ),
            Opacity(
              opacity: 0.56,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const TextDefault(
                  'Pular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.aquaText.withAlpha(30),
            borderRadius: BorderRadius.circular(2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final itemWidth = totalWidth / totalPages;
              final leftPosition = currentPage * itemWidth;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: leftPosition,
                    child: Container(
                      width: itemWidth,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.aquaText,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: Image.asset(imagePath, fit: BoxFit.fitWidth)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextDefault(
            title,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.aquaText,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Opacity(
            opacity: 0.56,
            child: TextDefault(
              description,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomButtons extends StatelessWidget {
  final VoidCallback onNext;

  const _BottomButtons({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EdgeButtonRounded(text: 'Continuar', onTap: onNext),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Get.toNamed(EmailInputPage.route);
            },
            child: Opacity(
              opacity: 0.56,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Column(
                  children: [
                    TextDefault(
                      'Não tem conta?',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      textAlign: TextAlign.center,
                    ),
                    TextDefault(
                      'Cadastrar agora',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
