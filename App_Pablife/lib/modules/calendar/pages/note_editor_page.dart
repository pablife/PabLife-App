import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/app_text_vector.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/design_system/app_select_field.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/note_editor_controller.dart';

class NoteEditorPage extends StatelessWidget {
  const NoteEditorPage({super.key});

  static const route = '/calendar/note-editor';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NoteEditorController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF00343C),
          body: Column(
            children: [
              const SizedBox(height: 32),
              _buildHeader(controller),
              const SizedBox(height: 20),
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

  Widget _buildHeader(NoteEditorController controller) {
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
                Icons.note_add_outlined,
                color: Color(0xFF00343C),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            TextDefault(
              controller.isEditMode ? 'Editar Anotação' : 'Nova Anotação',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(NoteEditorController controller) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFC1CDFF)),
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
              onTap: controller.selectDate,
              child: AbsorbPointer(
                child: AppTextFormField(
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
              items: NoteEditorController.priorityOptions
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(NoteEditorController controller) {
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
              onTap: controller.saveNote,
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
