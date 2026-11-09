import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../infra/models/subscription_plan_model.dart';
import '../../../infra/repositories/student_repository.dart';
import '../../../infra/services/subscription_service.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/design_system/app_dialog.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../auth/pages/student_proof_page.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../controllers/subscription_controller.dart';
import 'subscription_page.dart';

/// "Minha assinatura" (canvas S2): plano atual, saldo, validade, próxima
/// cobrança, forma de pagamento, desconto de estudante e as ações (trocar
/// de plano, histórico e cancelar).
class MySubscriptionPage extends StatefulWidget {
  const MySubscriptionPage({super.key});

  static const route = '/profile/my-subscription';

  @override
  State<MySubscriptionPage> createState() => _MySubscriptionPageState();
}

class _MySubscriptionPageState extends State<MySubscriptionPage> {
  final _money = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final _date = DateFormat('dd/MM/yyyy');

  StudentStatus? _student;
  List<ConsultationBalance> _balances = [];

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final results = await Future.wait([
      StudentRepository().myStatus(),
      SubscriptionService.instance.getConsultationBalances(),
    ]);
    if (!mounted) return;
    setState(() {
      _student = results[0] as StudentStatus;
      _balances = results[1] as List<ConsultationBalance>;
    });
  }

  String _paymentLabel(SubscriptionController c) {
    final sub = c.activeSubscription;
    final id = sub?.mpPreapprovalId ?? '';
    if (id.startsWith('COUPON-')) return 'Cupom';
    if (id.startsWith('COURTESY-')) return 'Cortesia';
    return switch (c.activeTransaction?.paymentTypeId) {
      'credit_card' => 'Cartão de crédito',
      'debit_card' => 'Cartão de débito',
      'bank_transfer' || 'pix' => 'Pix',
      'ticket' => 'Boleto',
      _ => 'Cartão de crédito',
    };
  }

  Future<void> _cancel(SubscriptionController c) async {
    final ok = await AppDialog.showConfirmation(
      context: context,
      title: 'Cancelar assinatura?',
      message:
          'As próximas cobranças param. As consultas que já estão no saldo '
          'continuam valendo até a data de validade.',
      confirmText: 'Cancelar assinatura',
      cancelText: 'Manter',
      destructive: true,
      icon: Icons.event_busy_rounded,
    );
    if (ok == true) await c.cancelSubscription();
  }

  Future<void> _history(SubscriptionController c) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    List<Map<String, dynamic>> rows = [];
    try {
      final data = await Supabase.instance.client
          .from('tb_subscription_transactions')
          .select(
            'status, transaction_amount, mp_date_created, created_at, '
            'tb_user_subscriptions!inner(user_id, reason)',
          )
          .eq('tb_user_subscriptions.user_id', uid)
          .order('created_at', ascending: false)
          .limit(30);
      rows = [for (final r in data) Map<String, dynamic>.from(r)];
    } catch (_) {}
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: PabColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Histórico de pagamentos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
              ),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhum pagamento por aqui ainda.',
                    style: TextStyle(color: PabColors.muted),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: PabColors.line),
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      final when = DateTime.tryParse(
                        '${r['mp_date_created'] ?? r['created_at']}',
                      );
                      final amount = (r['transaction_amount'] as num?)
                          ?.toDouble();
                      final approved = r['status'] == 'approved';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        title: Text(
                          (r['tb_user_subscriptions'] as Map?)?['reason']
                                  ?.toString() ??
                              'Plano',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: PabColors.ink,
                          ),
                        ),
                        subtitle: Text(
                          when == null ? '' : _date.format(when.toLocal()),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              amount == null ? '—' : _money.format(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: PabColors.ink,
                              ),
                            ),
                            Text(
                              approved ? 'Aprovado' : 'Não aprovado',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: approved
                                    ? PabColors.accentText
                                    : PabColors.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      builder: (c) {
        final sub = c.activeSubscription;
        final SubscriptionPlanModel? plan = c.plans.firstWhereOrNull(
          (p) => p.id == c.activePlanId,
        );
        final open = _balances.where((b) => b.remaining > 0).toList()
          ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
        final remaining = open.fold<int>(0, (s, b) => s + b.remaining);
        final cancelled = c.isSubscriptionCancelled;

        Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: PabColors.muted),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: PabColors.ink,
                ),
              ),
            ],
          ),
        );

        return RegistrationLayout(
          title: 'Minha assinatura',
          onBack: () => Get.back<void>(),
          fields: [
            if (sub == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PabColors.card,
                  border: Border.all(color: PabColors.line),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Você ainda não tem um plano ativo. Escolha um plano para '
                  'agendar consultas online.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: PabColors.muted,
                  ),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PabColors.ink,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: AppImage(
                        imageUrl: plan?.imagePath,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 72,
                          height: 72,
                          color: PabColors.accent,
                          child: const Icon(
                            Icons.workspace_premium_outlined,
                            color: PabColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                plan?.reason ?? sub.reason ?? 'Seu plano',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: PabColors.onInk,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: cancelled
                                      ? const Color(0xFFFFF1D6)
                                      : PabColors.accent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  cancelled ? 'CANCELADA' : 'ATIVO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: cancelled
                                        ? const Color(0xFF6B4A00)
                                        : PabColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sub.transactionAmount == null
                                ? ''
                                : '${_money.format(sub.transactionAmount)}/mês'
                                      '${_student == StudentStatus.approved ? ' · com desconto estudante' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: PabColors.navIdle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PabColors.card,
                  border: Border.all(color: PabColors.line),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    line(
                      'Consultas no saldo',
                      plan == null
                          ? '$remaining'
                          : '$remaining de ${plan.consultations}',
                    ),
                    if (open.isNotEmpty)
                      line(
                        'Válidas até',
                        _date.format(open.first.expiresAt.toLocal()),
                      ),
                    if (!cancelled && sub.nextPaymentDate != null)
                      line(
                        'Próxima cobrança',
                        _date.format(sub.nextPaymentDate!.toLocal()),
                      ),
                    if (cancelled && sub.endDate != null)
                      line('Acesso até', _date.format(sub.endDate!.toLocal())),
                    line('Forma de pagamento', _paymentLabel(c)),
                  ],
                ),
              ),
            ],
            if (_student != null) _StudentBox(status: _student!),
          ],
          footer: [
            RegPrimaryButton(
              label: sub == null ? 'Ver planos' : 'Trocar de plano',
              onTap: () async {
                await Get.toNamed(SubscriptionPage.route);
                c.reload();
                _loadExtras();
              },
            ),
            if (sub != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _history(c),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: PabColors.ink,
                  side: const BorderSide(color: PabColors.lineStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Histórico de pagamentos',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (!cancelled)
                TextButton(
                  onPressed: c.isLoadingCancelSubscription
                      ? null
                      : () => _cancel(c),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: PabColors.error,
                  ),
                  child: Text(
                    c.isLoadingCancelSubscription
                        ? 'Cancelando…'
                        : 'Cancelar assinatura',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _StudentBox extends StatelessWidget {
  final StudentStatus status;

  const _StudentBox({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, text) = switch (status) {
      StudentStatus.approved => (
        'Aprovado',
        PabColors.soft,
        PabColors.softText,
        'Você tem 10% de desconto em qualquer plano.',
      ),
      StudentStatus.pending => (
        'Em análise',
        const Color(0xFFFFF1D6),
        const Color(0xFF6B4A00),
        'Respondemos em até 24 horas. O desconto entra assim que aprovar.',
      ),
      StudentStatus.rejected => (
        'Recusado',
        const Color(0xFFFCE8F3),
        const Color(0xFF7A1F52),
        'Seu comprovante não foi aprovado. Envie um novo para ganhar 10%.',
      ),
      StudentStatus.none => (
        'Não enviado',
        PabColors.track,
        PabColors.muted,
        'É estudante? Envie o comprovante e ganhe 10% em qualquer plano.',
      ),
    };
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
              const Expanded(
                child: Text(
                  'Desconto de estudante',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PabColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: fg,
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
              height: 1.45,
              color: PabColors.muted,
            ),
          ),
          if (status == StudentStatus.rejected ||
              status == StudentStatus.none) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: StudentProofPage.openFromProfile,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: PabColors.ink,
                side: const BorderSide(color: PabColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                status == StudentStatus.none
                    ? 'Enviar comprovante'
                    : 'Enviar novo comprovante',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
