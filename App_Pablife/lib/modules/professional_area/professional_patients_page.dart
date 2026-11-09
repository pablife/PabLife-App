import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infra/models/patient_record_model.dart';
import '../../infra/models/professional_appointment_model.dart';
import '../../infra/repositories/patient_record_repository.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../shared/utils/wide_layout.dart';
import '../../widgets/design_system/whatsapp_icon.dart';
import '../../widgets/pab_logo.dart';
import 'appointment_outcome.dart';
import 'professional_area_controller.dart';
import 'professional_dashboard_page.dart' show ProfessionalDashboardPage, hhmm;
import 'professional_room_page.dart';

/// Um paciente do profissional, montado a partir das consultas.
class PatientSummary {
  final String id;
  final String name;
  final String? phone;
  final List<ProfessionalAppointmentModel> appointments;

  PatientSummary(this.id, this.name, this.phone, this.appointments);

  int get sessions =>
      appointments.where((a) => a.status == AppointmentStatus.completed).length;

  ProfessionalAppointmentModel? get next {
    final now = DateTime.now();
    final list =
        appointments
            .where(
              (a) =>
                  a.status == AppointmentStatus.scheduled &&
                  a.endOfScheduledWindow.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return list.firstOrNull;
  }

  ProfessionalAppointmentModel? get last {
    final list =
        appointments
            .where((a) => a.status == AppointmentStatus.completed)
            .toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt));
    return list.firstOrNull;
  }

  /// Consulta mais recente (para ligar a anotação à ficha).
  ProfessionalAppointmentModel get latest => (List.of(
    appointments,
  )..sort((a, b) => b.startAt.compareTo(a.startAt))).first;

  DateTime get since => (List.of(
    appointments,
  )..sort((a, b) => a.startAt.compareTo(b.startAt))).first.startAt;

  PatientStatus get status {
    if (next != null) {
      return sessions == 0 ? PatientStatus.first : PatientStatus.active;
    }
    final outcome = AppointmentOutcome.of(latest);
    if (outcome != null && outcome != AppointmentOutcome.completed) {
      return PatientStatus.reschedule;
    }
    return PatientStatus.noNext;
  }

  static List<PatientSummary> from(List<ProfessionalAppointmentModel> all) {
    final byId = <String, List<ProfessionalAppointmentModel>>{};
    for (final a in all) {
      if (a.patientId.isEmpty) continue;
      byId.putIfAbsent(a.patientId, () => []).add(a);
    }
    return [
      for (final e in byId.entries)
        PatientSummary(
          e.key,
          e.value.first.patientName,
          e.value.first.patientPhone,
          e.value,
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}

enum PatientStatus {
  active('Em acompanhamento', PabColors.soft, PabColors.softText),
  first('Primeira consulta', PabColors.lilac, PabColors.lilacText),
  reschedule('Remarcar', Color(0xFFFFF1D6), Color(0xFF6B4A00)),
  noNext('Sem próxima', PabColors.track, PabColors.muted);

  final String label;
  final Color bg;
  final Color fg;
  const PatientStatus(this.label, this.bg, this.fg);
}

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .take(2)
    .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
    .join();

String _shortDate(DateTime d) {
  final l = d.toLocal();
  final now = DateTime.now();
  if (l.year == now.year && l.month == now.month && l.day == now.day) {
    return 'Hoje, ${hhmm(l)}';
  }
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}, ${hhmm(l)}';
}

Future<void> _openWhatsApp(PatientSummary p) async {
  final digits = (p.phone ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    AppSnackbar.to.show('Este paciente não tem telefone cadastrado.');
    return;
  }
  final number = digits.startsWith('55') ? digits : '55$digits';
  await launchUrl(
    Uri.parse('https://wa.me/$number'),
    mode: LaunchMode.externalApplication,
  );
}

/// Pacientes do profissional (canvas PP): busca, filtros e a ficha com as
/// anotações privadas de sessão.
class ProfessionalPatientsPage extends StatefulWidget {
  const ProfessionalPatientsPage({super.key});

  @override
  State<ProfessionalPatientsPage> createState() =>
      _ProfessionalPatientsPageState();
}

class _ProfessionalPatientsPageState extends State<ProfessionalPatientsPage> {
  final _search = TextEditingController();
  PatientStatus? _filter;
  String? _selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ProfessionalAreaController.to;
    return GetBuilder<ProfessionalAreaController>(
      builder: (c) {
        final wide = isWideLayout(context);
        final all = PatientSummary.from(c.appointments);
        final q = _search.text.trim().toLowerCase();
        final list = all
            .where((p) => _filter == null || p.status == _filter)
            .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
            .toList();
        final selected =
            all.firstWhereOrNull((p) => p.id == _selected) ??
            (wide && list.isNotEmpty ? list.first : null);

        final listView = _list(c, all, list, wide, selected);
        if (!wide) {
          return Scaffold(
            backgroundColor: PabColors.background,
            body: RefreshIndicator(
              color: PabColors.accent,
              onRefresh: controller.load,
              child: listView,
            ),
          );
        }
        return Scaffold(
          backgroundColor: PabColors.background,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 420, child: listView),
              Expanded(
                child: selected == null
                    ? const Center(
                        child: Text(
                          'Escolha um paciente.',
                          style: TextStyle(color: PabColors.muted),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: _PatientDetail(
                          key: ValueKey(selected.id),
                          patient: selected,
                          embedded: true,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _list(
    ProfessionalAreaController c,
    List<PatientSummary> all,
    List<PatientSummary> list,
    bool wide,
    PatientSummary? selected,
  ) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: PabColors.ink,
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 18,
            16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!wide)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: PabLogo(size: 22),
                ),
              const Text(
                'Pacientes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PabColors.onInk,
                ),
              ),
              Text(
                all.length == 1 ? '1 paciente' : '${all.length} pacientes',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PabColors.onInkSoft,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 15, color: PabColors.ink),
                decoration: InputDecoration(
                  hintText: 'Buscar paciente',
                  prefixIcon: const Icon(Icons.search, color: PabColors.muted),
                  filled: true,
                  fillColor: PabColors.card,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Todos', _filter == null, () => _filter = null),
                    for (final s in PatientStatus.values)
                      _chip(s.label, _filter == s, () => _filter = s),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (c.loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: PabColors.accent),
                  ),
                )
              else if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhum paciente encontrado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: PabColors.muted),
                  ),
                ),
              for (final p in list) ...[
                _row(p, wide, selected?.id == p.id),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool on, VoidCallback pick) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => setState(pick),
      showCheckmark: false,
      selectedColor: PabColors.ink,
      backgroundColor: PabColors.card,
      side: BorderSide(color: on ? PabColors.ink : PabColors.line),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: on ? Colors.white : PabColors.ink,
      ),
    ),
  );

  Widget _row(PatientSummary p, bool wide, bool selected) {
    final s = p.status;
    final next = p.next;
    return Material(
      color: selected ? PabColors.soft : PabColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? PabColors.accent : PabColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (wide) {
            setState(() => _selected = p.id);
          } else {
            Get.to<void>(
              () => Scaffold(
                backgroundColor: PabColors.background,
                body: _PatientDetail(patient: p, embedded: false),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: PabColors.ink,
                child: Text(
                  _initials(p.name),
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
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                    Text(
                      '${p.sessions} ${p.sessions == 1 ? 'sessão' : 'sessões'}'
                      ' · próxima: ${next == null ? '—' : _shortDate(next.startAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PabColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutcomeTag(
                      label: s.label,
                      background: s.bg,
                      foreground: s.fg,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Conversar com ${p.name} no WhatsApp',
                onPressed: () => _openWhatsApp(p),
                icon: const WhatsAppIcon(size: 22, color: WhatsAppIcon.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ficha do paciente: números, ações e anotações de sessão (só o
/// profissional vê).
class _PatientDetail extends StatefulWidget {
  final PatientSummary patient;
  final bool embedded;

  const _PatientDetail({
    super.key,
    required this.patient,
    required this.embedded,
  });

  @override
  State<_PatientDetail> createState() => _PatientDetailState();
}

class _PatientDetailState extends State<_PatientDetail> {
  final _note = TextEditingController();
  List<PatientRecordModel> _notes = [];
  bool _loading = true;
  bool _saving = false;

  PatientSummary get p => widget.patient;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profId = ProfessionalAreaController.to.professional?.id;
    try {
      final rows = await Supabase.instance.client
          .from('tb_patient_records')
          .select('*, patient:tb_patients!inner(user_id, professional_id)')
          .eq('patient.user_id', p.id)
          .eq('patient.professional_id', profId ?? '')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(50);
      _notes = [
        for (final r in rows)
          PatientRecordModel.fromMap(Map<String, dynamic>.from(r as Map)),
      ];
    } catch (_) {
      _notes = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final text = _note.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final repo = PatientRecordRepository();
    final patient = await repo.getPatientIdByAppointment(p.latest.id);
    String? error;
    if (patient.data == null) {
      error = 'Ficha do paciente não encontrada.';
    } else {
      final today = DateTime.now();
      final created = await repo.createPatientRecord(
        patientId: patient.data!,
        type: PatientRecordType.note,
        title:
            'Anotação de ${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}',
        description: text,
        isShared: false,
      );
      if (!created.success) error = 'Não foi possível salvar a anotação.';
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      AppSnackbar.to.show(error);
      return;
    }
    _note.clear();
    AppSnackbar.to.show('Anotação salva. Só você vê.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final next = p.next;
    final last = p.last;
    final since = DateFormat("MMM 'de' y", 'pt_BR').format(p.since.toLocal());

    Widget stat(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PabColors.card,
          border: Border.all(color: PabColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: PabColors.accentText,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: PabColors.muted),
            ),
          ],
        ),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: PabColors.ink,
              child: Text(
                _initials(p.name),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                  Text(
                    'Paciente desde $since',
                    style: const TextStyle(
                      fontSize: 13,
                      color: PabColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'WhatsApp',
              onPressed: () => _openWhatsApp(p),
              icon: const WhatsAppIcon(size: 24, color: WhatsAppIcon.green),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            stat('${p.sessions}', 'sessões'),
            const SizedBox(width: 8),
            stat(next == null ? '—' : _shortDate(next.startAt), 'próxima'),
            const SizedBox(width: 8),
            stat(last == null ? '—' : _shortDate(last.startAt), 'última'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: next == null
                    ? null
                    : () => ProfessionalRoomPage.open(next),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: PabColors.accent,
                  foregroundColor: PabColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: const Text(
                  'Abrir sala',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  if (!widget.embedded) Get.back<void>();
                  ProfessionalDashboardPage.goToTab(2);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: PabColors.ink,
                  side: const BorderSide(color: PabColors.lineStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Ver histórico',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(
              child: Text(
                'Anotações de sessão',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: PabColors.ink,
                ),
              ),
            ),
            Text(
              'só você vê',
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
          minLines: 3,
          maxLines: 8,
          style: const TextStyle(fontSize: 14, color: PabColors.ink),
          decoration: InputDecoration(
            hintText: 'Nova anotação',
            hintStyle: const TextStyle(color: PabColors.muted),
            filled: true,
            fillColor: PabColors.card,
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
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: PabColors.ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _saving ? 'Salvando…' : 'Salvar anotação',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: PabColors.accent),
            ),
          )
        else if (_notes.isEmpty)
          const Text(
            'Nenhuma anotação ainda.',
            style: TextStyle(fontSize: 13, color: PabColors.muted),
          ),
        for (final n in _notes)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PabColors.card,
              border: Border.all(color: PabColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('dd/MM/yyyy').format(n.createdAt.toLocal())}'
                  '${n.isShared ? ' · compartilhada com o paciente' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PabColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  n.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: PabColors.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (widget.embedded) {
      return ListView(children: [content]);
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Get.back<void>(),
              style: TextButton.styleFrom(foregroundColor: PabColors.ink),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(
                'Pacientes',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
}
