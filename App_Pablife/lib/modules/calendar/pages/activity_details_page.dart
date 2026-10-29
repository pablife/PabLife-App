import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../widgets/app_text_vector.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/activity_details_controller.dart';

class ActivityDetailsPage extends StatelessWidget {
  const ActivityDetailsPage({super.key});

  static const route = '/calendar/activity-details';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ActivityDetailsController>(
      init: ActivityDetailsController(),
      builder: (controller) {
        if (controller.isLoading || controller.activity == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF00343C),
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final activity = controller.activity!;
        final dueAtLocal = activity.dueAt?.toLocal();
        final eventDate = activity.activityDate;
        final dateBase = eventDate ?? dueAtLocal ?? DateTime.now();
        final timeBase = dueAtLocal ?? DateTime(dateBase.year, dateBase.month, dateBase.day);
        final dateStr = DateFormat('dd/MM/yyyy').format(dateBase);
        final timeStr = DateFormat('HH:mm').format(timeBase);

        Color typeColor;
        String typeLabel;
        IconData typeIcon;

        switch (activity.type) {
          case 'task':
            typeColor = const Color(0xFF00C2A8);
            typeLabel = 'Tarefa';
            typeIcon = Icons.check_circle_outline;
            break;
          case 'goal':
            typeColor = const Color(0xFF92CA4F);
            typeLabel = 'Meta';
            typeIcon = Icons.flag_outlined;
            break;
          case 'note':
            typeColor = const Color(0xFFD2CC61);
            typeLabel = 'Anotação';
            typeIcon = Icons.note_outlined;
            break;
          default:
            typeColor = const Color(0xFF3065FF);
            typeLabel = 'Atividade';
            typeIcon = Icons.event;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(controller, typeIcon, typeLabel),
                Expanded(
                  child: _buildContent(
                    activity,
                    dateStr,
                    timeStr,
                    typeColor,
                    typeLabel,
                    typeIcon,
                  ),
                ),
                _buildBottomButtons(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    ActivityDetailsController controller,
    IconData typeIcon,
    String typeLabel,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 66,
                  height: 65,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const AppTextVector(width: 148, height: 45),
              const SizedBox(width: 66),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 29,
              height: 29,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: const Color(0xFF00343C), size: 20),
            ),
            const SizedBox(width: 10),
            TextDefault(
              typeLabel,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(
    dynamic activity,
    String dateStr,
    String timeStr,
    Color typeColor,
    String typeLabel,
    IconData typeIcon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFC1CDFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(39),
          topRight: Radius.circular(39),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextDefault(
              activity.name,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00343C),
            ),
            const SizedBox(height: 20),
            if (activity.description != null &&
                activity.description!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextDefault(
                  activity.description!,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF00343C),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (activity.steps != null && activity.steps!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextDefault(
                      'Etapas',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00343C),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(activity.steps!.length, (index) {
                      final step = activity.steps![index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextDefault(
                              '${index + 1}. ',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00343C),
                            ),
                            Expanded(
                              child: TextDefault(
                                step,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF00343C),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF00343C),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      TextDefault(
                        dateStr,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF00343C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF00343C),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      TextDefault(
                        timeStr,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF00343C),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(ActivityDetailsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: AppColors.second,
      child: Row(
        children: [
          Expanded(
            child: EdgeButtonRounded(
              text: 'Editar',
              onTap: controller.editActivity,
              backgroundColor: const Color(0xFF0C8DA1),
              side: EdgeSide.right,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: EdgeButtonRounded(
              text: 'Excluir',
              onTap: controller.promptDeleteActivity,
              isLoading: controller.isLoading,
              backgroundColor: const Color(0xFFFF5252),
              side: EdgeSide.left,
            ),
          ),
        ],
      ),
    );
  }
}
