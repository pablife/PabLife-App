import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../infra/services/notification_service.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/wide_layout.dart';
import '../../widgets/pab_logo.dart';
import '../dashboard/dashboard_controller.dart';
import '../notifications/notifications_page.dart';
import 'appointment_outcome.dart';
import 'professional_area_controller.dart';
import 'professional_room_page.dart';

/// Dashboard do profissional (canvas PD): próxima consulta com "Entrar na
/// sala", números da semana, consultas de hoje com o registro rápido e as
/// pendências.
class ProfessionalDashboardPage extends StatelessWidget {
  const ProfessionalDashboardPage({super.key});

  static void goToTab(int index) {
    if (Get.isRegistered<DashboardController>()) {
      DashboardController.to.changeTab(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ProfessionalAreaController.to;
    return GetBuilder<ProfessionalAreaController>(
      builder: (c) {
        final wide = isWideLayout(context);
        return Scaffold(
          backgroundColor: PabColors.background,
          body: RefreshIndicator(
            color: PabColors.accent,
            onRefresh: controller.load,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Header(controller: c, wide: wide),
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: wide ? 920 : double.infinity,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: c.loading
                            ? const _Card(
                                child: SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: PabColors.accent,
                                    ),
                                  ),
                                ),
                              )
                            : _Body(controller: c, wide: wide),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ProfessionalAreaController controller;
  final bool wide;

  const _Header({required this.controller, required this.wide});

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Bom dia,'
        : h < 18
        ? 'Boa tarde,'
        : 'Boa noite,';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PabColors.ink,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 20,
        16,
        56,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 920 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!wide)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: PabLogo(size: 22),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: PabColors.onInkSoft,
                          ),
                        ),
                        Text(
                          controller.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: PabColors.onInk,
                          ),
                        ),
                        Text(
                          controller.roleLine,
                          style: const TextStyle(
                            fontSize: 12,
                            color: PabColors.onInkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Bell(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationService>()) return const SizedBox();
    final service = Get.find<NotificationService>();
    return GetBuilder<NotificationService>(
      id: 'notification_count',
      builder: (_) {
        final count = service.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: PabColors.onInk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Get.toNamed(NotificationsPage.route),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.notifications_none,
                    size: 20,
                    color: PabColors.onInk,
                  ),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -5,
                right: -5,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PabColors.pink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final ProfessionalAreaController controller;
  final bool wide;

  const _Body({required this.controller, required this.wide});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final left = [
      _NextCard(controller: c),
      const SizedBox(height: 12),
      _Stats(controller: c),
    ];
    final right = [
      _TodayCard(controller: c),
      const SizedBox(height: 12),
      _PendingCard(controller: c),
    ];
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...left, const SizedBox(height: 12), ...right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: left,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: right,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F052F33),
            blurRadius: 40,
            offset: Offset(0, 18),
            spreadRadius: -28,
          ),
        ],
      ),
      child: child,
    );
  }
}

