import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/wide_layout.dart';
import '../../../widgets/design_system/app_dialog.dart';
import '../women_health_controller.dart';
import 'pregnancy_controller.dart';
import 'pregnancy_dashboard_card.dart';
import 'pregnancy_evolution_page.dart';
import 'pregnancy_models.dart';
import 'pregnancy_record_page.dart';
import 'pregnancy_week_page.dart';
import 'pregnancy_widgets.dart';

/// "Minha gestação": a semana atual, o bebê semana a semana e os registros.
/// No computador vira o painel em colunas (com o gráfico de peso).
class MyPregnancyPage extends StatelessWidget {
  const MyPregnancyPage({super.key});

  static Future<void> open() => Get.to<void>(() => const MyPregnancyPage())!;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Scaffold(
      backgroundColor: PabColors.background,
      body: GetBuilder<PregnancyController>(
        init: PregnancyController.to,
        builder: (c) {
          final p = c.pregnancy;
          if (p == null) {
            return Column(
              children: [
                const PregTopBar(title: 'Minha gestação'),
                Expanded(
                  child: Center(
                    child: c.loading
                        ? const CircularProgressIndicator(
                            color: PabColors.softText,
                          )
                        : const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Nenhuma gestação em acompanhamento.',
                              style: TextStyle(color: PabColors.muted),
                            ),
                          ),
                  ),
                ),
              ],
            );
          }
          return wide ? _Wide(c: c, p: p) : _Phone(c: c, p: p);
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- celular

class _Phone extends StatelessWidget {
  final PregnancyController c;
  final Pregnancy p;

  const _Phone({required this.c, required this.p});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PregTopBar(
          title: 'Minha gestação',
          trailing: PregIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Novo registro',
            dark: true,
            onPressed: PregnancyRecordPage.open,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: PabColors.softText,
            onRefresh: c.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _Hero(c: c, p: p, imageSize: 216),
                const SizedBox(height: 24),
                PregSectionTitle(
                  'Semana a semana',
                  trailing: TextButton(
                    onPressed: PregnancyEvolutionPage.open,
                    style: TextButton.styleFrom(
                      foregroundColor: PabColors.softText,
                    ),
                    child: const Text(
                      'Ver tudo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const Text(
                  'Valores médios aproximados',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PabColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 214,
                  child: _WeekStrip(c: c, p: p, cardWidth: 148),
                ),
                const SizedBox(height: 24),
                _Records(c: c, p: p),
                const SizedBox(height: 24),
                const PregnancyNoticeCard(),
                const SizedBox(height: 8),
                _EndButton(c: c),
              ],
            ),
          ),
        ),
        _BottomBar(
          child: PregPrimaryButton(
            label: 'Novo registro',
            icon: Icons.add_rounded,
            onPressed: PregnancyRecordPage.open,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: PabColors.background,
        border: Border(top: BorderSide(color: PabColors.line)),
      ),
      child: child,
    );
  }
}

/// Bebê, semana, medidas, progresso e link para a semana.
class _Hero extends StatelessWidget {
  final PregnancyController c;
  final Pregnancy p;
  final double imageSize;
  final bool wide;

  const _Hero({
    required this.c,
    required this.p,
    required this.imageSize,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = c.weekData(p.shownWeek);
    final image = BabyImage(
      url: c.imageFor(p.week),
      size: imageSize,
      semantics: 'Ilustração do bebê na semana ${p.week}',
    );
    final info = Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (wide) ...[
          _Pill(trimesterLabel(p.week)),
          const SizedBox(height: 10),
        ],
        Text(
          'Semana ${p.week}',
          style: const TextStyle(
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: PabColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          wide
              ? '${p.weekAndDays} · ${milestone(p).toLowerCase()}'
              : '${p.weekAndDays} · ${trimesterLabel(p.week)}',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: const TextStyle(fontSize: 14, color: PabColors.muted),
        ),
        const SizedBox(height: 16),
        WeekStats(
          data: data,
          comparisonLabel: wide ? 'Tamanho de' : 'Parecido com',
        ),
        const SizedBox(height: 16),
        WeekProgress(week: p.week),
        const SizedBox(height: 8),
        DueLine(pregnancy: p),
        const SizedBox(height: 12),
        Align(
          alignment: wide ? Alignment.centerLeft : Alignment.center,
          child: TextButton(
            onPressed: () => PregnancyWeekPage.open(p.shownWeek),
            style: TextButton.styleFrom(foregroundColor: PabColors.softText),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver detalhes da semana ${p.shownWeek}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PregColors.alert,
        borderRadius: BorderRadius.circular(28),
      ),
      child: wide
          ? Row(
              children: [
                image,
                const SizedBox(width: 28),
                Expanded(child: info),
              ],
            )
          : Column(children: [image, const SizedBox(height: 16), info]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: PabColors.softText,
        ),
      ),
    );
  }
}

/// Cartões das semanas de referência (8, 12, ..., 40).
class _WeekStrip extends StatelessWidget {
  final PregnancyController c;
  final Pregnancy p;
  final double cardWidth;

