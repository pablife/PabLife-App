import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infra/models/patient_record_model.dart';
import '../../infra/models/professional_appointment_model.dart';
import '../../infra/repositories/patient_record_repository.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/app_snackbar.dart';
import '../auth/pages/widgets/registration_layout.dart';
import 'appointment_outcome.dart';
import 'professional_area_controller.dart';
import 'professional_dashboard_page.dart'
    show ProfessionalDashboardPage, firstNameAndInitial, hhmm;

/// Sala de atendimento do profissional (canvas PS). A chamada acontece no
/// link de vídeo do profissional (Meet, Zoom…): a sala abre o link, conta o
/// tempo, guarda a anotação privada e, no fim, registra como foi a consulta.
class ProfessionalRoomPage extends StatefulWidget {
  final ProfessionalAppointmentModel appointment;

  const ProfessionalRoomPage({super.key, required this.appointment});

  static Future<void> open(ProfessionalAppointmentModel appointment) async {
    await Get.to<void>(() => ProfessionalRoomPage(appointment: appointment));
  }

  @override
  State<ProfessionalRoomPage> createState() => _ProfessionalRoomPageState();
}

enum _Stage { before, inCall, ended }

class _ProfessionalRoomPageState extends State<ProfessionalRoomPage> {
  final _note = TextEditingController();
  final _link = TextEditingController();
  Timer? _tick;
  _Stage _stage = _Stage.before;
  bool _editingLink = false;
  bool _savingLink = false;
  bool _savingNote = false;
  bool _noteSaved = false;
  bool _correcting = false;
  bool _showCancel = false;

  ProfessionalAreaController get _c => ProfessionalAreaController.to;

