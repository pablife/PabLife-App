import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../widgets/design_system/text_default.dart';
import '../../../../infra/models/mentorship_model.dart';
import '../../mentorship_routes.dart';
import 'lessons_section.dart';

class ModuleTile extends StatelessWidget {
  const ModuleTile({
    super.key,
    required this.module,
    required this.mentorshipId,
  });

  final MentorshipModuleModel module;
  final String mentorshipId;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: TextDefault(
            text: module.name,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder_outlined, color: AppColors.warning),
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'edit') {
                Get.toNamed(
                  MentorshipRoutes.moduleForm,
                  arguments: {
                    'mentorshipId': mentorshipId,
                    'moduleId': module.id,
                    'moduleName': module.name,
                  },
                );
              } else if (value == 'delete') {
                //TODO: Implementar exclusão
              }
            },
          ),
          children: [LessonsSection(moduleId: module.id)],
        ),
      ),
    );
  }
}