  const _WeekStrip({required this.c, required this.p, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final current = nearestReferenceWeek(p.week);
    final cards = [
      for (final w in referenceWeeks)
        WeekCard(
          week: w,
          data: c.weekData(w),
          image: c.weekData(w)?.imageUrl,
          isCurrent: w == current,
          isFuture: w > current,
          width: cardWidth,
          showComparison: true,
        ),
    ];
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: cards.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) => cards[i],
    );
  }
}

class WeekCard extends StatelessWidget {
  final int week;
  final PregnancyWeek? data;
  final String? image;
  final bool isCurrent;
  final bool isFuture;
  final double width;
  final bool showComparison;

  const WeekCard({
    super.key,
    required this.week,
    required this.data,
    required this.image,
    required this.isCurrent,
    required this.isFuture,
    required this.width,
    this.showComparison = true,
  });

  @override
  Widget build(BuildContext context) {
    final d = data;
    return SizedBox(
      width: width,
      child: Material(
        color: isFuture ? PregColors.future : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: isCurrent
              ? const BorderSide(color: PabColors.pink, width: 2)
              : isFuture
              ? BorderSide.none
              : const BorderSide(color: PabColors.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => PregnancyWeekPage.open(week),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                BabyImage(
                  url: image,
                  size: width - 48,
                  semantics: 'Bebê na semana $week',
                ),
                const SizedBox(height: 8),
                Text(
                  'Semana $week',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    d == null
                        ? ''
                        : '${d.lengthLabel} · '
                              '${d.weightLabel.replaceFirst('≈ ', '')}',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PabColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: PabColors.ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Você está aqui',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PabColors.onInk,
                      ),
                    ),
                  )
                else if (showComparison && d?.comparison != null)
                  Text(
                    d!.comparison!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PabColors.muted,
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

/// "Meus registros": linha do tempo com filtro por tipo.
class _Records extends StatefulWidget {
  final PregnancyController c;
  final Pregnancy p;

  const _Records({required this.c, required this.p});

  @override
  State<_Records> createState() => _RecordsState();
}

class _RecordsState extends State<_Records> {
  PregnancyRecordType? _filter;

  @override
  Widget build(BuildContext context) {
    final list = widget.c.records
        .where((r) => _filter == null || r.type == _filter)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PregSectionTitle(
          'Meus registros',
          trailing: PopupMenuButton<PregnancyRecordType?>(
            tooltip: 'Filtrar registros',
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(child: Text('Tudo')),
              for (final t in PregnancyRecordType.values)
                PopupMenuItem(value: t, child: Text(t.label)),
            ],
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: PabColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PabColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _filter?.label ?? 'Tudo',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: PabColors.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PabColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PabColors.line),
            ),
            child: Text(
              _filter == null
                  ? 'Seus registros aparecem aqui: consultas, ultrassons, '
                        'exames, movimentos do bebê e anotações.'
                  : 'Nenhum registro deste tipo ainda.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: PabColors.muted,
              ),
            ),
          )
        else
          for (final (i, r) in list.indexed)
            RecordTile(
              record: r,
              pregnancy: widget.p,
              controller: widget.c,
              last: i == list.length - 1,
            ),
      ],
    );
  }
}

String _relative(DateTime date) {
  final days = DateUtils.dateOnly(
    DateTime.now(),
  ).difference(DateUtils.dateOnly(date)).inDays;
  if (days <= 0) return 'hoje';
  if (days == 1) return 'ontem';
  if (days < 7) return 'há $days dias';
  final weeks = days ~/ 7;
  return weeks == 1 ? 'há 1 semana' : 'há $weeks semanas';
}

class RecordTile extends StatelessWidget {
  final PregnancyRecord record;
  final Pregnancy pregnancy;
  final PregnancyController controller;
  final bool last;

