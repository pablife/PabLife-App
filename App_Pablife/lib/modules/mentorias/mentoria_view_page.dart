import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pablife/widgets/design_system/app_image.dart';
import '../../widgets/design_system/app_bar_default.dart';
import '../../widgets/design_system/edge_button_rounded.dart';
import '../../widgets/design_system/text_default.dart';
import 'mentoria_view_controller.dart';
import 'widgets/mentoria_module_card.dart';
import 'widgets/mentoria_video_tile.dart';

class MentoriaViewPage extends StatelessWidget {
  const MentoriaViewPage({super.key});

  static const route = '/mentoria/view';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MentoriaViewController>(
      builder: (controller) {
        if (controller.mentoria == null) {
          return const Scaffold(
            body: Center(child: Text('Mentoria não encontrada')),
          );
        }

        final mentoria = controller.mentoria!;
        final author = mentoria.author.isNotEmpty
            ? mentoria.author
            : 'Autor não informado';

        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          extendBodyBehindAppBar: true,
          appBar: const AppBarDefault(title: ''),
          body: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              _MentoriaBanner(imageUrl: mentoria.bannerUrl),
              Positioned.fill(
                top: 326,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFC1CDFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(38),
                        offset: const Offset(0, -20),
                        blurRadius: 60,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 30, left: 30),
                          child: TextDefault(
                            mentoria.title,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00343C),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: TextDefault(
                            author,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF22717D),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: EdgeButtonRounded(
                            text: controller.isSaved
                                ? 'Inscrito'
                                : 'Se Inscrever',
                            onTap: controller.toggleSave,
                            backgroundColor: controller.isSaved
                                ? const Color(0xFF0C8DA1)
                                : const Color(0xFFAEBEEC),
                            textColor: controller.isSaved
                                ? Colors.white
                                : const Color(0xFF00343C),
                            width: 190,
                            side: EdgeSide.left,
                            icon: Icon(
                              controller.isSaved
                                  ? Icons.check
                                  : Icons.bookmark_border,
                              color: controller.isSaved
                                  ? Colors.white
                                  : const Color(0xFF00343C),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const MentoriaViewDivider(),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: const TextDefault(
                            'Descrição',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: TextDefault(
                            mentoria.description,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withAlpha(143),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const MentoriaViewDivider(),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: const TextDefault(
                            'Módulos',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (controller.isLoading && controller.modules.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                color: Color(0xFF00343C),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 183,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              itemCount: controller.modules.length,
                              itemBuilder: (context, index) {
                                final module = controller.modules[index];
                                final isSelected =
                                    controller.selectedModuleId == module.id;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index < controller.modules.length - 1
                                        ? 12
                                        : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () =>
                                        controller.selectModule(module.id),
                                    child: MentoriaModuleCard(
                                      module: module,
                                      isSelected: isSelected,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        const MentoriaViewDivider(),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: const TextDefault(
                            'Aulas',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (controller.isLoading && controller.videos.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                color: Color(0xFF00343C),
                              ),
                            ),
                          )
                        else
                          ...controller.videos.map((video) {
                            final isExpanded =
                                controller.expandedVideoId == video.id;
                            final isLoading = controller.isVideoLoading(
                              video.id,
                            );
                            return MentoriaVideoTile(
                              video: video,
                              isExpanded: isExpanded,
                              isLoading: isLoading,
                              onTap: () =>
                                  controller.toggleVideoExpansion(video.id),
                              onPlayTap: () => controller.playVideo(video),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MentoriaViewDivider extends StatelessWidget {
  const MentoriaViewDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFF00343C).withAlpha(38));
  }
}

class _MentoriaBanner extends StatelessWidget {
  const _MentoriaBanner({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    const bannerHeight = 374.0;
    const widthFactor = 1.7;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: bannerHeight,
        child: Align(
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.fitWidth,
                    placeholder: Container(
                      color: const Color(0xFF00343C).withAlpha(153),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFC1CDFF),
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      color: const Color(0xFF00343C).withAlpha(153),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white.withAlpha(179),
                        size: 48,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(89),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
