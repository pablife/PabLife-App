import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/themes/pab_colors.dart';
import 'mentorias_controller.dart';
import 'widgets/mentorias_list_widget.dart';

/// Mentorias (canvas "Mentorias — mobile"): topo escuro com busca e o filtro
/// "Salvas", categorias em pílulas e os cartões.
class MentoriasPage extends StatelessWidget {
  const MentoriasPage({super.key});

  static const route = '/mentorias';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MentoriasController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: PabColors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(controller: controller),
              if (controller.categories.length > 1)
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final category = controller.categories[index];
                      final selected = category == controller.selectedCategory;
                      return _CategoryChip(
                        label: category,
                        selected: selected,
                        onTap: () => controller.changeCategory(category),
                      );
                    },
                  ),
                ),
              Expanded(
                child: MentoriasListWidget(
                  isLoading: controller.isLoading,
                  mentorias: controller.filteredMentorias,
                  showOnlySaved: controller.showOnlySaved,
                  onMentoriaTap: controller.openMentoria,
                  onBookmarkTap: controller.toggleSaveMentoria,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final MentoriasController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final saved = controller.showOnlySaved;
    return Container(
      decoration: const BoxDecoration(
        color: PabColors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mentorias',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PabColors.onInk,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    toggled: saved,
                    child: Material(
                      color: saved
                          ? PabColors.accent
                          : PabColors.onInk.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: controller.toggleSavedFilter,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: SizedBox(
                            height: 44,
                            child: Row(
                              children: [
                                Icon(
                                  saved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 16,
                                  color: saved
                                      ? PabColors.ink
                                      : PabColors.onInk,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Salvas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: saved
                                        ? PabColors.ink
                                        : PabColors.onInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: PabColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: PabColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          fontSize: 15,
                          color: PabColors.ink,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar mentoria',
                          hintStyle: TextStyle(color: PabColors.muted),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? PabColors.ink : PabColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? PabColors.ink : PabColors.lineStrong,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : PabColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