  const RecordTile({
    super.key,
    required this.record,
    required this.pregnancy,
    required this.controller,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final r = record;
    final pinkIcon =
        r.type == PregnancyRecordType.movimentos ||
        r.type == PregnancyRecordType.ultrassom ||
        r.type == PregnancyRecordType.sintoma;
    final gain = controller.weightGain(r);
    final chips = [
      if (r.motherWeight != null)
        gain == null
            ? formatKg(r.motherWeight!)
            : '${formatKg(r.motherWeight!)} · ${gain >= 0 ? '+' : '−'}'
                  '${formatKg(gain.abs())}',
      if (r.pressure != null) 'Pressão ${r.pressure}',
      if (r.heartRate != null) 'Bebê ${r.heartRate} bpm',
      if (r.babyLength != null) '≈ ${formatCm(r.babyLength!)}',
      if (r.babyWeight != null) '≈ ${formatG(r.babyWeight!.toDouble())}',
      if (r.feeling != null) r.feeling!,
    ];
    final week = pregnancy.weekOn(r.date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pinkIcon ? PabColors.soft : PabColors.lilac,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    r.type.icon,
                    size: 20,
                    color: pinkIcon ? PabColors.softText : PabColors.ink,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: PabColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${shortDateBr.format(r.date)} · $week sem',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PabColors.muted,
                          ),
                        ),
                      ),
                      Text(
                        _relative(r.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: PabColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: PabColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: PabColors.line),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onLongPress: () => _confirmDelete(context),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          r.type.label,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: PabColors.ink,
                                          ),
                                        ),
                                      ),
                                      if (r.shared) ...[
                                        const SizedBox(width: 8),
                                        const Tooltip(
                                          message:
                                              'Compartilhado com seu profissional',
                                          child: Icon(
                                            Icons.people_outline_rounded,
                                            size: 16,
                                            color: PabColors.lilacText,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (chips.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (final chip in chips) _Chip(chip),
                                      ],
                                    ),
                                  ],
                                  if (r.notes != null &&
                                      r.notes!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      r.notes!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: PabColors.muted,
                                      ),
                                    ),
                                  ],
                                  if (r.photoPath != null) ...[
                                    const SizedBox(height: 10),
                                    _PhotoLink(
                                      path: r.photoPath!,
                                      controller: controller,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Apagar registro',
                              onPressed: () => _confirmDelete(context),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: PabColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await AppDialog.showConfirmation(
      context: context,
      title: 'Apagar registro?',
      message:
          'O registro de ${dateBr.format(record.date)} será apagado. '
          'Essa ação não pode ser desfeita.',
      confirmText: 'Apagar',
      cancelText: 'Cancelar',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (ok == true) await controller.deleteRecord(record);
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PabColors.lilac,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: PabColors.ink,
        ),
      ),
    );
  }
}

/// "Foto do exame anexada": abre a foto por um link temporário.
class _PhotoLink extends StatelessWidget {
  final String path;
  final PregnancyController controller;

