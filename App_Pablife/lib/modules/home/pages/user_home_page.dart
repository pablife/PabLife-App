import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/services/notification_service.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/wide_layout.dart';
import '../../../widgets/banners/banner_carousel_widget.dart';
import '../../../widgets/pab_logo.dart';
import '../../../widgets/pabi/pabi.dart';
import '../../calendar/calendar_controller.dart';
import '../../dashboard/dashboard_controller.dart';
import '../../notifications/notifications_page.dart';
import '../../profile/pages/subscription_page.dart';
import '../../women_health/pages/mood_check_in_page.dart';
import '../../women_health/women_health_controller.dart';
import '../../women_health/women_health_data.dart';
import '../../../infra/repositories/daily_verse_repository.dart';
import '../../consultations/my_consultations_page.dart';
import '../controllers/user_home_controller.dart';
import '../../women_health/diary/women_diary_card.dart';
import '../../women_health/pages/cycle_tools_pages.dart';
import '../../women_health/pregnancy/pregnancy_dashboard_card.dart';

const _months = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];
const _weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

String _two(int value) => value.toString().padLeft(2, '0');

String _dayMonth(DateTime date) => '${date.day} ${_months[date.month - 1]}';

String _greeting(DateTime now) => now.hour < 12
    ? 'Bom dia'
    : now.hour < 18
    ? 'Boa tarde'
    : 'Boa noite';

void _goToTab(int index) {
  if (Get.isRegistered<DashboardController>()) {
    DashboardController.to.changeTab(index);
  }
}

WomenHealthController? get _women =>
    Get.isRegistered<WomenHealthController>() ? WomenHealthController.to : null;

