import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../infra/models/affiliation.dart';
import '../../../infra/repositories/affiliation_repository.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../auth/pages/affiliation_page.dart';

/// "Meu vínculo" no Perfil: organização, sugestão em análise, particular ou
/// plano do convênio pausado. Mesmo formato do cartão "Sou estudante".
class AffiliationCard extends StatefulWidget {
  const AffiliationCard({super.key});

  @override
  State<AffiliationCard> createState() => _AffiliationCardState();
}

class _AffiliationCardState extends State<AffiliationCard> {
  late Future<MyAffiliation?> _mine = AffiliationRepository.instance.loadMine();
  bool _resuming = false;

  void _reload() =>
      setState(() => _mine = AffiliationRepository.instance.loadMine());

  Future<void> _edit(MyAffiliation? current) async {
    final saved = await AffiliationPage.openFromProfile(current: current);
    if (saved && mounted) _reload();
  }

  Future<void> _resume() async {
    setState(() => _resuming = true);
    final result = await AffiliationRepository.instance.resumePlan();
    if (!mounted) return;
    setState(() => _resuming = false);
    if (result.ok) {
      final until = result.endsAt == null
          ? ''
          : ' até ${DateFormat('dd/MM/yyyy').format(result.endsAt!)}';
      AppSnackbar.to.show('Plano reativado$until.');
      _reload();
    } else if (result.reason == 'contract_inactive') {
      AppSnackbar.to.show(
        'O convênio da sua organização não está ativo. Fale com o RH.',
      );
    } else {
      AppSnackbar.to.show('Não foi possível reativar o plano. Tente de novo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MyAffiliation?>(
      future: _mine,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return AffiliationCardView(
          affiliation: snapshot.data,
          busy: _resuming,
          onEdit: () => _edit(snapshot.data),
          onResume: _resume,
        );
      },
    );
  }
}

/// O desenho do cartão, separado para os testes.
class AffiliationCardView extends StatelessWidget {
  final MyAffiliation? affiliation;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onResume;

  const AffiliationCardView({
    super.key,
    required this.affiliation,
    required this.onEdit,
    required this.onResume,
    this.busy = false,
  });

  static const _waitBg = Color(0xFFFFF1D6);
  static const _waitFg = Color(0xFF6B4A00);

  @override
  Widget build(BuildContext context) {
    final a = affiliation;
    final (
      IconData icon,
      Color iconBg,
      Color iconFg,
      Color cardBg,
      String title,
      String text,
      String action,
      bool resume,
    ) = switch (a) {
      null => (
        Icons.badge_outlined,
        PabColors.lilac,
        PabColors.lilacText,
        PabColors.card,
        'Meu vínculo',
        'Servidor(a) ou colaborador(a) de empresa parceira? Informe e use '
            'seu código de convite.',
        'Informar',
        false,
      ),
      _ when a.planPaused => (
        Icons.schedule,
        _waitBg,
        _waitFg,
        PabColors.card,
        'Plano do convênio pausado',
        a.planPauseReason == 'faltas'
            ? 'Você faltou às duas últimas consultas.'
            : 'Você não teve consultas nos últimos 60 dias.',
        'Reativar plano',
        true,
      ),
      _ when a.suggestionPending => (
        Icons.schedule,
        _waitBg,
        _waitFg,
        PabColors.card,
        'Organização em análise',
        '${a.suggestedOrganization}. Avisamos por notificação.',
        'Alterar',
        false,
      ),
      _ when a.organizationId != null => (
        Icons.badge_outlined,
        PabColors.card,
        PabColors.accentText,
        PabColors.soft,
        a.organizationName ?? 'Organização vinculada',
        '${[a.kind.label, if ((a.roleTitle ?? '').isNotEmpty) a.roleTitle].join(' · ')}'
            '${a.planName == null ? '' : '. Plano ${a.planName} pelo convênio'}.',
        'Alterar',
        false,
      ),
      _ when a.kind == AffiliationKind.private => (
        Icons.badge_outlined,
        PabColors.lilac,
        PabColors.lilacText,
        PabColors.card,
        'Meu vínculo',
        'Particular.',
        'Alterar',
        false,
      ),
      _ => (
        Icons.badge_outlined,
        PabColors.lilac,
        PabColors.lilacText,
        PabColors.card,
        'Meu vínculo',
        '${a.kind.label}. Informe sua organização e use seu código de '
            'convite.',
        'Alterar',
        false,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: PabColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: busy ? null : (resume ? onResume : onEdit),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: PabColors.accent,
              foregroundColor: PabColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              action,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
