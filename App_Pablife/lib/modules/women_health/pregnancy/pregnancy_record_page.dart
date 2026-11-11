import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import 'pregnancy_controller.dart';
import 'pregnancy_models.dart';
import 'pregnancy_widgets.dart';

/// "Novo registro": consulta, ultrassom, exame, movimentos, sintoma ou
/// anotação, com medidas, foto e a opção de compartilhar com o profissional.
class PregnancyRecordPage extends StatefulWidget {
  final DateTime? date;

  const PregnancyRecordPage({super.key, this.date});

  static Future<void> open({DateTime? date}) =>
      Get.to<void>(() => PregnancyRecordPage(date: date))!;

  @override
  State<PregnancyRecordPage> createState() => _PregnancyRecordPageState();
}

class _PregnancyRecordPageState extends State<PregnancyRecordPage> {
  final c = PregnancyController.to;

  late DateTime _date = widget.date ?? DateUtils.dateOnly(DateTime.now());
  PregnancyRecordType _type = PregnancyRecordType.consulta;
  String? _feeling;
  final Set<String> _symptoms = {};
  bool _shared = false;
  bool _saving = false;
  bool _touched = false;

  final _weight = TextEditingController();
  final _pressure = TextEditingController();
  final _bpm = TextEditingController();
  final _babyWeight = TextEditingController();
  final _babyLength = TextEditingController();
  final _notes = TextEditingController();

  Uint8List? _photo;
  String? _photoName;

  @override
  void initState() {
    super.initState();
    for (final t in [_weight, _pressure]) {
      t.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final t in [
      _weight,
      _pressure,
      _bpm,
      _babyWeight,
      _babyLength,
      _notes,
    ]) {
      t.dispose();
    }
    super.dispose();
  }

  static double? _decimal(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  String? get _weightError {
    if (_weight.text.trim().isEmpty) return null;
    final v = _decimal(_weight.text);
    return v == null || v < 30 || v > 250 ? 'Peso entre 30 e 250 kg' : null;
  }

  String? get _pressureError {
    final v = _pressure.text.trim();
    if (v.isEmpty) return null;
    return RegExp(r'^\d{2,3}/\d{2,3}$').hasMatch(v) ? null : 'Use 120/80';
  }

  String? get _bpmError {
    if (_bpm.text.trim().isEmpty) return null;
    final v = int.tryParse(_bpm.text.trim());
    return v == null || v < 50 || v > 250 ? 'Entre 50 e 250' : null;
  }

  String? get _babyWeightError {
    if (_babyWeight.text.trim().isEmpty) return null;
    final v = int.tryParse(_babyWeight.text.trim());
    return v == null || v > 7000 ? 'Até 7000 g' : null;
  }

  String? get _babyLengthError {
    if (_babyLength.text.trim().isEmpty) return null;
    final v = _decimal(_babyLength.text);
    return v == null || v > 70 ? 'Até 70 cm' : null;
  }

  bool get _valid =>
      _weightError == null &&
      _pressureError == null &&
      _bpmError == null &&
      _babyWeightError == null &&
      _babyLengthError == null;

  /// Sinal de alerta marcado ou pressão alta: "Procure atendimento agora".
  bool get _needsCare =>
      _symptoms.any(pregnancyAlertSigns.contains) ||
      isHighPressure(_pressure.text);

  Future<void> _pickDate() async {
    final p = c.pregnancy;
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: p?.dum ?? today.subtract(const Duration(days: 300)),
      lastDate: today,
      locale: const Locale('pt', 'BR'),
      helpText: 'Data do registro',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final file = result?.files.firstOrNull;
      if (file == null || file.bytes == null) return;
      if (file.size > 10 * 1024 * 1024) {
        AppSnackbar.to.show('A foto passa de 10 MB. Escolha uma menor.');
        return;
      }
      setState(() {
        _photo = file.bytes;
        _photoName = file.name;
      });
    } catch (e) {
      AppSnackbar.to.show('Não foi possível abrir a foto.');
    }
  }

