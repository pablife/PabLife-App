import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/app_text_vector.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/design_system/app_select_field.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/goal_editor_controller.dart';

class GoalEditorPage extends StatelessWidget {
  const GoalEditorPage({super.key});

  static const route = '/calendar/goal-editor';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GoalEditorController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(controller),
                Expanded(child: _buildContent(controller)),
                _buildBottomButtons(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(GoalEditorController controller) {
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
              GestureDetector(
                onTap: controller.showGoalSuggestions,
                child: Container(
                  width: 66,
                  height: 65,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
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
                Icons.flag_outlined,
                color: Color(0xFF00343C),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            TextDefault(
              controller.isEditMode ? 'Editar Meta' : 'Nova Meta',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(GoalEditorController controller) {
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
              hintText: 'Nome',
              controller: controller.nameController,
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: controller.selectDeadline,
              child: AbsorbPointer(
                child: AppTextFormField(
                  hintText: 'Prazo Final',
                  labelText: 'Prazo Final',
                  controller: controller.deadlineController,
                ),
              ),
            ),
            const SizedBox(height: 15),
            AppSelectField<String>(
              labelText: 'Prioridade',
              hintText: 'Selecione a prioridade',
              value: controller.selectedPriority,
              items: GoalEditorController.priorityOptions
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
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextFormField(
                controller: controller.strategyController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Estratégia para fazer',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withAlpha(143),
                    fontFamily: 'Instrument Sans',
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Instrument Sans',
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildStepsSection(controller),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection(GoalEditorController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: TextDefault(
            'Etapas',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF00343C),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(controller.stepControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppTextFormField(
              labelText: 'Etapa ${index + 1}',
              hintText: 'Etapa ${index + 1}',
              controller: controller.stepControllers[index],
              onChanged: (_) => controller.onStepsChanged(),
            ),
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: controller.canAddAnotherStep
                ? controller.addStepField
                : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00343C),
            ),
            icon: const Icon(Icons.add),
            label: const TextDefault(
              'Adicionar etapa',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00343C),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(GoalEditorController controller) {
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
              onTap: controller.saveGoal,
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
