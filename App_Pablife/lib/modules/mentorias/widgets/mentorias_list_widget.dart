import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import '../../../infra/models/mentoria_model.dart';
import '../../../widgets/design_system/empty_state_widget.dart';
import 'mentoria_tile.dart';

class MentoriasListWidget extends StatelessWidget {
  final bool isLoading;
  final List<MentoriaModel> mentorias;
  final bool showOnlySaved;
  final void Function(MentoriaModel) onMentoriaTap;
  final void Function(MentoriaModel) onBookmarkTap;

  const MentoriasListWidget({
    super.key,
    required this.isLoading,
    required this.mentorias,
    required this.showOnlySaved,
    required this.onMentoriaTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor(0xFF00343C)),
      );
    }

    if (mentorias.isEmpty) {
      return EmptyStateWidget(
        icon: showOnlySaved ? Icons.bookmark_border : Icons.search_off,
        title: showOnlySaved
            ? 'Nenhuma mentoria salva'
            : 'Nenhuma mentoria encontrada',
        description: showOnlySaved
            ? 'Salve mentorias para acessá-las facilmente depois'
            : 'Tente buscar por outro termo ou categoria',
        iconSize: 64,
        titleFontSize: 18,
        titleFontWeight: FontWeight.w600,
        descriptionFontSize: 14,
        descriptionFontWeight: FontWeight.w400,
      );
    }

    Widget tile(MentoriaModel mentoria) => MentoriaTile(
      mentoria: mentoria,
      onTap: () => onMentoriaTap(mentoria),
      onBookmarkTap: () => onBookmarkTap(mentoria),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Computador: cartões lado a lado.
        if (constraints.maxWidth >= 720) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 410,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: mentorias.length,
            itemBuilder: (_, index) => tile(mentorias[index]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: mentorias.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, index) => tile(mentorias[index]),
        );
      },
    );
  }
}