  Future<void> _save() async {
    setState(() => _touched = true);
    if (!_valid || _saving) return;
    setState(() => _saving = true);

    final notes = [
      if (_symptoms.isNotEmpty) 'Sintomas: ${_symptoms.join(', ')}.',
      if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
    ].join('\n');
    final ext = _photoName?.split('.').last;

    final ok = await c.saveRecord(
      date: _date,
      type: _type,
      motherWeight: _decimal(_weight.text),
      pressure: _pressure.text.trim().isEmpty ? null : _pressure.text.trim(),
      heartRate: int.tryParse(_bpm.text.trim()),
      babyWeight: int.tryParse(_babyWeight.text.trim()),
      babyLength: _decimal(_babyLength.text),
      feeling: _feeling,
      notes: notes.isEmpty ? null : notes,
      photo: _photo,
      photoExtension: ext,
      shared: _shared,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Get.back<void>();
      AppSnackbar.to.show('Registro salvo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = c.pregnancy;
    final week = p?.weekOn(_date);
    final last = c.lastWeight;
    final weightNow = _decimal(_weight.text);

    return Scaffold(
      backgroundColor: PabColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 20,
                  20,
                  0,
                ),
                child: Row(
                  children: [
                    PregIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Fechar',
                      onPressed: () => Get.back<void>(),
                    ),
                    const SizedBox(width: 12),
                    if (week != null) ...[
                      BabyImage(
                        url: c.imageFor(week),
                        size: 48,
                        semantics: 'Seu bebê na semana $week',
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Novo registro',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: PabColors.ink,
                            ),
                          ),
                          if (week != null)
                            Text(
                              'Semana $week · ${trimesterLabel(week)}',
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
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    const _Label('Data do registro'),
                    Row(
                      children: [
                        Expanded(
                          child: _Box(
                            onTap: _pickDate,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dateBr.format(_date),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: PabColors.ink,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: PabColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => setState(
                            () => _date = DateUtils.dateOnly(DateTime.now()),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: PabColors.soft,
                            foregroundColor: PabColors.softText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Hoje',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _Label('O que você quer registrar?'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in PregnancyRecordType.values)
                          _Choice(
                            label: t.label,
                            selected: _type == t,
                            dark: true,
                            onTap: () => setState(() => _type = t),
                          ),
                      ],
                    ),
                    if (_type == PregnancyRecordType.sintoma) ...[
                      const SizedBox(height: 18),
                      const _Label('O que você está sentindo?'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in [
                            ...pregnancyCommonSymptoms,
                            ...pregnancyAlertSigns,
                          ])
                            _Choice(
                              label: s,
                              selected: _symptoms.contains(s),
                              onTap: () => setState(
                                () => _symptoms.contains(s)
                                    ? _symptoms.remove(s)
                                    : _symptoms.add(s),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (_needsCare) ...[
                      const SizedBox(height: 16),
                      const _SeekCareCard(),
                    ],
                    const SizedBox(height: 18),
                    _Panel(
                      title: 'Minhas medidas',
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Field(
                                label: 'Peso (kg)',
                                controller: _weight,
                                hint: '0,0',
                                decimal: true,
                                error: _touched ? _weightError : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Field(
                                label: 'Pressão',
                                controller: _pressure,
                                hint: '120/80',
                                pressure: true,
                                error: _touched ? _pressureError : null,
                              ),
                            ),
                          ],
                        ),
                        if (last != null &&
                            weightNow != null &&
                            _weightError == null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: PabColors.softText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Desde ${shortDay(last.date)}: '
                                '${weightNow - last.motherWeight! >= 0 ? '+' : '−'}'
                                '${formatKg((weightNow - last.motherWeight!).abs())}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: PabColors.softText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Panel(
                      title: 'Dados do bebê',
                      subtitle: '(se tiver)',
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Field(
                                label: 'Batimentos (bpm)',
                                controller: _bpm,
                                hint: '000',
                                error: _touched ? _bpmError : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Field(
                                label: 'Peso estimado (g)',
                                controller: _babyWeight,
                                hint: '0',
                                error: _touched ? _babyWeightError : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Field(
                          label: 'Comprimento estimado (cm)',
                          controller: _babyLength,
                          hint: '0,0',
                          decimal: true,
                          error: _touched ? _babyLengthError : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _Label('Como estou me sentindo?'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in pregnancyFeelings)
                          _Choice(
                            label: f,
                            selected: _feeling == f,
                            onTap: () => setState(
                              () => _feeling = _feeling == f ? null : f,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _Label('Anotações'),
                    TextField(
                      controller: _notes,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 1800,
                      decoration: _inputDecoration(
                        'Como foi a consulta, o que sentiu, dúvidas para a '
                        'próxima…',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_photo == null)
                      OutlinedButton.icon(
                        onPressed: _pickPhoto,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: PabColors.softText,
                          side: const BorderSide(color: PabColors.lineStrong),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text(
                          'Adicionar foto do ultrassom ou exame',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PabColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PabColors.line),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _photo!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _photoName ?? 'Foto',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: PabColors.ink,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remover foto',
                              onPressed: () => setState(() {
                                _photo = null;
                                _photoName = null;
                              }),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: PabColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: PabColors.lilac,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Compartilhar com meu profissional',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: PabColors.ink,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Só os profissionais com quem você tem '
                                  'consulta poderão ver este registro.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: PabColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _shared,
                            onChanged: (v) => setState(() => _shared = v),
                            activeTrackColor: PabColors.ink,
                            activeThumbColor: PabColors.card,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: PabColors.line)),
                ),
                child: PregPrimaryButton(
                  label: 'Salvar registro',
                  busy: _saving,
                  onPressed: p == null ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String shortDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

InputDecoration _inputDecoration(String hint, {String? error}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    errorText: error,
    filled: true,
    fillColor: PabColors.card,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(PabColors.line),
    enabledBorder: border(PabColors.line),
    focusedBorder: border(PabColors.pink, 1.5),
    errorBorder: border(PabColors.error),
    focusedErrorBorder: border(PabColors.error, 1.5),
  );
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: PabColors.ink,
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _Box({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PabColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: PabColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = !selected
        ? PabColors.card
        : dark
        ? PabColors.ink
        : PabColors.soft;
    final fg = selected && dark ? PabColors.onInk : PabColors.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: selected && !dark
              ? const BorderSide(color: PabColors.pink, width: 2)
              : selected
              ? BorderSide.none
              : const BorderSide(color: PabColors.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _Panel({required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PabColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: title,
              children: [
                if (subtitle != null)
                  TextSpan(
                    text: ' $subtitle',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: PabColors.muted,
                    ),
                  ),
              ],
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool decimal;
  final bool pressure;
  final String? error;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.decimal = false,
    this.pressure = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        TextField(
          controller: controller,
          keyboardType: pressure
              ? TextInputType.datetime
              : TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(
                pressure
                    ? r'[0-9/]'
                    : decimal
                    ? r'[0-9,.]'
                    : r'[0-9]',
              ),
            ),
            LengthLimitingTextInputFormatter(7),
          ],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: PabColors.ink,
          ),
          decoration: _inputDecoration(hint, error: error),
        ),
      ],
    );
  }
}

/// "Procure atendimento agora": sem diagnóstico, só a orientação.
class _SeekCareCard extends StatelessWidget {
  const _SeekCareCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PregColors.alert,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PabColors.errorLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: PabColors.error),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Procure atendimento agora',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PabColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sangramento, perda de líquido, bebê sem mexer, dor forte ou '
            'pressão alta precisam ser avaliados por um profissional de saúde. '
            'Vá a uma maternidade ou pronto atendimento, ou ligue para o SAMU.',
            style: TextStyle(fontSize: 13, height: 1.5, color: PabColors.ink),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:192')),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: PabColors.error,
              foregroundColor: PabColors.onInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.call_rounded),
            label: const Text(
              'Ligar 192 (SAMU)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
