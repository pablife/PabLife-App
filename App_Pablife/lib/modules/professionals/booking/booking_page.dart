import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/professional_schedule_slot.dart';
import '../../../infra/models/professional_with_user_model.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/utils/wide_layout.dart';
import '../../calendar/widgets/calendar_connect_dialog.dart';
import '../../dashboard/dashboard_controller.dart';
import '../../dashboard/dashboard_page.dart';
import '../../women_health/women_health_data.dart';
import '../professionals_controller.dart';
import 'booking_controller.dart';

/// Cores do agendamento: a segunda é a do modo Saúde da mulher.
abstract final class _Colors {
  static const background = AppColor.pair(0xFFF4F7F7, 0xFFFBF6FA);
  static const ink = AppColor.pair(0xFF052F33, 0xFF3A1D4F);
  static const onInk = Color(0xFFFBFAFC);
  static const brand = AppColor.pair(0xFF9DE3E0, 0xFFFFC2E6);
  static const line = AppColor.pair(0xFFDCE7E6, 0xFFEEDDE9);
  static const lineStrong = AppColor.pair(0xFFCFE3E2, 0xFFE9A6CF);
  static const rowLine = AppColor.pair(0xFFEDF2F2, 0xFFF3E8EF);
  static const muted = AppColor.pair(0xFF4A5E60, 0xFF5E4A66);
  static const accent = AppColor.pair(0xFF13B8B2, 0xFFFF8ECF);
  static const accentDark = AppColor.pair(0xFF0E7C78, 0xFFC2417F);
  static const accentText = AppColor.pair(0xFF0E7C78, 0xFFA8336F);
  static const today = AppColor.pair(0xFFFF8ECF, 0xFF8D84F0);
  static const noSlots = AppColor.pair(0xFFE9EEEE, 0xFFEDE4EB);
  static const noSlotsText = AppColor.pair(0xFF6C7C7D, 0xFF76657B);
  static const past = AppColor.pair(0xFFA3AFB0, 0xFFAE9FB3);
  static const noticeBackground = AppColor.pair(0xFFE3F6F5, 0xFFFCE8F3);
  static const noticeText = AppColor.pair(0xFF0B5754, 0xFF7A1F52);
  static const disabledButton = AppColor.pair(0xFFE3E9E9, 0xFFEDE4EB);
  static const violetBackground = Color(0xFFEEEDFF);
  static const violet = Color(0xFF3F3A8C);
  static const violetDark = Color(0xFF1F1B4D);
  static const menstruation = Color(0xFFD63A74);
  static const fertile = Color(0xFF8D84F0);
}

const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];
const _shortMonths = [
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
const _weekDays = [
  'Domingo',
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
];
const _shortWeekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

String _two(int value) => value.toString().padLeft(2, '0');

String _time(DateTime date) => '${_two(date.hour)}:${_two(date.minute)}';

String _shortWeekDay(DateTime date) => _shortWeekDays[date.weekday % 7];

String _longWeekDay(DateTime date) => _weekDays[date.weekday % 7];

String _shortDate(DateTime date) =>
    '${_shortWeekDay(date)}, ${date.day} de ${_shortMonths[date.month - 1]}';

String _longDate(DateTime date) =>
    '${_longWeekDay(date)}, ${date.day} de ${_months[date.month - 1]}';

/// Os horários vêm no fuso do aparelho. Só dizemos "Fortaleza" quando é o
/// mesmo fuso, para não mostrar um horário com o nome errado.
bool get _isFortalezaTime =>
    DateTime.now().timeZoneOffset == const Duration(hours: -3);

String _countLabel(int count) => count == 0
    ? 'Nenhum horário livre'
    : count == 1
    ? '1 horário livre'
    : '$count horários livres';

String _summary(BookingController c, {String empty = 'Escolha um horário'}) {
  final slot = c.selectedSlot;
  if (slot == null) return empty;
  return '${_shortDate(slot.startAt)} às ${_time(slot.startAt)}';
}

String _dayTitle(BookingController c, DateTime day, {bool long = false}) {
  final isToday = day == c.today;
  final date = long ? _longDate(day) : _shortDate(day);
  if (!isToday) {
    return long
        ? date
        : '${_longWeekDay(day)}, ${day.day} de ${_shortMonths[day.month - 1]}';
  }
  final weekDay = _longWeekDay(day).toLowerCase();
  final month = (long ? _months : _shortMonths)[day.month - 1];
  return 'Hoje, $weekDay, ${day.day} de $month';
}

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  static const route = '/book-appointment';

  /// Abre o agendamento. Devolve 'booked' ou 'change', ou null se a pessoa só
  /// voltou. As rotas do app não têm tipo: pedir `toNamed<String>` dá erro.
  static Future<String?> open(ProfessionalWithUserModel professional) async {
    final result = await Get.toNamed(route, arguments: professional);
    return result as String?;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BookingController>(
      builder: (controller) {
        final wide = isWideLayout(context);
        return PopScope(
          canPop: controller.step != BookingStep.confirm,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.backToPick();
          },
          child: Scaffold(
            backgroundColor: _Colors.background,
            body: wide
                ? _WideBooking(controller: controller)
                : _MobileBooking(controller: controller),
          ),
        );
      },
    );
  }
}

