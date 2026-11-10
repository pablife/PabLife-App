import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../controllers/goal_editor_controller.dart';
import '../widgets/editor_form_widgets.dart';

/// "Nova meta" / "Editar meta" no visual da repaginação.
class GoalEditorPage extends StatelessWidget {
  const GoalEditorPage({super.key});

  static const route = '/calendar/goal-editor';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GoalEditorController>(
      builder: (c) {
        return RegistrationLayout(
          title: c.isEditMode ? 'Editar meta' : 'Nova meta',
          onBack: c.goBack,
          fields: [
            if (!c.isEditMode) _SuggestionsCard(onTap: c.showGoalSuggestions),
            RegField(
              label: 'Nome da meta',
              hint: 'Ex.: Ler 12 livros no ano',
              controller: c.nameController,
              onChanged: (_) {},
              capitalization: TextCapitalization.sentences,
            ),
            EditorPickerField(
              label: 'Prazo final',
              hint: 'Escolher data',
              controller: c.deadlineController,
              onTap: c.selectDeadline,
              icon: Icons.calendar_today_outlined,
            ),
            EditorPriorityPicker(
              options: GoalEditorController.priorityOptions,
              value: c.selectedPriority,
              onChanged: c.onPriorityChanged,
            ),
            EditorTextArea(
              label: 'Estratégia',
              hint: 'Como você vai chegar lá?',
              controller: c.strategyController,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < c.stepControllers.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  RegField(
                    label: 'Etapa ${i + 1}',
                    hint: 'Um passo da meta',
                    controller: c.stepControllers[i],
                    onChanged: (_) => c.onStepsChanged(),
                    capitalization: TextCapitalization.sentences,
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: c.canAddAnotherStep ? c.addStepField : null,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: PabColors.accentText,
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'Adicionar etapa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          footer: [
            EditorFooter(
              onCancel: c.goBack,
              onSave: c.saveGoal,
              loading: c.isLoading,
            ),
          ],
        );
      },
    );
  }
}

class _SuggestionsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SuggestionsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PabColors.soft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: PabColors.softText),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sem ideia? Veja sugestões de metas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PabColors.softText,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: PabColors.softText),
            ],
          ),
        ),
      ),
    );
  }
}
