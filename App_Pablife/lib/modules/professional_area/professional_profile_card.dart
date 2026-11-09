import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/app_snackbar.dart';
import '../auth/pages/widgets/registration_layout.dart';
import 'professional_area_controller.dart';

/// Temas sugeridos (canvas PF). O profissional pode criar outros.
const suggestedTopics = [
  'Ansiedade',
  'Autoestima',
  'Carreira',
  'Luto',
  'Relacionamentos',
  'Sono',
  'Saúde da mulher',
  'Depressão',
  'TDAH',
  'Burnout',
  'Alimentação emocional',
  'Maternidade',
];

/// Perfil público do profissional (canvas PF): "Sobre você", os temas que
/// atende (viram filtros na busca dos pacientes), a visibilidade e a prévia
/// de como os pacientes veem o perfil.
class ProfessionalProfileCard extends StatefulWidget {
  const ProfessionalProfileCard({super.key});

  @override
  State<ProfessionalProfileCard> createState() =>
      _ProfessionalProfileCardState();
}

class _ProfessionalProfileCardState extends State<ProfessionalProfileCard> {
  final _bio = TextEditingController();
  final _newTopic = TextEditingController();
  final Set<String> _topics = {};
  final List<String> _custom = [];
  bool _visible = true;
  bool _ready = false;
  bool _saving = false;
  bool _saved = false;

  ProfessionalAreaController get _c => ProfessionalAreaController.to;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    final c = _c;
    if (c.loading) return;
    _bio.text = c.description;
    _topics
      ..clear()
      ..addAll(c.topics);
    _custom
      ..clear()
      ..addAll(c.topics.where((t) => !suggestedTopics.contains(t)));
    _visible = c.visible;
    _ready = true;
  }

  @override
  void dispose() {
    _bio.dispose();
    _newTopic.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _saved = false);

  void _addTopic() {
    final t = _newTopic.text.trim();
    if (t.isEmpty) return;
    final all = [...suggestedTopics, ..._custom];
    final existing = all.firstWhereOrNull(
      (x) => x.toLowerCase() == t.toLowerCase(),
    );
    setState(() {
      if (existing != null) {
        _topics.add(existing);
      } else {
        _custom.add(t);
        _topics.add(t);
      }
      _newTopic.clear();
      _saved = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ordered = [
      ...suggestedTopics.where(_topics.contains),
      ..._custom.where(_topics.contains),
    ];
    final error = await _c.saveProfile(
      description: _bio.text,
      topics: ordered,
      visible: _visible,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = error == null;
    });
    AppSnackbar.to.show(error ?? 'Perfil salvo.');
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalAreaController>(
      builder: (c) {
        if (!_ready && !c.loading) _sync();
        if (!_ready) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(color: PabColors.accent),
            ),
          );
        }
        final all = [...suggestedTopics, ..._custom];
        final chosen = all.where(_topics.contains).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _box(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sobre você',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bio,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 500,
                    onChanged: (_) => _changed(),
                    style: const TextStyle(fontSize: 14, color: PabColors.ink),
                    decoration: InputDecoration(
                      hintText:
                          'Conte como você atende, para quem e com que foco.',
                      hintStyle: const TextStyle(color: PabColors.muted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: PabColors.line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Temas que você atende',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        '${_topics.length} selecionados',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PabColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Viram filtros na busca dos pacientes.',
                    style: TextStyle(fontSize: 12, color: PabColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in all)
                        InputChip(
                          label: Text(t),
                          selected: _topics.contains(t),
                          showCheckmark: false,
                          onSelected: (on) => setState(() {
                            on ? _topics.add(t) : _topics.remove(t);
                            _saved = false;
                          }),
                          onDeleted: _custom.contains(t)
                              ? () => setState(() {
                                  _custom.remove(t);
                                  _topics.remove(t);
                                  _saved = false;
                                })
                              : null,
                          deleteIconColor: _topics.contains(t)
                              ? Colors.white
                              : PabColors.muted,
                          selectedColor: PabColors.ink,
                          backgroundColor: PabColors.card,
                          side: BorderSide(
                            color: _topics.contains(t)
                                ? PabColors.ink
                                : PabColors.line,
                          ),
                          shape: const StadiumBorder(),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _topics.contains(t)
                                ? Colors.white
                                : PabColors.ink,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newTopic,
                          maxLength: 40,
                          onSubmitted: (_) => _addTopic(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: PabColors.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Novo tema',
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: PabColors.line,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _addTopic,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          foregroundColor: PabColors.ink,
                          side: const BorderSide(color: PabColors.ink),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Adicionar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _visible,
                    activeTrackColor: PabColors.accent,
                    onChanged: (v) => setState(() {
                      _visible = v;
                      _saved = false;
                    }),
                    title: Text(
                      _visible
                          ? 'Perfil visível para novos pacientes'
                          : 'Perfil oculto · só quem tem consulta marcada te encontra',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RegPrimaryButton(
                    label: _saved ? 'Salvo' : 'Salvar perfil',
                    loading: _saving,
                    onTap: _save,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _preview(c, chosen),
          ],
        );
      },
    );
  }

  Widget _box(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: PabColors.card,
      border: Border.all(color: PabColors.line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget _preview(ProfessionalAreaController c, List<String> chosen) {
    final name = c.displayName;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    final type = c.professional?.type == 'nutritionist'
        ? 'Nutricionista'
        : 'Psicólogo(a)';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMO OS PACIENTES VEEM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: PabColors.softText,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PabColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: PabColors.ink,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: PabColors.ink,
                            ),
                          ),
                          Text(
                            '$type · online · 50 min',
                            style: const TextStyle(
                              fontSize: 12,
                              color: PabColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_bio.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _bio.text.trim(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: PabColors.ink,
                    ),
                  ),
                ],
                if (chosen.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in chosen)
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
                            t,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PabColors.softText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: PabColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Agendar consulta',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
