import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../widgets/design_system/text_default.dart';
import '../../mentorship_routes.dart';
import '../../mentorship_controller.dart';
import 'module_tile.dart';

class ModulesList extends StatelessWidget {
  const ModulesList({super.key, required this.mentorshipId});

  final String mentorshipId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MentorshipController>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextDefault(
              text: 'Módulos',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            TextButton.icon(
              onPressed: () {
                Get.toNamed(
                  MentorshipRoutes.moduleForm,
                  arguments: {'mentorshipId': mentorshipId},
                );
              },
              icon: Icon(
                Icons.add,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.white
                    : AppColors.primaryGreen,
              ),
              label: const TextDefault(text: 'Adicionar Módulo', fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GetBuilder<MentorshipController>(
          builder: (_) {
            final modules = controller.modules;
            if (modules.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: TextDefault(
                    text: 'Nenhum módulo adicionado',
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                return ModuleTile(
                  module: modules[index],
                  mentorshipId: mentorshipId,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
