import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../widgets/design_system/text_default.dart';
import '../../../../infra/models/mentorship_model.dart';
import '../../mentorship_routes.dart';

class LessonListItem extends StatelessWidget {
  const LessonListItem({
    super.key,
    required this.lesson,
    required this.moduleId,
  });

  final ModuleLessonModel lesson;
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(0xFF9C27B0).withValues(alpha: 0.1),
        child: Text(
          lesson.lessonNumber.toString(),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.white
                : AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: TextDefault(text: lesson.title, fontSize: 14),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18),
        onPressed: () {
          Get.toNamed(
            MentorshipRoutes.lessonForm,
            arguments: {
              'moduleId': moduleId,
              'lessonId': lesson.id,
              'lessonNumber': lesson.lessonNumber,
              'title': lesson.title,
              'videoUrl': lesson.videoUrl,
            },
          );
        },
      ),
    );
  }
}