String hhmm(DateTime d) {
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

String firstNameAndInitial(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return name.trim();
  return '${parts.first} ${parts.last[0]}.';
}

class _NextCard extends StatelessWidget {
  final ProfessionalAreaController controller;

  const _NextCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final next = controller.next;
    if (next == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nenhuma consulta marcada',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Quando um paciente agendar, a próxima consulta aparece aqui.',
              style: TextStyle(fontSize: 13, color: PabColors.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ProfessionalDashboardPage.goToTab(1),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                foregroundColor: PabColors.ink,
                side: const BorderSide(color: PabColors.lineStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Abrir agenda',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final start = next.startAt.toLocal();
    final minutes = start.difference(now).inMinutes;
    final isToday =
        start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final when = minutes <= 0
        ? 'AGORA'
        : minutes < 60
        ? 'EM $minutes MIN'
        : isToday
        ? 'HOJE'
        : '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}';
    final duration = next.endOfScheduledWindow
        .difference(next.startOfScheduledWindow)
        .inMinutes;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: PabColors.ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hhmm(start),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isToday ? 'hoje' : 'dia ${start.day}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: PabColors.onInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRÓXIMA · $when',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: PabColors.accentText,
                      ),
                    ),
                    Text(
                      firstNameAndInitial(next.patientName),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                    Text(
                      '${duration > 0 ? duration : 50} min · '
                      '${controller.sessionNumber(next)}ª sessão',
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
          FilledButton.icon(
            onPressed: () => ProfessionalRoomPage.open(next),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: PabColors.accent,
              foregroundColor: PabColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.videocam_rounded, size: 20),
            label: const Text(
              'Entrar na sala',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final ProfessionalAreaController controller;

  const _Stats({required this.controller});

  @override
  Widget build(BuildContext context) {
    Widget box(
      String value,
      String label, {
      bool dark = false,
      VoidCallback? onTap,
    }) {
      return Expanded(
        child: Material(
          color: dark ? PabColors.ink : PabColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: dark
                ? BorderSide.none
                : const BorderSide(color: PabColors.line),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: dark ? PabColors.onInk : PabColors.accentText,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dark ? PabColors.onInkSoft : PabColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        box('${controller.weekCount}', 'na semana'),
        const SizedBox(width: 8),
        box(
          '${controller.freeToday}',
          'livres hoje',
          onTap: () => ProfessionalDashboardPage.goToTab(1),
        ),
        const SizedBox(width: 8),
        box(
          '${controller.completedCount}',
          'no histórico',
          dark: true,
          onTap: () => ProfessionalDashboardPage.goToTab(2),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  final ProfessionalAreaController controller;

  const _TodayCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final today = controller.today;
    return _Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hoje',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ProfessionalDashboardPage.goToTab(1),
                style: TextButton.styleFrom(
                  foregroundColor: PabColors.accentText,
                ),
                child: const Text(
                  'Abrir agenda',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (today.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Nenhuma consulta hoje.',
                style: TextStyle(fontSize: 13, color: PabColors.muted),
              ),
            ),
          for (final a in today)
            AppointmentRow(appointment: a, controller: controller),
        ],
      ),
    );
  }
}

/// Linha de uma consulta: horário, paciente, sessão e o selo ou os botões
/// de registro (✓ Concluída, Faltou e ⋯ para os outros motivos).
class AppointmentRow extends StatefulWidget {
  final ProfessionalAppointmentModel appointment;
  final ProfessionalAreaController controller;
  final bool showDate;

  const AppointmentRow({
    super.key,
    required this.appointment,
    required this.controller,
    this.showDate = false,
  });

  @override
  State<AppointmentRow> createState() => _AppointmentRowState();
}

class _AppointmentRowState extends State<AppointmentRow> {
  bool _more = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final c = widget.controller;
    final now = DateTime.now();
    final outcome = AppointmentOutcome.of(a);
    final pending =
        outcome == null &&
        a.status == AppointmentStatus.scheduled &&
        a.startAt.isBefore(now);
    final isNext = c.next?.id == a.id && !pending;
    final busy = c.registering == a.id;
    final start = a.startAt.toLocal();
    final date = widget.showDate
        ? '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} · '
        : '';

    Widget pill(
      String label,
      VoidCallback onTap, {
      bool dark = false,
      bool danger = false,
      IconData? icon,
    }) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: OutlinedButton(
          onPressed: busy ? null : onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            backgroundColor: dark ? PabColors.ink : PabColors.card,
            foregroundColor: dark
                ? Colors.white
                : danger
                ? PabColors.error
                : PabColors.ink,
            side: BorderSide(
              color: dark
                  ? PabColors.ink
                  : danger
                  ? PabColors.errorLine
                  : PabColors.line,
            ),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    void reg(AppointmentOutcome o) => c.register(context, a, o);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: isNext
              ? PabColors.soft
              : pending
              ? const Color(0xFFFFFAEF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => ProfessionalRoomPage.open(a),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: widget.showDate ? 92 : 46,
                    child: Text(
                      '$date${hhmm(start)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstNameAndInitial(a.patientName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PabColors.ink,
                          ),
                        ),
                        Text(
                          pending
                              ? 'Registre como foi'
                              : '${c.sessionNumber(a)}ª sessão',
                          style: const TextStyle(
                            fontSize: 12,
                            color: PabColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PabColors.accent,
                      ),
                    )
                  else if (pending) ...[
                    pill(
                      'Concluída',
                      () => reg(AppointmentOutcome.completed),
                      dark: true,
                      icon: Icons.check_rounded,
                    ),
                    pill(
                      'Faltou',
                      () => reg(AppointmentOutcome.noShow),
                      danger: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Tooltip(
                        message: 'Outros motivos',
                        child: OutlinedButton(
                          onPressed: () => setState(() => _more = !_more),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                            foregroundColor: PabColors.ink,
                            side: const BorderSide(color: PabColors.line),
                            shape: const StadiumBorder(),
                          ),
                          child: const Icon(Icons.more_horiz_rounded, size: 18),
                        ),
                      ),
                    ),
                  ] else if (outcome != null)
                    OutcomeTag.of(outcome)
                  else
                    OutcomeTag(
                      label: isNext ? _nextLabel(a) : 'Confirmada',
                      background: isNext ? PabColors.accent : PabColors.soft,
                      foreground: isNext ? PabColors.ink : PabColors.softText,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (pending && _more)
          Padding(
            padding: EdgeInsets.fromLTRB(widget.showDate ? 100 : 54, 0, 4, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final o in const [
                  AppointmentOutcome.cancelledPatient,
                  AppointmentOutcome.cancelledProfessional,
                  AppointmentOutcome.technicalIssue,
                ])
                  OutlinedButton(
                    onPressed: busy ? null : () => reg(o),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: PabColors.ink,
                      side: const BorderSide(color: PabColors.line),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      o.action,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _nextLabel(ProfessionalAppointmentModel a) {
    final minutes = a.startAt.difference(DateTime.now()).inMinutes;
    if (minutes <= 0) return 'Agora';
    if (minutes < 60) return 'Em $minutes min';
    return 'Próxima';
  }
}

class _PendingCard extends StatelessWidget {
  final ProfessionalAreaController controller;

  const _PendingCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final now = DateTime.now();
    final older = c.toRegister
        .where(
          (a) =>
              !(a.startAt.toLocal().year == now.year &&
                  a.startAt.toLocal().month == now.month &&
                  a.startAt.toLocal().day == now.day),
        )
        .toList();
    final todayPending = c.toRegister.length - older.length;

    final items = <(IconData, String, Color, Color, VoidCallback?)>[
      if (todayPending > 0)
        (
          Icons.fact_check_outlined,
          todayPending == 1
              ? '1 consulta de hoje para registrar'
              : '$todayPending consultas de hoje para registrar',
          const Color(0xFFFFF1D6),
          const Color(0xFF6B4A00),
          null,
        ),
      if (older.isNotEmpty)
        (
          Icons.history_rounded,
          older.length == 1
              ? '1 consulta de dias anteriores para registrar'
              : '${older.length} consultas de dias anteriores para registrar',
          const Color(0xFFFFF1D6),
          const Color(0xFF6B4A00),
          () => _showOlder(context, older),
        ),
      if ((c.meetingUrl ?? '').isEmpty)
        (
          Icons.link_rounded,
          'Cadastre o link da sua sala de vídeo',
          PabColors.lilac,
          PabColors.lilacText,
          () => c.next == null
              ? ProfessionalDashboardPage.goToTab(4)
              : ProfessionalRoomPage.open(c.next!),
        ),
    ];

    return _Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pendências',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'Tudo em dia.',
              style: TextStyle(fontSize: 14, color: PabColors.muted),
            ),
          for (final (icon, text, bg, fg, onTap) in items)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 17, color: fg),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PabColors.ink,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: PabColors.muted,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOlder(
    BuildContext context,
    List<ProfessionalAppointmentModel> list,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PabColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => GetBuilder<ProfessionalAreaController>(
        builder: (c) {
          final pending = c.toRegister
              .where((a) => list.any((b) => b.id == a.id))
              .toList();
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.8,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  const Text(
                    'Consultas para registrar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Registre como foi cada uma. O saldo do paciente depende '
                    'do registro.',
                    style: TextStyle(fontSize: 13, color: PabColors.muted),
                  ),
                  const SizedBox(height: 10),
                  if (pending.isEmpty)
                    const Text(
                      'Tudo registrado.',
                      style: TextStyle(fontSize: 14, color: PabColors.muted),
                    ),
                  for (final a in pending)
                    AppointmentRow(
                      appointment: a,
                      controller: c,
                      showDate: true,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
