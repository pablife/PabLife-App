import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/pabi/pabi.dart';
import '../women_health_controller.dart';
import 'diary_entry_page.dart';
import 'women_diary_controller.dart';

/// Card "Meu diário" do Dashboard da Saúde da Mulher (canvas
/// Fem-Diario-Cards, opção A: pergunta do dia).
class WomenDiaryCard extends StatelessWidget {
  final WomenHealthController women;

  const WomenDiaryCard({super.key, required this.women});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WomenDiaryController>(
      init: WomenDiaryController.to,
      builder: (c) {
        final written = c.todayEntry != null;
        void open() => DiaryEntryPage.open(viewOnly: written);
        return Semantics(
          button: true,
          label: written
              ? 'Meu diário: ver anotação de hoje'
              : 'Meu diário: escrever sobre hoje',
          excludeSemantics: true,
          child: Material(
            color: PabColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: PabColors.line),
            ),
            child: InkWell(
              onTap: open,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: PabColors.soft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Pabi(
                            // Sem registro de hoje, a Pabi fica tranquila.
                            mood: PabiMood.fromCheckIn(women.todayCheckIn),
                            women: true,
                            size: 52,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Meu diário',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: PabColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                written
                                    ? 'Hoje · anotado'
                                    : 'Hoje · ainda sem anotação',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: PabColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PabColors.soft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${c.weekCount} na semana',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: PabColors.accentText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: PabColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '“${c.dailyPrompt}”',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PabColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: open,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        backgroundColor: PabColors.ink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        written ? 'Ver anotação de hoje' : 'Escrever no diário',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
