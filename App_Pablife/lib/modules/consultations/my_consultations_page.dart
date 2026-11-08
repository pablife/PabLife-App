import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../infra/repositories/appointment_repository.dart';
import '../../infra/repositories/consultation_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../infra/services/subscription_service.dart';
import '../../shared/themes/pab_colors.dart';
import '../auth/pages/widgets/registration_layout.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_page.dart';
import 'consultation_detail_page.dart';
import 'consultation_info.dart';
import 'rate_consultation_page.dart';

/// "Minhas consultas" (canvas Q1): saldo, Próximas e Anteriores. Tocar numa
/// próxima abre "Sua consulta"; nas anteriores dá para avaliar ou agendar
/// retorno.
class MyConsultationsPage extends StatefulWidget {
  const MyConsultationsPage({super.key});

  static const route = '/consultas';

  @override
  State<MyConsultationsPage> createState() => _MyConsultationsPageState();
}

class _MyConsultationsPageState extends State<MyConsultationsPage> {
  bool _loading = true;
  bool _showPast = false;
  List<ProfessionalAppointmentModel> _next = [];
  List<ProfessionalAppointmentModel> _past = [];
  Set<String> _rated = {};
  int _balance = 0;
  DateTime? _expires;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;
    final repo = AppointmentRepository();
    final now = DateTime.now();
    final results = await Future.wait([
      repo.getPatientActiveAppointments(patientId: uid),
      repo.getPatientAppointments(
        patientId: uid,
        startAt: now.subtract(const Duration(days: 365)),
        endAt: now,
      ),
      ConsultationRepository().ratedAppointmentIds(),
      SubscriptionService.instance.getConsultationBalances(),
    ]);
    if (!mounted) return;

    final active =
        (results[0] as dynamic).data as List<ProfessionalAppointmentModel>? ??
        const [];
    final history =
        (results[1] as dynamic).data as List<ProfessionalAppointmentModel>? ??
        const [];
    final balances = results[3] as List<ConsultationBalance>;
    final open = balances.where((b) => b.remaining > 0).toList()
      ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));

    setState(() {
      _next =
          active
              .where(
                (a) =>
                    a.status == AppointmentStatus.scheduled &&
                    a.localEnd.isAfter(now),
              )
              .toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
      _past =
          history
              .where(
                (a) =>
                    a.status != AppointmentStatus.scheduled ||
                    a.localEnd.isBefore(now),
              )
              .toList()
            ..sort((a, b) => b.startAt.compareTo(a.startAt));
      _rated = results[2] as Set<String>;
      _balance = open.fold(0, (sum, b) => sum + b.remaining);
      _expires = open.isEmpty ? null : open.first.expiresAt;
      _loading = false;
    });
  }

  void _goTo(int tab) {
    Get.offAllNamed(DashboardPage.route);
    if (Get.isRegistered<DashboardController>()) {
      DashboardController.to.changeTab(tab);
    }
  }

  Future<void> _openNext(ProfessionalAppointmentModel a) async {
    final changed = await ConsultationDetailPage.open(a);
    if (changed) _load();
  }

  Future<void> _rate(ProfessionalAppointmentModel a) async {
    final sent = await RateConsultationPage.open(a);
    if (sent) setState(() => _rated = {..._rated, a.id});
  }

  @override
  Widget build(BuildContext context) {
    final list = _showPast ? _past : _next;
    return RegistrationLayout(
      title: 'Minhas consultas',
      onBack: () => Get.back<void>(),
      fields: [
        // Saldo e "Agendar".
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: PabColors.ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Text(
                '$_balance',
                style: const TextStyle(
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: PabColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _balance == 1
                          ? 'consulta no saldo'
                          : 'consultas no saldo',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: PabColors.onInk,
                      ),
                    ),
                    if (_expires != null)
                      Text(
                        'Válidas até ${DateFormat('dd/MM/yyyy').format(_expires!.toLocal())}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PabColors.navIdle,
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => _goTo(3),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  backgroundColor: PabColors.accent,
                  foregroundColor: PabColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Agendar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        // Próximas / Anteriores.
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: PabColors.card,
            border: Border.all(color: PabColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              for (final (past, label) in const [
                (false, 'Próximas'),
                (true, 'Anteriores'),
              ])
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: _showPast == past,
                    child: Material(
                      color: _showPast == past
                          ? PabColors.ink
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      child: InkWell(
                        onTap: () => setState(() => _showPast = past),
                        borderRadius: BorderRadius.circular(11),
                        child: SizedBox(
                          height: 44,
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _showPast == past
                                    ? Colors.white
                                    : PabColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: PabColors.accentText),
            ),
          )
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              _showPast
                  ? 'Suas consultas realizadas aparecem aqui.'
                  : 'Nenhuma consulta marcada. Toque em Agendar para escolher '
                        'um horário.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: PabColors.muted),
            ),
          )
        else ...[
          for (final a in list)
            _showPast
                ? _PastCard(
                    appointment: a,
                    rated: _rated.contains(a.id),
                    onRate: () => _rate(a),
                    onBookAgain: () => _goTo(3),
                  )
                : _NextCard(appointment: a, onTap: () => _openNext(a)),
          if (!_showPast)
            const Text(
              'Toque na consulta para entrar na sala, remarcar ou cancelar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: PabColors.muted),
            ),
        ],
      ],
      footer: const [],
    );
  }
}

class _NextCard extends StatelessWidget {
  final ProfessionalAppointmentModel appointment;
  final VoidCallback onTap;

  const _NextCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Material(
      color: PabColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PabColors.accent, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfessionalAvatarCircle(appointment: a, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.professionalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PabColors.ink,
                          ),
                        ),
                        Text(
                          '${a.professionalRole} · Online',
                          style: const TextStyle(
                            fontSize: 13,
                            color: PabColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: PabColors.muted),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(a.shortWhen, PabColors.soft, PabColors.softText),
                  _Tag(a.statusLabel, PabColors.background, PabColors.ink),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastCard extends StatelessWidget {
  final ProfessionalAppointmentModel appointment;
  final bool rated;
  final VoidCallback onRate;
  final VoidCallback onBookAgain;

  const _PastCard({
    required this.appointment,
    required this.rated,
    required this.onRate,
    required this.onBookAgain,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final canRate =
        !rated &&
        a.status != AppointmentStatus.cancelled &&
        a.status != AppointmentStatus.noShow;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProfessionalAvatarCircle(appointment: a, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.professionalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PabColors.ink,
                      ),
                    ),
                    Text(
                      '${a.shortWhen} · ${a.statusLabel}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: PabColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (canRate) ...[
                Expanded(
                  child: FilledButton(
                    onPressed: onRate,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      backgroundColor: PabColors.accent,
                      foregroundColor: PabColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Avaliar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (rated) ...[
                const Expanded(
                  child: Center(
                    child: Text(
                      'Avaliada ✓',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PabColors.accentText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: onBookAgain,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: PabColors.ink,
                    side: const BorderSide(color: PabColors.lineStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Agendar retorno',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Tag(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
