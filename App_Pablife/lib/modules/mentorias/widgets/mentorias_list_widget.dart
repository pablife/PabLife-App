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
        child: CircularProgressIndicator(color: Color(0xFF00343C)),
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 100),
      itemCount: mentorias.length,
      itemBuilder: (context, index) {
        final mentoria = mentorias[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MentoriaTile(
            mentoria: mentoria,
            onTap: () => onMentoriaTap(mentoria),
            onBookmarkTap: () => onBookmarkTap(mentoria),
          ),
        );
      },
    );
  }
}
