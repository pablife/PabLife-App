import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../infra/models/women_diary_entry.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/design_system/app_dialog.dart';
import '../women_health_controller.dart';
import 'women_diary_controller.dart';

/// Texto corrido das anotações (canvas: #4E3A58).
const diaryBodyColor = Color(0xFF4E3A58);

/// "Sexta, 6 nov".
String diaryDateLabel(DateTime day) {
  final text = DateFormat("EEEE, d MMM", 'pt_BR').format(day);
  final clean = text.replaceAll('-feira', '').replaceAll('.', '');
  return '${clean[0].toUpperCase()}${clean.substring(1)}';
}

/// Humor registrado no dia ("Tranquila"), ou null.
String? diaryMoodOn(DateTime day) {
  if (!Get.isRegistered<WomenHealthController>()) return null;
  return WomenHealthController.to.checkInOn(day);
}

/// "Dia 5 do ciclo · Tranquila" (só o que existir).
String diaryMeta(WomenDiaryEntry entry, {bool withMood = true}) {
  final parts = <String>[
    if (entry.cycleDay != null) 'Dia ${entry.cycleDay} do ciclo',
    if (withMood && diaryMoodOn(entry.day) != null) diaryMoodOn(entry.day)!,
  ];
  return parts.join(' · ');
}

/// Mostra uma vez o aviso de privacidade do diário.
Future<void> showDiaryPrivacyOnce(BuildContext context) async {
  final diary = WomenDiaryController.to;
  if (await diary.privacySeen()) return;
  if (!context.mounted) return;
  await AppDialog.show<void>(
    context: context,
    title: 'Meu diário',
    icon: Icons.lock_outline_rounded,
    content: const Text(
      'Seu diário é privado. Só você vê, a não ser que escolha compartilhar '
      'uma anotação com sua psicóloga.',
    ),
    confirmText: 'Entendi',
    onConfirm: () => Navigator.of(context).pop(),
  );
  await diary.markPrivacySeen();
}

/// Botão redondo de escolha (rotina e filtros), com 44px de toque.
class DiaryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool check;

  const DiaryPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.check = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? PabColors.ink : PabColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? PabColors.ink : PabColors.lineStrong,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (check && selected) ...[
                    const Icon(Icons.check, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : PabColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta pequena (hábitos marcados).
class DiaryTag extends StatelessWidget {
  final String label;

  const DiaryTag(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: PabColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PabColors.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: diaryBodyColor,
        ),
      ),
    );
  }
}

/// Selo "Privada" / "Compartilhada".
class DiaryShareBadge extends StatelessWidget {
  final bool shared;

  const DiaryShareBadge({super.key, required this.shared});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: shared ? PabColors.lilac : PabColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        shared ? 'Compartilhada' : 'Privada',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: shared ? PabColors.lilacText : PabColors.muted,
        ),
      ),
    );
  }
}

/// Botão de voltar (44px).
class DiaryBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool onDark;

  const DiaryBackButton({super.key, required this.onTap, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Voltar',
      child: Material(
        color: onDark
            ? PabColors.onInk.withValues(alpha: 0.12)
            : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: onDark
              ? BorderSide.none
              : const BorderSide(color: PabColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.chevron_left,
              size: 24,
              color: onDark ? PabColors.onInk : PabColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
