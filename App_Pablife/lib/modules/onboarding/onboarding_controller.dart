import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../shared/mixins/loader_manager.dart';
import '../../shared/themes/app_palette.dart';
import '../auth/pages/choose_profile_page.dart';
import 'widgets/onboarding_background.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final String imagePath;
  final String imageDescription;
  final String buttonLabel;
  final OnboardingScene scene;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.imageDescription,
    required this.buttonLabel,
    required this.scene,
  });
}

class OnboardingController extends GetxController with LoaderManagerMixin {
  int currentPage = 0;

  final List<OnboardingSlide> slides = const [
    OnboardingSlide(
      title: 'Bem-estar que cabe na sua rotina',
      description:
          'Tenha um plano claro para alcançar seus objetivos com suporte '
          'profissional.',
      imagePath: 'assets/pages/onboarding/slide_one.jpg',
      imageDescription:
          'Ilustração: busto clássico lilás com coroa amarela, um jarro '
          'derramando carinhas sorridentes e um vaso com flor',
      buttonLabel: 'Continuar',
      scene: OnboardingScene(
        gradient: [
          AppColor.pair(0xFFDFE5FD, 0xFFF7F1EF),
          AppColor.pair(0xFFD5DFFC, 0xFFF1E7EE),
          AppColor.pair(0xFFCCCBF8, 0xFFE3D8F8),
        ],
        blobs: [
          BackgroundBlob(
            left: -90,
            bottom: -100,
            width: 280,
            height: 240,
            color: OnboardingColors.pink,
            opacity: .85,
          ),
          BackgroundBlob(
            right: -70,
            bottom: -80,
            width: 240,
            height: 200,
            color: OnboardingColors.yellow,
            opacity: .9,
            delay: 5,
            period: 16,
          ),
          BackgroundBlob(
            left: .44,
            top: -60,
            width: 130,
            height: 120,
            color: OnboardingColors.lilac,
            opacity: .8,
            delay: 3,
          ),
          BackgroundBlob(
            left: -36,
            top: .42,
            width: 96,
            height: 92,
            color: OnboardingColors.lime,
            opacity: .75,
            delay: 8,
            period: 12,
          ),
          BackgroundBlob(
            right: .09,
            top: .16,
            width: 54,
            height: 54,
            color: OnboardingColors.sky,
            opacity: .8,
            delay: 2,
            period: 10,
          ),
        ],
        bubbles: [
          BackgroundBubble(.14, 40, 14, OnboardingColors.sky),
          BackgroundBubble(.38, 10, 10, OnboardingColors.lilac, delay: 3),
          BackgroundBubble(
            .63,
            30,
            18,
            OnboardingColors.sky,
            delay: 6,
            period: 11,
          ),
          BackgroundBubble(.86, 60, 12, OnboardingColors.lilac, delay: 1.5),
        ],
        waveTop: .58,
        cloudLeft: .3,
        cloudTop: .09,
        cloudWidth: 150,
      ),
    ),
    OnboardingSlide(
      title: 'Organize tudo em um só lugar',
      description:
          'Nosso app conecta você com especialistas e ajuda a acompanhar suas '
          'metas e seu bem-estar.',
      imagePath: 'assets/pages/onboarding/slide_two.jpg',
      imageDescription:
          'Ilustração: rosto de estátua rosa com fone de ouvido verde, um '
          'vaso com flor e um portal com estrelas',
      buttonLabel: 'Continuar',
      scene: OnboardingScene(
        gradient: [
          AppColor.pair(0xFFDCE4FD, 0xFFF7F1EF),
          AppColor.pair(0xFFD2DDFC, 0xFFF1E7EE),
          AppColor.pair(0xFFC7D0F9, 0xFFE3D8F8),
        ],
        blobs: [
          BackgroundBlob(
            right: -90,
            bottom: -100,
            width: 290,
            height: 240,
            color: OnboardingColors.sky,
            opacity: .85,
          ),
          BackgroundBlob(
            left: -70,
            bottom: -80,
            width: 230,
            height: 190,
            color: OnboardingColors.lime,
            opacity: .8,
            delay: 5,
            period: 16,
          ),
          BackgroundBlob(
            right: .3,
            top: -60,
            width: 130,
            height: 120,
            color: OnboardingColors.pink,
            opacity: .75,
            delay: 3,
          ),
          BackgroundBlob(
            left: .06,
            top: .14,
            width: 60,
            height: 60,
            color: OnboardingColors.lilac,
            opacity: .8,
            delay: 2,
            period: 10,
          ),
        ],
        bubbles: [
          BackgroundBubble(.2, 30, 14, OnboardingColors.lilac),
          BackgroundBubble(.48, 10, 10, OnboardingColors.sky, delay: 4),
          BackgroundBubble(
            .72,
            40,
            16,
            OnboardingColors.lilac,
            delay: 7,
            period: 11,
          ),
        ],
        waveTop: .64,
        cloudLeft: .72,
        cloudTop: .11,
        cloudWidth: 130,
      ),
    ),
    OnboardingSlide(
      title: 'Difícil se organizar no dia a dia?',
      description:
          'Conciliar saúde, metas pessoais e compromissos pode ser desafiador. '
          'A Pablife ajuda você a dar o primeiro passo.',
      imagePath: 'assets/pages/onboarding/slide_three.jpg',
      imageDescription:
          'Ilustração: busto rosa com coroa amarela, um jarro derramando '
          'carinhas e um sol sobre nuvem roxa',
      buttonLabel: 'Começar',
      scene: OnboardingScene(
        gradient: [
          AppColor.pair(0xFFE2E2FD, 0xFFF7F1EF),
          AppColor.pair(0xFFD6DAFB, 0xFFF1E7EE),
          AppColor.pair(0xFFD2C8F6, 0xFFE3D8F8),
        ],
        blobs: [
          BackgroundBlob(
            left: -90,
            bottom: -100,
            width: 280,
            height: 240,
            color: OnboardingColors.lilac,
            opacity: .85,
          ),
          BackgroundBlob(
            right: -70,
            bottom: -80,
            width: 250,
            height: 210,
            color: OnboardingColors.pink,
            opacity: .85,
            delay: 5,
            period: 16,
          ),
          BackgroundBlob(
            right: -40,
            top: .3,
            width: 110,
            height: 100,
            color: OnboardingColors.yellow,
            opacity: .85,
            delay: 3,
            period: 12,
          ),
          BackgroundBlob(
            left: .38,
            top: -50,
            width: 120,
            height: 110,
            color: OnboardingColors.sky,
            opacity: .75,
            delay: 8,
          ),
        ],
        bubbles: [
          BackgroundBubble(.16, 30, 14, OnboardingColors.pink),
          BackgroundBubble(.44, 10, 10, OnboardingColors.lilac, delay: 4),
          BackgroundBubble(
            .78,
            40,
            16,
            OnboardingColors.pink,
            delay: 7,
            period: 11,
          ),
        ],
        waveTop: .6,
        cloudLeft: .12,
        cloudTop: .1,
        cloudWidth: 140,
      ),
    ),
  ];

  /// Carrega as ilustrações antes, para não aparecerem com atraso na troca.
  @override
  void onReady() {
    super.onReady();
    final context = Get.context;
    if (context == null) return;
    for (final path in [
      ...slides.map((slide) => slide.imagePath),
      'assets/pages/auth/login_art.png',
    ]) {
      precacheImage(AssetImage(path), context);
    }
  }

  void nextPage() {
    if (currentPage < slides.length - 1) {
      currentPage++;
      update();
    } else {
      _finishOnboarding();
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      currentPage--;
      update();
    }
  }

  void skipOnboarding() => _finishOnboarding();

  void _finishOnboarding() => Get.offAllNamed(ChooseProfilePage.route);
}
