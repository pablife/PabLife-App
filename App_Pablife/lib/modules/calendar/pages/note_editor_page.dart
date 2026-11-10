import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/pages/widgets/registration_layout.dart';
import '../controllers/note_editor_controller.dart';
import '../widgets/editor_form_widgets.dart';

/// "Nova anotação" / "Editar anotação" no visual da repaginação.
class NoteEditorPage extends StatelessWidget {
  const NoteEditorPage({super.key});

  static const route = '/calendar/note-editor';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NoteEditorController>(
      builder: (c) {
        return RegistrationLayout(
          title: c.isEditMode ? 'Editar anotação' : 'Nova anotação',
          onBack: c.goBack,
          fields: [
            RegField(
              label: 'Anotação',
              hint: 'O que você quer lembrar?',
              controller: c.nameController,
              onChanged: (_) {},
              capitalization: TextCapitalization.sentences,
            ),
            Row(
              children: [
                Expanded(
                  child: EditorPickerField(
                    label: 'Data',
                    hint: 'Escolher',
                    controller: c.dateController,
                    onTap: c.selectDate,
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: EditorPickerField(
                    label: 'Horário',
                    hint: 'Escolher',
                    controller: c.timeController,
                    onTap: c.selectTime,
                    icon: Icons.schedule,
                  ),
                ),
              ],
            ),
            EditorPriorityPicker(
              options: NoteEditorController.priorityOptions,
              value: c.selectedPriority,
              onChanged: c.onPriorityChanged,
            ),
          ],
          footer: [
            EditorFooter(
              onCancel: c.goBack,
              onSave: c.saveNote,
              loading: c.isLoading,
            ),
          ],
        );
      },
    );
  }
}