void _leave(BookingController c) {
  if (c.step == BookingStep.confirm) {
    c.backToPick();
    return;
  }
  Get.back(result: c.step == BookingStep.done ? 'booked' : null);
}

void _backToDashboard(int tab) {
  Get.until((route) => route.settings.name == DashboardPage.route);
  if (Get.isRegistered<DashboardController>()) {
    DashboardController.to.changeTab(tab);
  }
}

void _openPlanner() => _backToDashboard(1);

void _openMyAppointments() {
  _backToDashboard(3);
  if (Get.isRegistered<ProfessionalsController>()) {
    Get.find<ProfessionalsController>().showScheduledOnly();
  }
}

// ------------------------------------------------------------- computador

class _WideBooking extends StatelessWidget {
  final BookingController controller;

  const _WideBooking({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WideHeader(controller: c),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: switch (c.step) {
                    BookingStep.pick => 1248,
                    BookingStep.confirm => 688,
                    BookingStep.done => 608,
                  },
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                  child: _content(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final c = controller;
    if (c.step == BookingStep.confirm) return _Confirmation(controller: c);
    if (c.step == BookingStep.done) return _Done(controller: c);
    if (c.loading) return const _Loading();
    if (c.loadFailed) return _LoadFailed(controller: c);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfessionalCard(controller: c),
              const SizedBox(height: 16),
              _Card(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MonthHeader(controller: c),
                    if (c.hasCycle) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _CycleToggle(controller: c),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _MonthGrid(controller: c, compact: false),
                    const SizedBox(height: 14),
                    _Legend(controller: c),
                  ],
                ),
              ),
              if (c.hasCycle) ...[
                const SizedBox(height: 16),
                const _CycleNotice(),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 13,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (c.firstSlot != null) ...[
                _FirstSlotBanner(controller: c),
                const SizedBox(height: 16),
              ],
              _Card(
                padding: const EdgeInsets.all(24),
                child: _DaySlots(controller: c, compact: false),
              ),
              const SizedBox(height: 16),
              _WideSummaryBar(controller: c),
            ],
          ),
        ),
      ],
    );
  }
}

class _WideHeader extends StatelessWidget {
  final BookingController controller;

  const _WideHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final current = c.step.index;
    const labels = ['Data e horário', 'Confirmação', 'Pronto'];

    return ColoredBox(
      color: _Colors.ink,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1248),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _BackButton(onTap: () => _leave(c)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.womenMode ? 'PABLIFE · SAÚDE DA MULHER' : 'PABLIFE',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .5,
                            color: _Colors.brand,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Agendar consulta',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _Colors.onInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < labels.length; i++) ...[
                    const SizedBox(width: 20),
                    _StepLabel(
                      number: i + 1,
                      label: labels[i],
                      active: i == current,
                      done: i < current,
                      showLabel:
                          i == current ||
                          MediaQuery.sizeOf(context).width >= 1100,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool done;
  final bool showLabel;

  const _StepLabel({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    final lit = active || done;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? _Colors.accent
                : done
                ? _Colors.accent.withValues(alpha: .28)
                : Colors.transparent,
            border: lit
                ? null
                : Border.all(color: _Colors.brand.withValues(alpha: .5)),
          ),
          child: done
              ? const Icon(Icons.check, size: 15, color: _Colors.onInk)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? _Colors.ink : _Colors.onInk,
                  ),
                ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: lit ? _Colors.onInk : _Colors.brand.withValues(alpha: .7),
            ),
          ),
        ],
      ],
    );
  }
}

