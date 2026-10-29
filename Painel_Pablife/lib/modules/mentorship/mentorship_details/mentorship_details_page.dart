import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/modules/mentorship/mentorship_details/widgets/mentorship_info_card.dart';
import 'package:painel_pablife/modules/mentorship/mentorship_details/widgets/modules_list.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../widgets/states/app_widget_loading.dart';
import '../mentorship_controller.dart';
import '../mentorship_routes.dart';

class MentorshipDetailsPage extends StatelessWidget {
  const MentorshipDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MentorshipController>();
    final mentorshipId = Get.arguments as String?;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mentorshipId != null) {
        controller.loadMentorshipDetails(mentorshipId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Mentoria'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final mentorship = controller.selectedMentorship;
              if (mentorship != null) {
                Get.toNamed(
                  MentorshipRoutes.mentorshipEdit,
                  arguments: {
                    'id': mentorship.id,
                    'title': mentorship.title,
                    'author': mentorship.author,
                    'duration': mentorship.duration,
                    'description': mentorship.description,
                    'categoryId': mentorship.categoryId,
                    'imageUrl': mentorship.imageUrl,
                  },
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGreen,
        onPressed: () {
          Get.toNamed(
            MentorshipRoutes.moduleForm,
            arguments: {'mentorshipId': mentorshipId},
          );
        },
        child: const Icon(Icons.add),
      ),
      body: GetBuilder<MentorshipController>(
        builder: (_) {
          if (controller.isLoading) {
            return const AppWidgetLoading();
          }

          final mentorship = controller.selectedMentorship;
          if (mentorship == null) {
            return const Center(
              child: TextDefault(text: 'Mentoria não encontrada'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MentorshipInfoCard(mentorship: mentorship),
                const SizedBox(height: 24),
                ModulesList(mentorshipId: mentorshipId ?? ''),
              ],
            ),
          );
        },
      ),
    );
  }
}
