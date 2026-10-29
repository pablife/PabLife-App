import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../infra/models/onboarding_model.dart';
import '../auth/pages/email_input_page.dart';

class OnboardingController extends GetxController with LoaderManagerMixin {
  int currentPage = 0;
  PageController pageController = PageController();

  List<OnboardingModel> onboardingPages = [
    OnboardingModel(
      id: 1,
      title: 'Difícil se organizar no dia a dia?',
      description:
          'Conciliar saúde, metas pessoais e compromissos pode ser desafiador.',
      imagePath: 'assets/pages/onboarding/step_one.png',
    ),
    OnboardingModel(
      id: 2,
      title: 'Organize tudo em um só lugar',
      description:
          'Nosso app conecta você com especialistas e ajuda a acompanhar suas metas e bem-estar.',
      imagePath: 'assets/pages/onboarding/step_two.png',
    ),
    OnboardingModel(
      id: 3,
      title: 'Bem-estar que cabe na sua rotina',
      description:
          'Tenha um plano claro para alcançar seus objetivos com suporte profissional.',
      imagePath: 'assets/pages/auth/auth_banner.png',
      isLastPage: true,
    ),
  ];

  void nextPage() {
    if (currentPage < onboardingPages.length - 1) {
      currentPage++;
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      currentPage--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() {
    Get.offAllNamed(EmailInputPage.route);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