  const _PhotoLink({required this.path, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PabColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final link = await controller.photoLink(path);
          if (link != null) {
            await launchUrl(
              Uri.parse(link),
              mode: LaunchMode.externalApplication,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PregColors.rest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_outlined, color: PabColors.muted),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Foto do exame anexada',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PabColors.muted,
                  ),
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: PabColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encerrar o acompanhamento: para os avisos semanais e sai da trilha.
class _EndButton extends StatelessWidget {
  final PregnancyController c;

  const _EndButton({required this.c});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final ok = await AppDialog.showConfirmation(
          context: context,
          title: 'Encerrar acompanhamento?',
          message:
              'Os avisos semanais da gestação param. Seus registros continuam '
              'guardados na sua conta. Depois você pode escolher outra trilha '
              'na Saúde da Mulher.',
          confirmText: 'Encerrar',
          cancelText: 'Voltar',
          icon: Icons.pause_circle_outline_rounded,
        );
        if (ok != true) return;
        await c.endPregnancy();
        if (Get.isRegistered<WomenHealthController>()) {
          await WomenHealthController.to.exit();
        }
        Get.until((route) => route.isFirst);
      },
      style: TextButton.styleFrom(foregroundColor: PabColors.muted),
      child: const Text(
        'Encerrar acompanhamento da gestação',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------- web

class _Wide extends StatelessWidget {
  final PregnancyController c;
  final Pregnancy p;

  const _Wide({required this.c, required this.p});

  @override
  Widget build(BuildContext context) {
    final next = c.weekData(p.shownWeek)?.consult ?? const [];
    final women = Get.isRegistered<WomenHealthController>()
        ? WomenHealthController.to
        : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PregIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Voltar',
                    onPressed: () => Get.back<void>(),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Minha gestação',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Acompanhe o desenvolvimento do bebê semana a semana '
                          'e guarde cada consulta, exame e novidade na linha '
                          'do tempo.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: PabColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: PregPrimaryButton(
                      label: 'Novo registro',
                      icon: Icons.add_rounded,
                      onPressed: PregnancyRecordPage.open,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _Hero(c: c, p: p, imageSize: 240, wide: true),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const PregSectionTitle('Próximos passos'),
                          const SizedBox(height: 12),
                          if (next.isEmpty)
                            const NextStepCard(
                              tip: (
                                title: 'Pré-natal.',
                                text:
                                    'Mantenha as consultas em dia e leve suas '
                                    'dúvidas anotadas.',
                              ),
                            )
                          else
                            for (final tip in next) ...[
                              NextStepCard(tip: tip),
                              const SizedBox(height: 12),
                            ],
                          const Spacer(),
                          if (women != null) ...[
                            const SizedBox(height: 12),
                            _WideMood(women: women),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PregSectionTitle(
                'Como o bebê vai crescendo',
                trailing: TextButton(
                  onPressed: PregnancyEvolutionPage.open,
                  style: TextButton.styleFrom(
                    foregroundColor: PabColors.softText,
                  ),
                  child: const Text(
                    'Ver evolução completa',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const Text(
                'Valores médios aproximados',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PabColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: _WeekStrip(c: c, p: p, cardWidth: 130),
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _WeightChart(c: c, p: p),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _Records(c: c, p: p),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const PregnancyNoticeCard(
                text:
                    'Tamanhos, pesos e datas são médias e estimativas, e podem '
                    'variar. Esta ferramenta não substitui o pré-natal: '
                    'converse sempre com sua médica ou obstetra. Se sentir '
                    'algo diferente do esperado, procure atendimento.',
              ),
              const SizedBox(height: 8),
              Center(child: _EndButton(c: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideMood extends StatelessWidget {
  final WomenHealthController women;

  const _WideMood({required this.women});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PabColors.line),
      ),
      child: const Row(
        children: [
          Icon(Icons.mood_rounded, color: PabColors.lilacText, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Como você está hoje? Registre no Dashboard em poucos segundos.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: PabColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _minY(List<PregnancyRecord> p) =>
    p
        .map((r) => r.motherWeight!)
        .reduce((a, b) => a < b ? a : b)
        .floorToDouble() -
    1;

double _maxY(List<PregnancyRecord> p) =>
    p
        .map((r) => r.motherWeight!)
        .reduce((a, b) => a > b ? a : b)
        .ceilToDouble() +
    1;

double _step(List<PregnancyRecord> p) => _maxY(p) - _minY(p) > 8 ? 2 : 1;

/// "Meu peso ao longo da gestação".
class _WeightChart extends StatelessWidget {
  final PregnancyController c;
  final Pregnancy p;

  const _WeightChart({required this.c, required this.p});

  @override
  Widget build(BuildContext context) {
    final points = c.weightRecords;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PabColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PregSectionTitle('Meu peso ao longo da gestação'),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: points.length < 2
                ? const Center(
                    child: Text(
                      'Registre o peso em duas consultas ou mais para ver o '
                      'gráfico.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: PabColors.muted),
                    ),
                  )
                : Semantics(
                    label:
                        'Gráfico do peso: de ${formatKg(points.first.motherWeight!)} '
                        'na semana ${p.weekOn(points.first.date)} a '
                        '${formatKg(points.last.motherWeight!)} na semana '
                        '${p.weekOn(points.last.date)}',
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 40,
                        minY: _minY(points),
                        maxY: _maxY(points),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: _step(points),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 8,
                              getTitlesWidget: (v, _) => Text(
                                'sem ${v.toInt()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: PabColors.muted,
                                ),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: _step(points),
                              getTitlesWidget: (v, _) => Text(
                                v.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: PabColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (final r in points)
                                FlSpot(
                                  r.date.difference(p.dum).inDays / 7,
                                  r.motherWeight!,
                                ),
                            ],
                            color: PabColors.softText,
                            barWidth: 3,
                            dotData: const FlDotData(),
                            belowBarData: BarAreaData(
                              show: true,
                              color: PabColors.soft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          const Text(
            'O ganho de peso esperado varia de gestante para gestante. '
            'Converse com sua médica ou com uma nutricionista da Pablife.',
            style: TextStyle(fontSize: 12, height: 1.5, color: PabColors.muted),
          ),
        ],
      ),
    );
  }
}
