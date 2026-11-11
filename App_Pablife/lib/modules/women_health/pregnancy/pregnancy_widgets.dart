import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../dashboard/dashboard_controller.dart';
import 'pregnancy_models.dart';

/// Cores do design "Evolução da Gestação" que não estão em [PabColors].
abstract final class PregColors {
  /// Cartões de semanas que ainda vão chegar.
  static const future = Color(0xFFF7EEF7);

  /// Parte que falta na barra de progresso.
  static const rest = Color(0xFFF3CFE3);

  /// Fundo do aviso de atendimento.
  static const alert = Color(0xFFFFE6F4);
}

final dateBr = DateFormat('dd/MM/yyyy', 'pt_BR');
final shortDateBr = DateFormat('dd MMM yyyy', 'pt_BR');

/// Leva à aba Profissionais (para conversar com um psicólogo da Pablife).
void openPsychologists() {
  Get.until((route) => route.isFirst);
  if (Get.isRegistered<DashboardController>()) {
    DashboardController.to.changeTab(3);
  }
}

/// Ilustração do bebê num círculo branco.
class BabyImage extends StatelessWidget {
  final String? url;
  final double size;
  final String semantics;

  const BabyImage({
    super.key,
    required this.url,
    required this.size,
    required this.semantics,
  });

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.9;
    return Semantics(
      label: semantics,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: PabColors.card,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClipOval(
          child: SizedBox(
            width: inner,
            height: inner,
            child: url == null
                ? const _BabyPlaceholder()
                : CachedNetworkImage(
                    imageUrl: url!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _BabyPlaceholder(),
                    errorWidget: (_, _, _) => const _BabyPlaceholder(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _BabyPlaceholder extends StatelessWidget {
  const _BabyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: PabColors.soft,
      child: Center(
        child: Icon(
          Icons.child_care_rounded,
          color: PabColors.softText,
          size: 36,
        ),
      ),
    );
  }
}

/// Um número com legenda (Comprimento, Peso, Parecido com).
class StatTile extends StatelessWidget {
  final String label;
  final String value;

  const StatTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: PabColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Comprimento, peso e comparação lado a lado.
class WeekStats extends StatelessWidget {
  final PregnancyWeek? data;
  final String comparisonLabel;

  const WeekStats({
    super.key,
    required this.data,
    this.comparisonLabel = 'Parecido com',
  });

  @override
  Widget build(BuildContext context) {
    final d = data;
    final tiles = [
      StatTile(label: 'Comprimento', value: d?.lengthLabel ?? '—'),
      StatTile(label: 'Peso', value: d?.weightLabel ?? '—'),
      if (d?.comparison != null)
        StatTile(label: comparisonLabel, value: d!.comparison!),
    ];
    return Row(
      children: [
        for (final (i, t) in tiles.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: t),
        ],
      ],
    );
  }
}

/// Barra de três trimestres (13, 14 e 13 semanas).
class WeekProgress extends StatelessWidget {
  final int week;

  const WeekProgress({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    const parts = [(0, 13), (13, 27), (27, 40)];
    return Semantics(
      label: 'Progresso: semana $week de 40',
      child: Row(
        children: [
          for (final (i, (start, end)) in parts.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              flex: end - start,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ((week - start) / (end - start)).clamp(0.0, 1.0),
                  minHeight: 8,
                  color: PabColors.pink,
                  backgroundColor: PregColors.rest,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Faltam X dias" e a data provável do parto.
class DueLine extends StatelessWidget {
  final Pregnancy pregnancy;
  final String dueLabel;

  const DueLine({
    super.key,
    required this.pregnancy,
    this.dueLabel = 'Parto previsto',
  });

  @override
  Widget build(BuildContext context) {
    final p = pregnancy;
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: PabColors.muted,
    );
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          p.daysLeft == 0
              ? 'A data provável chegou'
              : p.daysLeft == 1
              ? 'Falta 1 dia'
              : 'Faltam ${p.daysLeft} dias',
          style: style,
        ),
        Text('$dueLabel: ${dateBr.format(p.dpp)}', style: style),
      ],
    );
  }
}

/// Título de seção.
class PregSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const PregSectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PabColors.ink,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Cartão branco com itens "Título. Frase" e um ícone em cada.
class TipsCard extends StatelessWidget {
  final List<WeekTip> tips;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const TipsCard({
    super.key,
    required this.tips,
    required this.icon,
    this.iconBackground = PabColors.soft,
    this.iconColor = PabColors.softText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PabColors.line),
      ),
      child: Column(
        children: [
          for (final (i, tip) in tips.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (tip.title.isNotEmpty)
                          TextSpan(
                            text: '${tip.title} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: PabColors.ink,
                            ),
                          ),
                        TextSpan(text: tip.text),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: PabColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Procure atendimento sem esperar": sinais de alerta, sem diagnóstico.
class AlertSignsCard extends StatelessWidget {
  final PregnancyWeek? data;

  const AlertSignsCard({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final alerts = data?.alerts ?? const [];
    final text = alerts.isEmpty
        ? pregnancyAlertFallback
        : 'Procure um serviço de saúde em caso de: '
              '${alerts.map((a) => a.title.replaceAll('.', '').toLowerCase()).join(', ')}.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PregColors.alert,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: PabColors.softText,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Procure atendimento sem esperar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PabColors.softText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: PabColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso fixo "Cada gestação é única" com o botão do psicólogo.
class PregnancyNoticeCard extends StatelessWidget {
  final String title;
  final String text;
  final String button;

  const PregnancyNoticeCard({
    super.key,
    this.title = 'Cada gestação é única',
    this.text =
        'Tamanhos e pesos são médias e podem variar. Esta ferramenta não '
        'substitui o pré-natal: converse sempre com sua médica ou obstetra. '
        'Se sentir algo diferente do esperado, procure atendimento.',
    this.button = 'Conversar com um psicólogo da Pablife',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PabColors.lilac,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: PabColors.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PabColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: PabColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: openPsychologists,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: PabColors.ink,
              side: const BorderSide(color: PabColors.ink, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              button,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão escuro largo (Novo registro, Salvar registro...).
class PregPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;

  const PregPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: PabColors.ink,
        foregroundColor: PabColors.onInk,
        disabledBackgroundColor: PabColors.ink.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: PabColors.onInk,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Botão quadrado de 44 px do topo (voltar, fechar, novo).
class PregIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool dark;

  const PregIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: dark ? PabColors.ink : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: dark
              ? BorderSide.none
              : const BorderSide(color: PabColors.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 20,
              color: dark ? PabColors.onInk : PabColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Topo das telas da gestação: voltar, título e ação opcional.
class PregTopBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final IconData backIcon;
  final String backTooltip;

  const PregTopBar({
    super.key,
    required this.title,
    this.trailing,
    this.backIcon = Icons.arrow_back_rounded,
    this.backTooltip = 'Voltar',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        0,
      ),
      child: Row(
        children: [
          PregIconButton(
            icon: backIcon,
            tooltip: backTooltip,
            onPressed: () => Get.back<void>(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: PabColors.ink,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