  /// A consulta mais recente (o registro pode ter mudado aqui).
  ProfessionalAppointmentModel get _a =>
      _c.appointments.firstWhereOrNull((x) => x.id == widget.appointment.id) ??
      widget.appointment;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _stage == _Stage.inCall) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _note.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    final url = _c.meetingUrl;
    if (url == null || url.isEmpty) {
      setState(() => _editingLink = true);
      AppSnackbar.to.show('Cadastre o link da sua sala de vídeo primeiro.');
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      AppSnackbar.to.show('Não foi possível abrir o link. Confira o endereço.');
      return;
    }
    setState(() => _stage = _Stage.inCall);
  }

  Future<void> _saveLink() async {
    var url = _link.text.trim();
    if (url.isNotEmpty && !url.startsWith('http')) url = 'https://$url';
    if (!url.startsWith('https://')) {
      AppSnackbar.to.show('Use um link que comece com https://');
      return;
    }
    setState(() => _savingLink = true);
    final error = await _c.saveMeetingUrl(url);
    if (!mounted) return;
    setState(() {
      _savingLink = false;
      if (error == null) _editingLink = false;
    });
    AppSnackbar.to.show(error ?? 'Link da sala salvo.');
  }

  Future<void> _saveNote() async {
    final text = _note.text.trim();
    if (text.isEmpty) return;
    setState(() => _savingNote = true);
    final repo = PatientRecordRepository();
    final patient = await repo.getPatientIdByAppointment(_a.id);
    final patientId = patient.data;
    String? error;
    if (patientId == null) {
      error = 'Ficha do paciente não encontrada para esta consulta.';
    } else {
      final start = _a.startAt.toLocal();
      final created = await repo.createPatientRecord(
        patientId: patientId,
        type: PatientRecordType.note,
        title:
            'Anotação da sessão de ${start.day.toString().padLeft(2, '0')}/'
            '${start.month.toString().padLeft(2, '0')}',
        description: text,
        isShared: false,
      );
      if (!created.success) error = 'Não foi possível salvar a anotação.';
    }
    if (!mounted) return;
    setState(() {
      _savingNote = false;
      _noteSaved = error == null;
    });
    AppSnackbar.to.show(error ?? 'Anotação salva na ficha. Só você vê.');
  }

  Future<void> _register(AppointmentOutcome outcome) async {
    final ok = await _c.register(context, _a, outcome);
    if (ok && mounted) {
      setState(() {
        _correcting = false;
        _stage = _Stage.ended;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalAreaController>(
      builder: (c) {
        final a = _a;
        final outcome = AppointmentOutcome.of(a);
        const minutes = minSessionMinutes;

        Widget body;
        if (outcome != null && !_correcting) {
          body = _Registered(
            outcome: outcome,
            appointment: a,
            canCorrect: _canCorrect(a),
            onCorrect: () => setState(() => _correcting = true),
          );
        } else if (_stage == _Stage.ended || _correcting) {
          body = _OutcomeChoice(
            appointment: a,
            busy: c.registering == a.id,
            onPick: _register,
          );
        } else if (_stage == _Stage.inCall) {
          body = _inCall(a, minutes);
        } else {
          body = _before(a, minutes);
        }

        return PabCardFrame(
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: PabColors.ink,
                padding: EdgeInsets.fromLTRB(
                  8,
                  MediaQuery.paddingOf(context).top + 10,
                  16,
                  16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Get.back<void>(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: PabColors.onInk,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sala de atendimento',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: PabColors.onInk,
                            ),
                          ),
                          Text(
                            'Consulta online · $minutes min',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PabColors.onInkSoft,
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [body],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _canCorrect(ProfessionalAppointmentModel a) {
    final closedAt = a.finishedAt ?? a.updatedAt;
    return DateTime.now().difference(closedAt).inHours < 24;
  }

  Widget _patientCard(ProfessionalAppointmentModel a, String status) {
    final initials = a.patientName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: PabColors.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${firstNameAndInitial(a.patientName)} · ${hhmm(a.startAt)} · '
                  '${_c.sessionNumber(a)}ª sessão',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PabColors.accentText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard() {
    final url = _c.meetingUrl ?? '';
    final editing = _editingLink || url.isEmpty;
    if (editing && _link.text.isEmpty && url.isNotEmpty) _link.text = url;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: editing ? PabColors.lilac : PabColors.card,
        border: Border.all(color: editing ? PabColors.lilac : PabColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: editing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Link da sua sala de vídeo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PabColors.lilacText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cole o link fixo do Google Meet, Zoom ou outro. O paciente '
                  'vê esse link 15 minutos antes da consulta.',
                  style: TextStyle(fontSize: 13, color: PabColors.lilacText),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(fontSize: 14, color: PabColors.ink),
                  decoration: InputDecoration(
                    hintText: 'https://meet.google.com/…',
                    filled: true,
                    fillColor: PabColors.card,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _savingLink ? null : _saveLink,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    backgroundColor: PabColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _savingLink ? 'Salvando…' : 'Salvar link',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.link_rounded, color: PabColors.accentText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Uri.tryParse(url)?.host ?? url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PabColors.ink,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _link.text = url;
                    _editingLink = true;
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: PabColors.accentText,
                  ),
                  child: const Text(
                    'Trocar',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _before(ProfessionalAppointmentModel a, int minutes) {
    final now = DateTime.now();
    final toStart = a.startAt.difference(now).inMinutes;
    final status = toStart > 60
        ? 'Começa às ${hhmm(a.startAt)}'
        : toStart > 0
        ? 'Começa em $toStart min'
        : a.endOfScheduledWindow.isAfter(now)
        ? 'Horário da consulta: já pode entrar'
        : 'O horário já passou: registre como foi';
    final started = !a.startAt.isAfter(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _patientCard(a, status),
        const SizedBox(height: 12),
        _linkCard(),
        const SizedBox(height: 14),
        RegPrimaryButton(
          label: 'Entrar na sala',
          icon: const Icon(
            Icons.videocam_rounded,
            size: 20,
            color: PabColors.ink,
          ),
          onTap: _enter,
        ),
        if (started) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => _stage = _Stage.ended),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: PabColors.card,
              foregroundColor: PabColors.ink,
              side: const BorderSide(color: PabColors.lineStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Registrar como foi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() => _showCancel = !_showCancel),
            style: TextButton.styleFrom(foregroundColor: PabColors.muted),
            child: const Text(
              'A consulta não vai acontecer?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (_showCancel)
            Row(
              children: [
                for (final o in const [
                  AppointmentOutcome.cancelledPatient,
                  AppointmentOutcome.cancelledProfessional,
                ]) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _c.registering == a.id
                          ? null
                          : () => _register(o),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: PabColors.ink,
                        side: const BorderSide(color: PabColors.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        o.action,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (o == AppointmentOutcome.cancelledPatient)
                    const SizedBox(width: 8),
                ],
              ],
            ),
        ],
      ],
    );
  }

  Widget _inCall(ProfessionalAppointmentModel a, int minutes) {
    final elapsed = DateTime.now().difference(a.startAt);
    final shown = elapsed.isNegative ? Duration.zero : elapsed;
    String two(int n) => n.toString().padLeft(2, '0');
    final clock =
        '${two(shown.inMinutes)}:${two(shown.inSeconds % 60)} de $minutes:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PabColors.ink,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5A7A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Em atendimento · $clock',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                firstNameAndInitial(a.patientName),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PabColors.onInk,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'A chamada abriu no seu link de vídeo. Se fechou sem querer, '
                'é só abrir de novo.',
                style: TextStyle(fontSize: 13, color: PabColors.onInkSoft),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _enter,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text(
                        'Abrir chamada',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => setState(() => _stage = _Stage.ended),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: const Color(0xFFE5484D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Encerrar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PabColors.card,
            border: Border.all(color: PabColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Anotação da sessão',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    'vai para a ficha · só você vê',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PabColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                minLines: 4,
                maxLines: 10,
                onChanged: (_) {
                  if (_noteSaved) setState(() => _noteSaved = false);
                },
                style: const TextStyle(fontSize: 14, color: PabColors.ink),
                decoration: InputDecoration(
                  hintText: 'Escreva durante ou depois da sessão…',
                  hintStyle: const TextStyle(color: PabColors.muted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: PabColors.line),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _savingNote || _noteSaved ? null : _saveNote,
                  style: FilledButton.styleFrom(
                    backgroundColor: PabColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _noteSaved
                        ? 'Salva'
                        : _savingNote
                        ? 'Salvando…'
                        : 'Salvar anotação',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Como foi esta consulta?": os cinco registros.
class _OutcomeChoice extends StatelessWidget {
  final ProfessionalAppointmentModel appointment;
  final bool busy;
  final ValueChanged<AppointmentOutcome> onPick;

  const _OutcomeChoice({
    required this.appointment,
    required this.busy,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final started = !a.startAt.isAfter(DateTime.now());
    Widget other(AppointmentOutcome o) => OutlinedButton(
      onPressed: busy ? null : () => onPick(o),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        foregroundColor: PabColors.ink,
        side: const BorderSide(color: PabColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        o.action,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SESSÃO · ${firstNameAndInitial(a.patientName).toUpperCase()} · '
            '${hhmm(a.startAt)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: PabColors.accentText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Como foi esta consulta?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O registro vai para o histórico e define o saldo do paciente.',
            style: TextStyle(fontSize: 14, color: PabColors.muted),
          ),
          const SizedBox(height: 14),
          if (started) ...[
            FilledButton.icon(
              onPressed: busy || !canComplete(a)
                  ? null
                  : () => onPick(AppointmentOutcome.completed),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: PabColors.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                canComplete(a)
                    ? 'Consulta concluída'
                    : 'Concluída a partir das ${hhmm(completableAt(a))}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!canComplete(a))
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'A sessão tem no mínimo $minSessionMinutes minutos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: PabColors.muted),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: busy ? null : () => onPick(AppointmentOutcome.noShow),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                foregroundColor: PabColors.error,
                side: const BorderSide(color: PabColors.errorLine),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Paciente não compareceu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 14),
          ],
          const Text(
            'Não aconteceu por outro motivo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: PabColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          other(AppointmentOutcome.cancelledPatient),
          const SizedBox(height: 8),
          other(AppointmentOutcome.cancelledProfessional),
          if (started) ...[
            const SizedBox(height: 8),
            other(AppointmentOutcome.technicalIssue),
          ],
        ],
      ),
    );
  }
}

/// "Registrado ✓": o resultado e o que acontece com o saldo.
class _Registered extends StatelessWidget {
  final AppointmentOutcome outcome;
  final ProfessionalAppointmentModel appointment;
  final bool canCorrect;
  final VoidCallback onCorrect;

  const _Registered({
    required this.outcome,
    required this.appointment,
    required this.canCorrect,
    required this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = outcome.colors;
    final reason = appointment.cancellationReason?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutcomeTag(
              label: 'Registrado',
              background: bg,
              foreground: fg,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            outcome.action,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            outcome.effect,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: PabColors.muted,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Justificativa: $reason',
              style: const TextStyle(fontSize: 13, color: PabColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: RegPrimaryButton(
                  label: 'Voltar ao Dashboard',
                  onTap: () {
                    Get.back<void>();
                    ProfessionalDashboardPage.goToTab(0);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.back<void>();
                    ProfessionalDashboardPage.goToTab(1);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    foregroundColor: PabColors.ink,
                    side: const BorderSide(color: PabColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Abrir agenda',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          if (canCorrect)
            TextButton(
              onPressed: onCorrect,
              style: TextButton.styleFrom(foregroundColor: PabColors.muted),
              child: const Text(
                'Corrigir registro',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
