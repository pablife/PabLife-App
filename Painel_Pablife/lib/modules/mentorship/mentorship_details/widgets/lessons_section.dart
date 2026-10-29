import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../widgets/design_system/text_default.dart';
import '../../mentorship_routes.dart';
import '../../mentorship_controller.dart';
import 'lesson_list_item.dart';

class LessonsSection extends StatelessWidget {
  const LessonsSection({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MentorshipController>();

    return FutureBuilder(
      future: controller.getLessonsByModule(moduleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final lessons = snapshot.data ?? [];
        if (lessons.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const TextDefault(
                  text: 'Nenhuma aula',
                  color: AppColors.textSecondary,
                ),
                TextButton.icon(
                  onPressed: () {
                    Get.toNamed(
                      MentorshipRoutes.lessonForm,
                      arguments: {'moduleId': moduleId},
                    );
                  },
                  icon: Icon(
                    Icons.add,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.white
                        : AppColors.primaryGreen,
                  ),
                  label: const TextDefault(
                    text: 'Adicionar Aula',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ...lessons.map(
              (lesson) => LessonListItem(lesson: lesson, moduleId: moduleId),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: () {
                  Get.toNamed(
                    MentorshipRoutes.lessonForm,
                    arguments: {'moduleId': moduleId},
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar Aula'),
              ),
            ),
          ],
        );
      },
    );
  }
}
