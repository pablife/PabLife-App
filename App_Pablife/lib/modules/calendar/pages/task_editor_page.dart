import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/app_text_vector.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/design_system/app_select_field.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/task_editor_controller.dart';

class TaskEditorPage extends StatelessWidget {
  const TaskEditorPage({super.key});

  static const route = '/calendar/task-editor';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaskEditorController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          body: Column(
            children: [
              const SizedBox(height: 32),
              _buildHeader(controller),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(39),
                    topRight: Radius.circular(39),
                  ),
                  child: _buildContent(controller),
                ),
              ),
              _buildBottomButtons(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(TaskEditorController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: controller.goBack,
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
              const SizedBox(),
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
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF00343C),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            TextDefault(
              controller.isEditMode ? 'Editar Tarefa' : 'Nova Tarefa',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(TaskEditorController controller) {
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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
        child: Column(
          children: [
            AppTextFormField(
              labelText: 'Nome da Tarefa',
              hintText: 'Nome',
              controller: controller.nameController,
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: controller.isDateLocked ? null : controller.selectDate,
              child: AbsorbPointer(
                absorbing: controller.isDateLocked,
                child: AppTextFormField(
                  labelText: 'Data de Início',
                  hintText: 'Data',
                  controller: controller.dateController,
                ),
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: controller.selectTime,
              child: AbsorbPointer(
                child: AppTextFormField(
                  labelText: 'Horário',
                  hintText: 'Horário',
                  controller: controller.timeController,
                ),
              ),
            ),
            const SizedBox(height: 15),
            AppSelectField<String>(
              labelText: 'Prioridade',
              hintText: 'Selecione a prioridade',
              value: controller.selectedPriority,
              items: TaskEditorController.priorityOptions
                  .map(
                    (option) => SelectOption(
                      value: option['value']!,
                      label: option['label']!,
                    ),
                  )
                  .toList(),
              valueFromString: (value) => value,
              onChanged: controller.onPriorityChanged,
            ),
            const SizedBox(height: 20),
            if (controller.showRecurrenceToggle) _buildRecurrenceToggle(controller),
            if (controller.isRecurrenceEnabled) ...[
              const SizedBox(height: 20),
              _buildWeekdaySelector(controller),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceToggle(TaskEditorController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const TextDefault(
            'Habilitar Recorrência',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFF00343C),
          ),
          GestureDetector(
            onTap: controller.canToggleRecurrence ? controller.toggleRecurrence : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 60,
              height: 34,
              decoration: BoxDecoration(
                color: controller.isRecurrenceEnabled
                    ? const Color(0xFF0C8DA1)
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: controller.isRecurrenceEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00343C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdaySelector(TaskEditorController controller) {
    final weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: weekdays.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        final isSelected = controller.selectedWeekdays.contains(index);

        return GestureDetector(
          onTap: () => controller.toggleWeekday(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00343C)
                  : const Color(0xFFC1CDFF),
              border: Border.all(color: const Color(0xFF00343C), width: 1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextDefault(
              day,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isSelected ? Colors.white : const Color(0xFF00343C),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButtons(TaskEditorController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: AppColors.second,
      child: Row(
        children: [
          Expanded(
            child: EdgeButtonRounded(
              text: 'Cancelar',
              onTap: controller.goBack,
              backgroundColor: const Color(0xFF0C8DA1),
              side: EdgeSide.right,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: EdgeButtonRounded(
              text: 'Salvar',
              onTap: controller.saveTask,
              isLoading: controller.isLoading,
              backgroundColor: const Color(0xFF00343C),
              side: EdgeSide.left,
            ),
          ),
        ],
      ),
    );
  }
}
