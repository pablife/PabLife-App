import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infra/models/banner_model.dart';
import '../design_system/app_image.dart';

class BannerCarouselWidget extends StatelessWidget {
  final List<BannerModel> banners;
  final double? height;
  final EdgeInsets padding;
  final double aspectRatio;

  const BannerCarouselWidget({
    super.key,
    required this.banners,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.aspectRatio = 16 / 9,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(builder: _buildCarousel);
  }

  Widget _buildCarousel(BuildContext context, BoxConstraints constraints) {
    // Calcula a largura do banner (85% do espaço disponível; na web em
    // colunas, isso é a coluna e não a tela inteira)
    final bannerWidth = constraints.maxWidth * 0.85;
    // Calcula a altura baseada na proporção ou usa a altura fixa se fornecida
    final bannerHeight = height ?? (bannerWidth / aspectRatio);

    return SizedBox(
      height: bannerHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < banners.length - 1 ? 12 : 0,
            ),
            child: _BannerItem(
              banner: banner,
              height: bannerHeight,
              width: bannerWidth,
            ),
          );
        },
      ),
    );
  }
}

class _BannerItem extends StatelessWidget {
  final BannerModel banner;
  final double height;
  final double width;

  const _BannerItem({
    required this.banner,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final hasLink = banner.redirectUrl.isNotEmpty;

    Widget bannerWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
      child: AppImage(
        imageUrl: banner.imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(25),
      ),
    );

    if (hasLink) {
      return GestureDetector(
        onTap: () => _openLink(banner.redirectUrl),
        child: bannerWidget,
      );
    }

    return bannerWidget;
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
