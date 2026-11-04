import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../women_health_controller.dart';
import '../women_health_data.dart';

enum _Stage { pick, quiz, consent }

/// Entrada do modo: escolha da trilha, questionário e avisos.
class WomenHealthFlowPage extends StatefulWidget {
  const WomenHealthFlowPage({super.key});

  static Future<void> open() async {
    await Get.to<void>(() => const WomenHealthFlowPage());
  }

  @override
  State<WomenHealthFlowPage> createState() => _WomenHealthFlowPageState();
}

class _WomenHealthFlowPageState extends State<WomenHealthFlowPage> {
  _Stage _stage = _Stage.pick;
  WomenTrail? _trail;
  int _step = 0;
  final Map<String, String> _answers = {};
  DateTime? _lastPeriod;

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
      initialDate: today,
      firstDate: today.subtract(Duration(days: days)),
      lastDate: today,
      helpText: 'Escolha a data',
    );
    if (date == null) return;
    _lastPeriod = date;
    _next();
  }

  Future<void> _finish() async {
    await WomenHealthController.to.start(
      newTrail: _trail!,
      newAnswers: Map.of(_answers),
      newLastPeriod: _lastPeriod,
    );
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WomenColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: WomenColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _back,
                      style: TextButton.styleFrom(
                        foregroundColor: WomenColors.plum,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.chevron_left),
                      label: Text(
                        _stage == _Stage.pick ? 'Voltar ao planner' : 'Voltar',
                      ),
                    ),
                    const SizedBox(height: 8),
                    switch (_stage) {
                      _Stage.pick => _pick(),
                      _Stage.quiz => _quiz(),
                      _Stage.consent => _consent(),
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.25,
      color: WomenColors.plum,
    ),
  );

  Widget _body(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, height: 1.5, color: WomenColors.muted),
  );

  Widget _pick() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('O que você quer acompanhar?'),
        const SizedBox(height: 6),
        _body('Escolha uma trilha. Você pode trocar depois.'),
        const SizedBox(height: 20),
        for (final trail in WomenTrail.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionTile(
              leadingColor: trail.color,
              title: trail.title,
              subtitle: trail.description,
              onTap: () => setState(() {
                _trail = trail;
                _step = 0;
                _answers.clear();
                _lastPeriod = null;
                _stage = _Stage.quiz;
              }),
            ),
          ),
      ],
    );
  }

  Widget _quiz() {
    final question = _questions[_step];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_trail!.title} · Pergunta ${_step + 1} de ${_questions.length}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: WomenColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (_step + 1) / _questions.length,
            minHeight: 8,
            backgroundColor: WomenColors.blush,
            valueColor: const AlwaysStoppedAnimation(WomenColors.lilac),
          ),
        ),
        const SizedBox(height: 20),
        _title(question.text),
        if (question.help != null) ...[
          const SizedBox(height: 8),
          _body(question.help!),
        ],
        const SizedBox(height: 20),
        if (question.isDate) ...[
          _OptionTile(title: 'Escolher a data', onTap: _pickDate),
          if (question.unknownLabel != null) ...[
            const SizedBox(height: 10),
            _OptionTile(
              title: question.unknownLabel!,
              onTap: () {
                _lastPeriod = null;
                _next();
              },
            ),
          ],
        ] else
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                title: option,
                onTap: () {
                  _answers[question.id] = option;
                  _next();
                },
              ),
            ),
      ],
    );
  }

  Widget _consent() {
    const items = [
      (
        WomenColors.lilac,
        'As previsões do planner são estimativas feitas a partir das suas '
            'respostas e podem variar de pessoa para pessoa.',
      ),
      (
        WomenColors.mauve,
        'O Pablife não substitui consulta médica, não faz diagnóstico e não '
            'é método contraceptivo.',
      ),
      (
        WomenColors.rose,
        'Em caso de sangramento intenso, dor forte ou sangramento na '
            'gestação, procure atendimento médico.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Antes de começar'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WomenColors.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WomenColors.line),
          ),
          child: Column(
            children: [
              for (final (color, text) in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6, right: 10),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: WomenColors.plum,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _body(
          'Versão de teste: suas respostas ficam só neste aparelho e não vão '
          'para a Pablife. O modo fica ativo até você pedir para sair.',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _finish,
            style: FilledButton.styleFrom(
              backgroundColor: WomenColors.plum,
              foregroundColor: WomenColors.light,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Entendi e quero começar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? leadingColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WomenColors.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WomenColors.line),
          ),
          child: Row(
            children: [
              if (leadingColor != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: leadingColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                        color: WomenColors.plum,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: WomenColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