class _WideSummaryBar extends StatelessWidget {
  final BookingController controller;

  const _WideSummaryBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final ready = c.selectedSlot != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _Colors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu horário',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _Colors.brand,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _summary(c, empty: 'Escolha um dia e um horário'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _Colors.onInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _Button(
            label: 'Continuar',
            onTap: ready ? c.toConfirm : null,
            minWidth: 140,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- celular

class _MobileBooking extends StatelessWidget {
  final BookingController controller;

  const _MobileBooking({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MobileHeader(controller: c),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: _content(),
          ),
        ),
        if (c.step == BookingStep.pick && !c.loading && !c.loadFailed)
          _MobileSummaryBar(controller: c),
      ],
    );
  }

  Widget _content() {
    final c = controller;
    if (c.step == BookingStep.confirm) return _Confirmation(controller: c);
    if (c.step == BookingStep.done) return _Done(controller: c);
    if (c.loading) return const _Loading();
    if (c.loadFailed) return _LoadFailed(controller: c);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _MonthHeader(controller: c)),
            const SizedBox(width: 8),
            _ModeButton(controller: c),
          ],
        ),
        if (c.hasCycle) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: _CycleToggle(controller: c),
          ),
        ],
        const SizedBox(height: 16),
        if (c.monthOpen)
          _Card(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MonthGrid(controller: c, compact: true),
                const SizedBox(height: 10),
                _Legend(controller: c),
              ],
            ),
          )
        else
          _DayStrip(controller: c),
        const SizedBox(height: 18),
        _DaySlots(controller: c, compact: true),
        if (c.hasCycle) ...[const SizedBox(height: 18), const _CycleNotice()],
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  final BookingController controller;

  const _MobileHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final subtitle = switch (c.step) {
      BookingStep.pick => 'Passo 1 de 2 · Data e horário',
      BookingStep.confirm => 'Passo 2 de 2 · Confirmação',
      BookingStep.done => 'Agendamento concluído',
    };

    return Container(
      decoration: const BoxDecoration(
        color: _Colors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _BackButton(onTap: () => _leave(c)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.step == BookingStep.done
                              ? 'Tudo certo'
                              : 'Agendar consulta',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: _Colors.onInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _Colors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _Colors.onInk.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _Avatar(controller: c, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.professional.user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _Colors.onInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${c.professional.typeFormatted} · Online por vídeo',
                            style: TextStyle(
                              fontSize: 13,
                              color: _Colors.onInk.withValues(alpha: .8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (c.step == BookingStep.pick)
                      TextButton(
                        onPressed: () => Get.back(result: 'change'),
                        style: TextButton.styleFrom(
                          foregroundColor: _Colors.brand,
                        ),
                        child: const Text('Trocar'),
                      ),
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

class _MobileSummaryBar extends StatelessWidget {
  final BookingController controller;

  const _MobileSummaryBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _Colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seu horário',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _Colors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _summary(c),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _Colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Button(
                label: 'Continuar',
                onTap: c.selectedSlot == null ? null : c.toConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final BookingController controller;

  const _ModeButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return OutlinedButton.icon(
      onPressed: c.toggleMonth,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: _Colors.ink,
        backgroundColor: c.monthOpen ? _Colors.noticeBackground : Colors.white,
        side: const BorderSide(color: _Colors.lineStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.calendar_month_outlined, size: 16),
      label: Text(
        c.monthOpen ? 'Semana' : 'Mês',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Dias do mês em uma faixa que desliza para o lado.
class _DayStrip extends StatefulWidget {
  final BookingController controller;

  const _DayStrip({required this.controller});

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  static const _itemExtent = 68.0;
  final _scroll = ScrollController();

  List<DateTime> get _days {
    final c = widget.controller;
    final month = c.viewMonth;
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final firstDay = month == DateTime(c.today.year, c.today.month)
        ? c.today.day
        : 1;
    return [
      for (var day = firstDay; day <= lastDay; day++)
        DateTime(month.year, month.month, day),
    ];
  }

  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final index = _days.indexOf(widget.controller.selectedDay ?? DateTime(0));
      if (index < 0) return;
      _scroll.animateTo(
        (index * _itemExtent - _itemExtent).clamp(
          0.0,
          _scroll.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(covariant _DayStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revealSelected();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final days = _days;
    return SizedBox(
      height: 84,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        itemExtent: _itemExtent,
        itemCount: days.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _DayCell(
            controller: c,
            day: days[index],
            layout: _DayLayout.strip,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- calendário

class _MonthHeader extends StatelessWidget {
  final BookingController controller;

  const _MonthHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final name = _months[c.viewMonth.month - 1];
    final label =
        '${name[0].toUpperCase()}${name.substring(1)} ${c.viewMonth.year}';

    Widget arrow(IconData icon, String tooltip, int delta, bool enabled) {
      return SizedBox(
        width: 44,
        height: 44,
        child: IconButton.outlined(
          tooltip: tooltip,
          onPressed: enabled ? () => c.changeMonth(delta) : null,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _Colors.ink,
            side: const BorderSide(color: _Colors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(icon, size: 20),
        ),
      );
    }

    return Row(
      children: [
        arrow(Icons.chevron_left, 'Mês anterior', -1, c.canGoPrevMonth),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _Colors.ink,
            ),
          ),
        ),
        arrow(Icons.chevron_right, 'Próximo mês', 1, c.canGoNextMonth),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final BookingController controller;
  final bool compact;

  const _MonthGrid({required this.controller, required this.compact});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final month = c.viewMonth;
    final lead = month.weekday % 7;
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final hasBar = c.hasCycle && !compact;
    final height = compact ? 46.0 : (hasBar ? 68.0 : 64.0);
    const titles = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final title in titles)
              Expanded(
                child: Text(
                  compact ? title[0] : title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _Colors.muted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        _SevenColumns(
          count: lead + dayCount,
          height: height,
          spacing: compact ? 4 : 6,
          builder: (index) {
            if (index < lead) return const SizedBox.shrink();
            return _DayCell(
              controller: c,
              day: DateTime(month.year, month.month, index - lead + 1),
              layout: compact ? _DayLayout.compact : _DayLayout.full,
            );
          },
        ),
      ],
    );
  }
}

/// Grade de 7 colunas com altura fixa por linha.
class _SevenColumns extends StatelessWidget {
  final int count;
  final double height;
  final double spacing;
  final Widget Function(int index) builder;

  const _SevenColumns({
    required this.count,
    required this.height,
    required this.spacing,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final rows = (count / 7).ceil();
    return Column(
      children: [
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) SizedBox(height: spacing + 2),
          SizedBox(
            height: height,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++) ...[
                  if (col > 0) SizedBox(width: spacing),
                  Expanded(
                    child: row * 7 + col < count
                        ? builder(row * 7 + col)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

enum _DayLayout { full, compact, strip }

class _DayCell extends StatelessWidget {
  final BookingController controller;
  final DateTime day;
  final _DayLayout layout;

  const _DayCell({
    required this.controller,
    required this.day,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final count = c.slotsOn(day).length;
    final available = count > 0;
    final past = day.isBefore(c.today);
    final selected = day == c.selectedDay;
    final isToday = day == c.today;
    final strip = layout == _DayLayout.strip;

    Color background = Colors.white;
    Color foreground = _Colors.ink;
    Color border = layout == _DayLayout.full
        ? _Colors.accent
        : _Colors.lineStrong;
    var note = '$count ${count == 1 ? 'livre' : 'livres'}';
    Color noteColor = _Colors.accentText;
    Color dot = _Colors.accent;

    if (selected) {
      background = _Colors.ink;
      foreground = Colors.white;
      border = _Colors.ink;
      noteColor = _Colors.brand;
    } else if (past) {
      background = Colors.transparent;
      foreground = _Colors.past;
      border = Colors.transparent;
      note = ' ';
      dot = Colors.transparent;
    } else if (!available) {
      background = _Colors.noSlots;
      foreground = _Colors.noSlotsText;
      border = Colors.transparent;
      note = '—';
      noteColor = _Colors.noSlotsText;
      dot = Colors.transparent;
    }

    if (isToday) {
      note = available ? 'Hoje · $count' : 'Hoje';
      if (!selected) border = _Colors.today;
    }

    final phase = past ? null : c.visibleCyclePhaseOn(day);
    final bar = switch (phase?.kind) {
      WomenCycleKind.menstruation => _Colors.menstruation,
      WomenCycleKind.fertile => _Colors.fertile,
      _ => Colors.transparent,
    };

    final number = Text(
      '${day.day}',
      style: TextStyle(
        fontSize: switch (layout) {
          _DayLayout.full => 18,
          _DayLayout.compact => 15,
          _DayLayout.strip => 22,
        },
        height: 1,
        fontWeight: strip ? FontWeight.w800 : FontWeight.w700,
        color: foreground,
        decoration: past ? TextDecoration.lineThrough : null,
        decorationColor: foreground,
      ),
    );
    Widget mark(Color color) => Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );

    final children = switch (layout) {
      _DayLayout.full => <Widget>[
        if (c.hasCycle)
          FractionallySizedBox(
            widthFactor: .6,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: bar,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        number,
        Text(
          note,
          maxLines: 1,
          style: TextStyle(
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w700,
            color: noteColor,
          ),
        ),
      ],
      _DayLayout.compact => <Widget>[
        number,
        mark(bar == Colors.transparent ? dot : bar),
      ],
      _DayLayout.strip => <Widget>[
        Text(
          isToday ? 'Hoje' : _shortWeekDay(day),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? _Colors.brand : _Colors.muted,
          ),
        ),
        number,
        mark(bar == Colors.transparent ? dot : bar),
      ],
    };

    final description = StringBuffer(
      '${day.day} de ${_months[day.month - 1]}, '
      '${past
          ? 'dia passado'
          : available
          ? _countLabel(count)
          : 'sem horários'}',
    );
    if (phase != null && phase.kind != WomenCycleKind.other) {
      description.write(', ${phase.label.toLowerCase()}');
    }

    return Semantics(
      button: true,
      selected: selected,
      enabled: available,
      label: description.toString(),
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(strip ? 16 : 14),
          side: BorderSide(color: border, width: isToday && !selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: available ? () => c.selectDay(day) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: layout == _DayLayout.compact ? 4 : 5,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final BookingController controller;

  const _Legend({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    Widget item(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: _Colors.muted)),
      ],
    );
    Widget box({Color? fill, Color? border, double width = 1}) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: fill,
        border: border == null ? null : Border.all(color: border, width: width),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    Widget bar(Color color) => Container(
      width: 16,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );

    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _Colors.rowLine)),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          item(box(fill: Colors.white, border: _Colors.accent), 'Com horários'),
          item(box(fill: _Colors.ink), 'Selecionado'),
          item(box(fill: _Colors.noSlots), 'Sem horários'),
          item(box(border: _Colors.today, width: 2), 'Hoje'),
          if (c.hasCycle && c.showCycle) ...[
            item(bar(_Colors.menstruation), 'Menstruação'),
            item(bar(_Colors.fertile), 'Período fértil'),
          ],
        ],
      ),
    );
  }
}

class _CycleToggle extends StatelessWidget {
  final BookingController controller;

  const _CycleToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Semantics(
      toggled: c.showCycle,
      button: true,
      label: 'Mostrar meu ciclo no calendário',
      excludeSemantics: true,
      child: Material(
        color: c.showCycle ? _Colors.noticeBackground : Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: _Colors.lineStrong)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: c.toggleCycle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  c.showCycle ? Icons.toggle_on : Icons.toggle_off_outlined,
                  size: 24,
                  color: _Colors.accentDark,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mostrar meu ciclo no calendário',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Colors.ink,
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

class _CycleNotice extends StatelessWidget {
  const _CycleNotice();

  @override
  Widget build(BuildContext context) {
    return const _Notice(
      icon: Icons.info_outline,
      text:
          'As fases do ciclo são estimativas com base no que você registrou e '
          'podem variar. Não servem como método contraceptivo nem substituem o '
          'acompanhamento com ginecologista.',
    );
  }
}

// --------------------------------------------------------------- horários

class _FirstSlotBanner extends StatelessWidget {
  final BookingController controller;

  const _FirstSlotBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final slot = c.firstSlot!;
    final day = DateTime(
      slot.startAt.year,
      slot.startAt.month,
      slot.startAt.day,
    );
    final date = day == c.today ? 'Hoje' : _shortDate(day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Colors.violetBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bolt_outlined,
              size: 22,
              color: _Colors.violet,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Primeiro horário livre',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _Colors.violet,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$date às ${_time(slot.startAt)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _Colors.violetDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: c.useFirstSlot,
            style: FilledButton.styleFrom(
              backgroundColor: _Colors.violet,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Quero este',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySlots extends StatelessWidget {
  final BookingController controller;
  final bool compact;

  const _DaySlots({required this.controller, required this.compact});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final day = c.selectedDay;

    if (!c.hasAnySlot || day == null) {
      return const _EmptyBox(
        title: 'Sem horários livres no momento',
        text: 'Tente outro profissional ou volte mais tarde.',
      );
    }

    final count = c.selectedDaySlots.length;
    final zone = _isFortalezaTime
        ? (compact ? 'horário de Fortaleza' : 'horário de Fortaleza (GMT-3)')
        : 'no horário do seu aparelho';
    final phase = c.visibleCyclePhaseOn(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _dayTitle(c, day, long: !compact),
          style: TextStyle(
            fontSize: compact ? 19 : 22,
            fontWeight: FontWeight.w700,
            color: _Colors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_countLabel(count)} · $zone',
          style: TextStyle(fontSize: compact ? 13 : 14, color: _Colors.muted),
        ),
        if (phase != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _PhaseChip(phase: phase),
          ),
        ],
        const SizedBox(height: 18),
        if (count == 0)
          _EmptyBox(
            title: 'Este dia não tem horários livres',
            text: 'Que tal o próximo dia disponível?',
            action: 'Ver próximo dia com horários',
            onAction: c.goToNextDayWithSlots,
          )
        else
          for (final period in c.periods) ...[
            _PeriodHeader(period: period, compact: compact),
            const SizedBox(height: 10),
            _SlotGrid(controller: c, slots: period.slots),
            if (period != c.periods.last) const SizedBox(height: 20),
          ],
      ],
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final WomenCyclePhase phase;

  const _PhaseChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, dot) = switch (phase.kind) {
      WomenCycleKind.menstruation => (
        const Color(0xFFFCE8F3),
        const Color(0xFF7A1F52),
        _Colors.menstruation,
      ),
      WomenCycleKind.fertile => (
        _Colors.violetBackground,
        _Colors.violet,
        _Colors.fertile,
      ),
      WomenCycleKind.other => (
        const Color(0xFFF3EEF2),
        const Color(0xFF5E4A66),
        const Color(0xFFAE9FB3),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
          const SizedBox(width: 8),
          Text(
            phase.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  final BookingPeriod period;
  final bool compact;

  const _PeriodHeader({required this.period, required this.compact});

  @override
  Widget build(BuildContext context) {
    final icon = switch (period.startHour) {
      0 => Icons.wb_sunny_outlined,
      12 => Icons.wb_twilight_outlined,
      _ => Icons.nightlight_outlined,
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: _Colors.ink),
        const SizedBox(width: 8),
        Text(
          period.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _Colors.ink,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 8),
          Text(
            period.range,
            style: const TextStyle(fontSize: 13, color: _Colors.muted),
          ),
        ],
      ],
    );
  }
}

class _SlotGrid extends StatelessWidget {
  final BookingController controller;
  final List<ProfessionalScheduleSlot> slots;

  const _SlotGrid({required this.controller, required this.slots});

  @override
  Widget build(BuildContext context) {
    const columns = 4;
    const gap = 8.0;
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final slot in slots)
              SizedBox(
                width: width,
                child: _SlotButton(controller: controller, slot: slot),
              ),
          ],
        );
      },
    );
  }
}

class _SlotButton extends StatelessWidget {
  final BookingController controller;
  final ProfessionalScheduleSlot slot;

  const _SlotButton({required this.controller, required this.slot});

  @override
  Widget build(BuildContext context) {
    final selected = identical(slot, controller.selectedSlot);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? _Colors.accent : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? _Colors.accentDark : _Colors.lineStrong,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => controller.selectSlot(slot),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                _time(slot.startAt),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: _Colors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ confirmação

class _Confirmation extends StatelessWidget {
  final BookingController controller;

  const _Confirmation({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final slot = c.selectedSlot!;
    final phase = c.cyclePhaseOn(slot.startAt);
    final zone = _isFortalezaTime ? ' (Fortaleza, GMT-3)' : '';
    final rows = [
      (
        'Profissional',
        '${c.professional.user.fullName} · ${c.professional.typeFormatted}',
      ),
      ('Data', _longDate(slot.startAt)),
      ('Horário', '${_time(slot.startAt)}$zone'),
      ('Modalidade', 'Online por vídeo'),
      if (phase != null) ('Seu ciclo neste dia', phase.label),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Confira e confirme',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _Colors.ink,
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, (label, value)) in rows.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: index == rows.length - 1
                        ? null
                        : const Border(
                            bottom: BorderSide(color: _Colors.rowLine),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _Colors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _Colors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Notice(
          icon: Icons.notifications_none,
          text:
              'Você vai receber lembretes 3 dias, 1 dia e 1 hora antes da '
              'consulta.${c.womenMode ? ' Se quiser, leve para a sessão o que '
                        'anotou no seu planner.' : ''}',
        ),
        const SizedBox(height: 16),
        _Button(
          label: c.booking ? 'Agendando...' : 'Confirmar agendamento',
          onTap: c.booking ? null : c.confirm,
        ),
        const SizedBox(height: 8),
        _OutlineButton(
          label: 'Alterar data ou horário',
          onTap: c.booking ? null : c.backToPick,
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  final BookingController controller;

  const _Done({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final women = c.womenMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _Colors.accent,
            ),
            child: const Icon(Icons.check, size: 38, color: _Colors.ink),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Consulta agendada!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _Colors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${_summary(c)} com ${c.professional.user.fullName}. '
          '${women ? 'A consulta também aparece no seu planner de Saúde da '
                    'Mulher.' : 'A consulta também aparece no seu planner.'}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: _Colors.muted,
          ),
        ),
        const SizedBox(height: 20),
        if (women)
          _Button(label: 'Ver no meu planner', onTap: _openPlanner)
        else
          _Button(
            label: 'Adicionar à minha agenda',
            onTap: () => CalendarConnectDialog.show(context),
          ),
        const SizedBox(height: 8),
        _OutlineButton(
          label: 'Ver minhas consultas',
          onTap: _openMyAppointments,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------- peças comuns

class _ProfessionalCard extends StatelessWidget {
  final BookingController controller;

  const _ProfessionalCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return _Card(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _Avatar(controller: c, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.professional.user.fullName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _Colors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.professional.typeFormatted,
                  style: const TextStyle(fontSize: 14, color: _Colors.muted),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _Colors.noticeBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        size: 14,
                        color: _Colors.noticeText,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Consulta online por vídeo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _Colors.noticeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Get.back(result: 'change'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: _Colors.ink,
              side: const BorderSide(color: _Colors.lineStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Trocar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final BookingController controller;
  final double size;

  const _Avatar({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    final user = controller.professional.user;
    final imageUrl = user.imageUrl;
    final initials = user.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _Colors.violetBackground,
      foregroundImage: imageUrl == null || imageUrl.isEmpty
          ? null
          : NetworkImage(imageUrl),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * .32,
          fontWeight: FontWeight.w700,
          color: _Colors.violet,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: 'Voltar',
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: _Colors.onInk.withValues(alpha: .12),
          foregroundColor: _Colors.onInk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.arrow_back, size: 20),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;

  const _Card({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _Colors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Colors.noticeBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _Colors.noticeText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: _Colors.noticeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double minWidth;

  const _Button({required this.label, required this.onTap, this.minWidth = 0});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: Size(minWidth, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        backgroundColor: _Colors.accent,
        foregroundColor: _Colors.ink,
        disabledBackgroundColor: _Colors.disabledButton,
        disabledForegroundColor: _Colors.noSlotsText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        backgroundColor: Colors.white,
        foregroundColor: _Colors.ink,
        side: const BorderSide(color: _Colors.lineStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const _EmptyBox({
    required this.title,
    required this.text,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: _Colors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _Colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _Colors.muted),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            _Button(label: action!, onTap: onAction),
          ],
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: CircularProgressIndicator(color: _Colors.accent)),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  final BookingController controller;

  const _LoadFailed({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _EmptyBox(
      title: 'Não foi possível carregar os horários',
      text: 'Verifique sua conexão e tente de novo.',
      action: 'Tentar de novo',
      onAction: controller.load,
    );
  }
}
