import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../women_health_controller.dart';
import '../women_health_data.dart';

enum _Stage { pick, quiz, consent }

/// Entrada do modo: escolha da trilha, questionário e avisos. Segue a
/// moldura das telas repaginadas (RegistrationLayout): voltar, título,
/// passo, barra de progresso e botão embaixo.
class WomenHealthFlowPage extends StatefulWidget {
  const WomenHealthFlowPage({super.key});

  static Future<void> open() async {
    await Get.to<void>(() => const WomenHealthFlowPage());
  }

  @override
  State<WomenHealthFlowPage> createState() => _WomenHealthFlowPageState();
}

/// Ícone de cada trilha.
IconData _trailIcon(WomenTrail trail) => switch (trail) {
  WomenTrail.cycle => Icons.water_drop_outlined,
  WomenTrail.conceive => Icons.favorite_border_rounded,
  WomenTrail.pregnancy => Icons.child_care_rounded,
  WomenTrail.menopause => Icons.spa_outlined,
};

class _WomenHealthFlowPageState extends State<WomenHealthFlowPage> {
  _Stage _stage = _Stage.pick;
  WomenTrail? _trail;
  int _step = 0;
  final Map<String, String> _answers = {};
  DateTime? _lastPeriod;
  bool _saving = false;

  List<WomenQuestion> get _questions => womenQuiz[_trail]!;

  void _next() {
    setState(() {
      if (_step + 1 < _questions.length) {
        _step++;
      } else {
        _stage = _Stage.consent;
      }
    });
  }

  void _back() {
    setState(() {
      switch (_stage) {
        case _Stage.pick:
          Get.back<void>();
        case _Stage.quiz:
          if (_step > 0) {
            _step--;
          } else {
            _stage = _Stage.pick;
          }
        case _Stage.consent:
          _stage = _Stage.quiz;
          _step = _questions.length - 1;
      }
    });
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final days = switch (_trail!) {
      WomenTrail.pregnancy => 294,
      WomenTrail.menopause => 3650,
      _ => 365,
    };
    final date = await showDatePicker(
      context: context,
      initialDate: _lastPeriod ?? today,
      firstDate: today.subtract(Duration(days: days)),
      lastDate: today,
      helpText: 'Escolha a data',
    );
    if (date == null) return;
    _lastPeriod = date;
    _next();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final started = await WomenHealthController.to.start(
      newTrail: _trail!,
      newAnswers: Map.of(_answers),
      newLastPeriod: _lastPeriod,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    // Se não salvou, fica aqui com o aviso na tela para tentar de novo.
    if (started) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _Stage.pick => RegistrationLayout(
        title: 'Saúde da Mulher',
        step: 'Escolha uma trilha',
        onBack: _back,
        fields: [
          const _Heading(
            'O que você quer acompanhar?',
            'Escolha uma trilha. Você pode trocar depois.',
          ),
          for (final trail in WomenTrail.values)
            _OptionTile(
              icon: _trailIcon(trail),
              title: trail.title,
              subtitle: trail.description,
              selected: trail == _trail,
              onTap: () => setState(() {
                if (trail != _trail) {
                  _answers.clear();
                  _lastPeriod = null;
                }
                _trail = trail;
                _step = 0;
                _stage = _Stage.quiz;
              }),
            ),
        ],
        footer: const [],
      ),
      _Stage.quiz => _quiz(),
      _Stage.consent => _consent(),
    };
  }

  Widget _quiz() {
    final question = _questions[_step];
    final answer = _answers[question.id];
    return RegistrationLayout(
      title: _trail!.title,
      step: 'Pergunta ${_step + 1} de ${_questions.length}',
      onBack: _back,
      progress: _step + 1,
      totalSteps: _questions.length,
      fields: [
        _Heading(question.text, question.help),
        if (question.isDate) ...[
          _OptionTile(
            icon: Icons.calendar_today_outlined,
            title: _lastPeriod == null
                ? 'Escolher a data'
                : DateFormat(
                    "d 'de' MMMM 'de' y",
                    'pt_BR',
                  ).format(_lastPeriod!),
            subtitle: _lastPeriod == null ? null : 'Toque para trocar',
            selected: _lastPeriod != null,
            onTap: _pickDate,
          ),
          if (question.unknownLabel != null)
            _OptionTile(
              icon: Icons.help_outline_rounded,
              title: question.unknownLabel!,
              onTap: () {
                _lastPeriod = null;
                _next();
              },
            ),
        ] else
          for (final option in question.options)
            _OptionTile(
              title: option,
              selected: option == answer,
              onTap: () {
                _answers[question.id] = option;
                _next();
              },
            ),
      ],
      footer: const [],
    );
  }

  Widget _consent() {
    const items = [
      (
        Icons.insights_rounded,
        'As previsões são estimativas feitas a partir das suas respostas e '
            'podem variar de pessoa para pessoa.',
      ),
      (
        Icons.medical_services_outlined,
        'A Pablife não substitui consulta médica, não faz diagnóstico e não '
            'é método contraceptivo.',
      ),
      (
        Icons.warning_amber_rounded,
        'Em caso de sangramento intenso, dor forte ou sangramento na '
            'gestação, procure atendimento médico.',
      ),
    ];

    return RegistrationLayout(
      title: _trail!.title,
      step: 'Antes de começar',
      onBack: _back,
      progress: _questions.length,
      totalSteps: _questions.length,
      fields: [
        const _Heading('Antes de começar', null),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PabColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PabColors.line),
          ),
          child: Column(
            children: [
              for (final (i, (icon, text)) in items.indexed) ...[
                if (i > 0) const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: PabColors.soft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 18, color: PabColors.softText),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: PabColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PabColors.lilac,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: PabColors.lilacText,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seus dados de saúde são sensíveis (LGPD): só você tem '
                  'acesso, eles não são usados para publicidade e você pode '
                  'apagá-los quando quiser. O modo fica ativo até você pedir '
                  'para sair.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: PabColors.lilacText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      footer: [
        RegPrimaryButton(
          label: 'Entendi e quero começar',
          loading: _saving,
          onTap: _finish,
        ),
      ],
    );
  }
}

/// Pergunta em destaque com a ajuda embaixo.
class _Heading extends StatelessWidget {
  final String title;
  final String? help;

  const _Heading(this.title, this.help);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          if (help != null) ...[
            const SizedBox(height: 8),
            Text(
              help!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: PabColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opção tocável (trilha, resposta ou data).
class _OptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? PabColors.soft : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? PabColors.accent : PabColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected ? PabColors.card : PabColors.soft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: PabColors.softText, size: 22),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PabColors.ink,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: PabColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: selected ? PabColors.softText : PabColors.muted,
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