/// Dashboard do usuário (spec: Dashboard, M-Dashboard e Fem-M-Dashboard).
class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  static const route = '/home/user';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PabColors.background,
      body: GetBuilder<UserHomeController>(
        builder: (controller) {
          final women = _women;
          if (women == null) return _HomeBody(controller: controller);
          return GetBuilder<WomenHealthController>(
            builder: (_) => _HomeBody(controller: controller, women: women),
          );
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final UserHomeController controller;
  final WomenHealthController? women;

  const _HomeBody({required this.controller, this.women});

  bool get _womenMode => women?.isActive ?? false;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final c = controller;
    final gap = SizedBox(height: wide ? 16 : 12);

    final appointment = _AppointmentCard(controller: c, compact: _womenMode);
    final balance = _BalanceCard(controller: c);
    final goals = _GoalsCard(controller: c);
    final tasks = _TasksCard(controller: c);
    final cycle = !_womenMode
        ? null
        : women!.trail == WomenTrail.pregnancy
        ? PregnancyDashboardCards(women: women!)
        : _CycleCard(women: women!);
    final diary = _womenMode ? WomenDiaryCard(women: women!) : null;
    final verse = c.showDailyVerse ? c.dailyVerse : null;
    final verseCard = verse == null ? null : _VerseCard(verse: verse);

    final List<Widget> content;
    if (wide) {
      content = [
        if (verseCard != null) ...[verseCard, gap],
        if (cycle != null) ...[cycle, gap],
        if (diary != null) ...[diary, gap],
        _Grid(
          minItemWidth: 260,
          children: [
            appointment,
            if (!_womenMode) balance,
            goals,
            if (_womenMode) tasks,
          ],
        ),
        // Os cartões empurram o botão para baixo: precisam de altura definida.
        if (!_womenMode) ...[gap, IntrinsicHeight(child: tasks)],
        if (_womenMode) ...[gap, const _ProfessionalsShortcut()],
      ];
    } else {
      content = [
        if (verseCard != null) ...[verseCard, gap],
        if (cycle != null) ...[cycle, gap],
        if (diary != null) ...[diary, gap],
        appointment,
        if (!_womenMode) ...[gap, balance],
        gap,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: goals),
              const SizedBox(width: 12),
              Expanded(child: tasks),
            ],
          ),
        ),
        if (_womenMode) ...[gap, const _ProfessionalsShortcut()],
      ];
    }

    return RefreshIndicator(
      color: PabColors.accentText,
      onRefresh: c.refreshData,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(controller: c, women: _womenMode ? women : null, wide: wide),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Align(
              alignment: wide ? Alignment.topLeft : Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...content,
                      if (c.banners.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Parceiros Pablife',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        BannerCarouselWidget(
                          banners: c.banners,
                          padding: EdgeInsets.zero,
                          bannersPerView: wide ? 2 : null,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grade que quebra em colunas de pelo menos [minItemWidth].
class _Grid extends StatelessWidget {
  final double minItemWidth;
  final List<Widget> children;

  const _Grid({required this.minItemWidth, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const spacing = 16.0;
        final columns =
            ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                .floor()
                .clamp(1, children.length);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          final row = children.sublist(
            i,
            (i + columns).clamp(0, children.length),
          );
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < row.length; j++) ...[
                    if (j > 0) const SizedBox(width: spacing),
                    SizedBox(width: width, child: row[j]),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: spacing),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------ topo

class _Header extends StatelessWidget {
  final UserHomeController controller;
  final WomenHealthController? women;
  final bool wide;

  const _Header({required this.controller, this.women, required this.wide});

  @override
  Widget build(BuildContext context) {
    final name = controller.user?.fullName.trim() ?? '';
    // "Como prefere ser chamado(a)" (Editar perfil), senão o primeiro nome.
    final preferred = controller.user?.preferredName?.trim() ?? '';
    final firstName = preferred.isNotEmpty
        ? preferred
        : name.split(RegExp(r'\s+')).first;
    final greeting = _greeting(DateTime.now());
    final w = women;

    return Container(
      color: PabColors.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? 32 : 16,
            wide ? 28 : 18,
            wide ? 32 : 16,
            52,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // No computador o logo fica no menu lateral.
              if (!wide)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: PabLogo(size: 22),
                ),
              Row(
                children: [
                  if (w != null) ...[
                    Semantics(
                      button: true,
                      label: 'Registrar como estou hoje',
                      excludeSemantics: true,
                      child: Material(
                        color: PabColors.onInk.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => showMoodSheet(context, w),
                          child: Pabi(
                            mood: PabiMood.fromCheckIn(w.todayCheckIn),
                            women: true,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w != null ? 'SAÚDE DA MULHER' : '$greeting,',
                          style: TextStyle(
                            fontSize: w != null ? 12 : 14,
                            letterSpacing: w != null ? 0.5 : 0,
                            fontWeight: w != null
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: PabColors.onInkSoft,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          w != null
                              ? '$greeting${firstName.isEmpty ? '' : ', $firstName'}'
                              : (name.isEmpty ? 'Olá!' : name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: wide ? 28 : 22,
                            fontWeight: FontWeight.w800,
                            color: PabColors.onInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const PabNotificationBell(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sino das notificações com o selo rosa de não lidas.
class PabNotificationBell extends StatelessWidget {
  const PabNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationService>()) return const _Bell(count: 0);
    return GetBuilder<NotificationService>(
      id: 'notification_count',
      builder: (service) => _Bell(count: service.unreadCount),
    );
  }
}

class _Bell extends StatelessWidget {
  final int count;

  const _Bell({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == 0
        ? 'Notificações'
        : 'Notificações, $count ${count == 1 ? 'nova' : 'novas'}';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Stack(
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
      ),
    );
  }
}

// --------------------------------------------------------------- cartões

class _Card extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;

  const _Card({
    required this.child,
    this.color = PabColors.card,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: color == PabColors.card
            ? Border.all(color: PabColors.line)
            : null,
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  const _IconBox({
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: size / 2, color: foreground),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool dark;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: dark ? PabColors.ink : PabColors.accent,
        foregroundColor: dark ? Colors.white : PabColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: PabColors.ink,
        side: const BorderSide(color: PabColors.lineStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _balanceDetail(UserHomeController c) {
  final expires = c.consultationsExpireAt?.toLocal();
  if (c.remainingConsultations <= 0 || expires == null) {
    return c.remainingConsultations <= 0
        ? 'Assine um plano para agendar'
        : 'Do seu plano ativo';
  }
  final days = DateTime(
    expires.year,
    expires.month,
    expires.day,
  ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
  final when = days <= 0
      ? 'vencem hoje'
      : days == 1
      ? 'vencem amanhã'
      : 'vencem em $days dias';
  return '${when[0].toUpperCase()}${when.substring(1)} · '
      '${_two(expires.day)}/${_two(expires.month)}/${expires.year}';
}

/// Próxima consulta, ou o convite para agendar.
class _AppointmentCard extends StatelessWidget {
  final UserHomeController controller;

  /// Saúde da Mulher: uma linha só, com o saldo junto.
  final bool compact;

  const _AppointmentCard({required this.controller, this.compact = false});

  ProfessionalAppointmentModel? get _next {
    final now = DateTime.now();
    final upcoming =
        controller.activeAppointments
            .where(
              (a) =>
                  a.status == AppointmentStatus.scheduled &&
                  (a.finishAt ?? a.startAt.add(const Duration(hours: 1)))
                      .isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  String _when(ProfessionalAppointmentModel a) {
    final start = a.startAt.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(start);
    final label = day == today
        ? 'Hoje'
        : day == today.add(const Duration(days: 1))
        ? 'Amanhã'
        : '${_weekDays[start.weekday % 7]}, ${_dayMonth(start)}';
    return '$label · ${_two(start.hour)}:${_two(start.minute)}';
  }

  /// Card de consulta abre "Minhas consultas" (e atualiza ao voltar).
  Future<void> _openList() async {
    await Get.toNamed(MyConsultationsPage.route);
    controller.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final next = _next;
    final professional =
        (next?.professionalData?['user'] as Map?)?['full_name']?.toString() ??
        'Profissional';

    if (compact) {
      final count = controller.remainingConsultations;
      return _Card(
        child: Row(
          children: [
            const _IconBox(
              icon: Icons.calendar_month_outlined,
              background: PabColors.soft,
              foreground: PabColors.accentText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    next == null ? 'Nenhuma consulta' : professional,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    next != null
                        ? _when(next)
                        : count > 0
                        ? '$count ${count == 1 ? 'disponível' : 'disponíveis'}'
                              ' · ${_balanceDetail(controller).toLowerCase()}'
                        : _balanceDetail(controller),
                    style: const TextStyle(
                      fontSize: 13,
                      color: PabColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _PrimaryButton(
              label: next == null ? 'Agendar' : 'Ver',
              dark: true,
              onTap: next == null ? () => _goToTab(3) : _openList,
            ),
          ],
        ),
      );
    }

    return _Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: Icons.calendar_month_outlined,
                background: PabColors.soft,
                foreground: PabColors.accentText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next == null
                          ? 'Nenhuma consulta marcada'
                          : 'Próxima consulta',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      next == null
                          ? 'Agende e ela aparece aqui.'
                          : '$professional · ${_when(next)}',
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
          next == null
              ? _PrimaryButton(
                  label: 'Agendar consulta',
                  onTap: () => _goToTab(3),
                )
              : _PrimaryButton(label: 'Ver minhas consultas', onTap: _openList),
        ],
      ),
    );
  }
}

/// "Versículo do dia" (pode ser tirado em Perfil > Ferramentas).
class _VerseCard extends StatelessWidget {
  final DailyVerse verse;

  const _VerseCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    final source = [
      verse.reference,
      if (verse.translation?.trim().isNotEmpty ?? false) verse.translation!,
    ].join(' · ');
    return _Card(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IconBox(
            icon: Icons.auto_stories_outlined,
            background: PabColors.lilac,
            foreground: PabColors.lilacText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VERSÍCULO DO DIA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: PabColors.lilacText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '“${verse.text.trim()}”',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  source,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PabColors.muted,
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

/// Consultas disponíveis no plano.
class _BalanceCard extends StatelessWidget {
  final UserHomeController controller;

  const _BalanceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final count = controller.remainingConsultations;
    return _Card(
      color: PabColors.ink,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 40,
              height: 1,
              fontWeight: FontWeight.w800,
              color: PabColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1 ? 'consulta disponível' : 'consultas disponíveis',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PabColors.onInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _balanceDetail(controller),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PabColors.pink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Get.toNamed(SubscriptionPage.route),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: PabColors.onInk,
              side: BorderSide(color: PabColors.onInk.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Planos',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  final UserHomeController controller;

  const _GoalsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final goals = controller.goalCards;
    final first = goals.isEmpty ? null : goals.first;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: _IconBox(
              icon: Icons.track_changes,
              background: PabColors.lilac,
              foreground: PabColors.lilacText,
              size: 40,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Metas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            first == null
                ? 'Nenhuma meta criada'
                : goals.length == 1
                ? first.title
                : '${first.title} e mais ${goals.length - 1}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: PabColors.muted),
          ),
          if (first?.percentage != null) ...[
            const SizedBox(height: 8),
            _ProgressBar(value: first!.percentage! / 100),
          ],
          const Spacer(),
          const SizedBox(height: 10),
          _SecondaryButton(
            label: first == null ? 'Criar meta' : 'Ver metas',
            onTap: first == null
                ? () => Get.find<CalendarController>().createGoal()
                : () => _goToTab(1),
          ),
        ],
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  final UserHomeController controller;

  const _TasksCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tasks = controller.todayTasks;
    final percent = tasks.isEmpty ? 0 : tasks.first.percentage;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: Icons.task_alt,
                background: PabColors.soft,
                foreground: PabColors.accentText,
                size: 40,
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PabColors.accentText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Tarefas de hoje',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          _ProgressBar(value: percent / 100),
          const Spacer(),
          const SizedBox(height: 10),
          _SecondaryButton(label: 'Abrir agenda', onTap: () => _goToTab(1)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      label: '${(clamped * 100).round()}%',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 8,
          child: LinearProgressIndicator(
            value: clamped,
            backgroundColor: PabColors.track,
            color: PabColors.accent,
          ),
        ),
      ),
    );
  }
}

class _ProfessionalsShortcut extends StatelessWidget {
  const _ProfessionalsShortcut();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PabColors.lilac,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _goToTab(3),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _IconBox(
                icon: Icons.groups_outlined,
                background: Colors.white,
                foreground: PabColors.lilacText,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profissionais para você',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1B4D),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Psicólogas e nutricionistas',
                      style: TextStyle(
                        fontSize: 13,
                        color: PabColors.lilacText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Color(0xFF1F1B4D)),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------- saúde da mulher

/// Ciclo do dia, linha do ciclo e próximas datas (ou o resumo da trilha de
/// gestação e menopausa).
class _CycleCard extends StatelessWidget {
  final WomenHealthController women;

  const _CycleCard({required this.women});

  @override
  Widget build(BuildContext context) {
    final w = women;
    final followsCycle =
        (w.trail == WomenTrail.cycle || w.trail == WomenTrail.conceive) &&
        w.lastPeriod != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PabColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (followsCycle) ..._cycle(w) else ..._summary(w),
          const SizedBox(height: 12),
          if (w.todayCheckIn == null)
            _PrimaryButton(
              label: 'Registrar como estou hoje',
              onTap: () => showMoodSheet(context, w),
            )
          else
            _MoodDone(
              mood: w.todayCheckIn!,
              onTap: () => showMoodSheet(context, w),
            ),
          if (w.trail != null && w.trail != WomenTrail.pregnancy) ...[
            const SizedBox(height: 10),
            CycleToolsRow(women: w),
          ],
          if (followsCycle) ...[
            const SizedBox(height: 10),
            const Text(
              'Previsões são estimativas e podem variar. Não substituem a '
              'ginecologista.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: PabColors.softText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _summary(WomenHealthController w) => [
    Text(
      w.heroTitle,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: PabColors.ink,
      ),
    ),
    const SizedBox(height: 6),
    Text(
      '${w.ringValue} ${w.ringUnit}',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: PabColors.accentText,
      ),
    ),
    const SizedBox(height: 6),
    Text(
      w.heroSubtitle,
      style: const TextStyle(fontSize: 13, height: 1.5, color: PabColors.muted),
    ),
  ];

  List<Widget> _cycle(WomenHealthController w) {
    final today = DateUtils.dateOnly(DateTime.now());
    final length = w.cycleLength.clamp(15, 45);
    final day = w.cycleDay(today);
    final ovulation = length - 14;
    final phase = w.cyclePhaseOn(today);
    final phaseLabel = switch (phase?.kind) {
      WomenCycleKind.menstruation => 'Menstruação',
      WomenCycleKind.fertile =>
        phase!.label.contains('ovulação') ? 'Ovulação' : 'Período fértil',
      _ => phase?.label.replaceAll(' (estimativa)', '') ?? '',
    };
    final phaseColor = switch (phase?.kind) {
      WomenCycleKind.menstruation => PabColors.menstruation,
      WomenCycleKind.fertile => PabColors.fertile,
      _ => const Color(0xFFAE9FB3),
    };

    final cycleStart = today.subtract(Duration(days: day - 1));
    var fertileStart = cycleStart.add(Duration(days: ovulation - 6));
    var fertileEnd = cycleStart.add(Duration(days: ovulation));
    if (fertileEnd.isBefore(today)) {
      fertileStart = fertileStart.add(Duration(days: length));
      fertileEnd = fertileEnd.add(Duration(days: length));
    }

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Dia $day',
            style: const TextStyle(
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w800,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'do ciclo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PabColors.muted,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: PabColors.soft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: phaseColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  phaseLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PabColors.softText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Semantics(
        label: 'Linha do ciclo de $length dias, hoje é o dia $day',
        excludeSemantics: true,
        child: SizedBox(
          height: 26,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var d = 1; d <= length; d++) ...[
                if (d > 1) const SizedBox(width: 2),
                Expanded(
                  child: Container(
                    height: d == day
                        ? 24
                        : d == ovulation
                        ? 18
                        : 12,
                    decoration: BoxDecoration(
                      color: d <= 5
                          ? PabColors.menstruation
                          : d >= ovulation - 5 && d <= ovulation + 1
                          ? PabColors.fertile
                          : PabColors.track,
                      borderRadius: BorderRadius.circular(3),
                      border: d == day
                          ? Border.all(color: PabColors.ink, width: 2)
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _InfoRow(
        label: 'Próxima menstruação',
        value: '${_dayMonth(w.nextPeriod)} · prevista',
      ),
      const SizedBox(height: 6),
      _InfoRow(
        label: 'Período fértil',
        value: fertileStart.month == fertileEnd.month
            ? '${fertileStart.day} a ${_dayMonth(fertileEnd)} · previsto'
            : '${_dayMonth(fertileStart)} a ${_dayMonth(fertileEnd)} · previsto',
      ),
    ];
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: PabColors.muted),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: PabColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Humor de hoje já registrado: mostra o registro em vez de pedir de novo.
class _MoodDone extends StatelessWidget {
  final String mood;
  final VoidCallback onTap;

  const _MoodDone({required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PabColors.soft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            child: Row(
              children: [
                Pabi(mood: PabiMood.fromCheckIn(mood), women: true, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registro de hoje feito',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PabColors.softText,
                        ),
                      ),
                      Text(
                        mood,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: PabColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: PabColors.accentText,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Ver',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: PabColors.accentText,
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

/// "Como estou hoje": a pessoa escolhe o humor do dia.
/// Abre "Como estou hoje" (tela inteira, como no canvas).
Future<void> showMoodSheet(BuildContext context, WomenHealthController w) =>
    MoodCheckInPage.open();
