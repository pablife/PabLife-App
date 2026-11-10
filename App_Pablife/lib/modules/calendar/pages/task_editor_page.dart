import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/pages/widgets/registration_layout.dart';
import '../controllers/task_editor_controller.dart';
import '../widgets/editor_form_widgets.dart';

/// "Nova tarefa" / "Editar tarefa" no visual da repaginação.
class TaskEditorPage extends StatelessWidget {
  const TaskEditorPage({super.key});

  static const route = '/calendar/task-editor';

  static const _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaskEditorController>(
      builder: (c) {
        return RegistrationLayout(
          title: c.isEditMode ? 'Editar tarefa' : 'Nova tarefa',
          onBack: c.goBack,
          fields: [
            RegField(
              label: 'Nome da tarefa',
              hint: 'Ex.: Caminhar 30 minutos',
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
                    onTap: c.isDateLocked ? null : c.selectDate,
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
              options: TaskEditorController.priorityOptions,
              value: c.selectedPriority,
              onChanged: c.onPriorityChanged,
            ),
            if (c.showRecurrenceToggle)
              EditorSwitchCard(
                label: 'Repetir toda semana',
                description: 'Escolha os dias em que a tarefa se repete.',
                value: c.isRecurrenceEnabled,
                onChanged: c.canToggleRecurrence
                    ? (_) => c.toggleRecurrence()
                    : null,
                child: c.isRecurrenceEnabled
                    ? Row(
                        children: [
                          for (var i = 0; i < _weekdays.length; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Expanded(
                              child: EditorChip(
                                label: _weekdays[i],
                                compact: true,
                                selected: c.selectedWeekdays.contains(i),
                                onTap: () => c.toggleWeekday(i),
                              ),
                            ),
                          ],
                        ],
                      )
                    : null,
              ),
          ],
          footer: [
            EditorFooter(
              onCancel: c.goBack,
              onSave: c.saveTask,
              loading: c.isLoading,
            ),
          ],
        );
      },
    );
  }
}
