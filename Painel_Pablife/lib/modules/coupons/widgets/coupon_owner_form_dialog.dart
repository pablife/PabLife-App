import 'package:flutter/material.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/app_text_form_field.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';

/// Criar/editar titular. Devolve o titular e o e-mail da conta de acesso
/// ao painel (vazio = sem acesso).
class CouponOwnerFormDialog extends StatelessWidget {
  final CouponOwnerModel? editing;

  const CouponOwnerFormDialog({super.key, this.editing});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final instagramCtrl = TextEditingController(text: editing?.instagram ?? '');
    final emailCtrl = TextEditingController(text: editing?.email ?? '');
    final phoneCtrl = TextEditingController(text: editing?.phone ?? '');
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    final percent = editing?.commissionPercent ?? 0;
    final percentCtrl = TextEditingController(
      text: percent == 0
          ? ''
          : (percent == percent.roundToDouble()
                ? percent.toStringAsFixed(0)
                : percent.toStringAsFixed(2).replaceAll('.', ',')),
    );
    final monthsCtrl = TextEditingController(
      text: '${editing?.commissionMonths ?? 3}',
    );
    final accessCtrl = TextEditingController(text: editing?.accessEmail ?? '');
    String kind = editing?.kind ?? 'influencer';
    bool isActive = editing?.isActive ?? true;

    double? parsePercent(String text) {
      final clean = text.trim().replaceAll('%', '').replaceAll(' ', '');
      if (clean.isEmpty) return 0;
      final value = double.tryParse(clean.replaceAll(',', '.'));
      if (value == null || value < 0 || value > 100) return null;
      return value;
    }

    return AlertDialog(
      title: Text(editing == null ? 'Novo titular' : 'Editar titular'),
      content: SizedBox(
        width: 480,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextFormField(
                      controller: nameCtrl,
                      title: 'Nome',
                      hintText: 'Ex.: Ana Nutri',
                      validator: (v) =>
                          (v ?? '').trim().length < 2 ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 12),
                    const TextDefault(
                      text: 'Tipo',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: kind,
                      items: CouponOwnerModel.kinds.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => kind = v ?? kind),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextFormField(
                            controller: instagramCtrl,
                            title: 'Instagram',
                            hintText: '@perfil',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextFormField(
                            controller: phoneCtrl,
                            title: 'Telefone',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppTextFormField(
                      controller: emailCtrl,
                      title: 'E-mail de contato',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextFormField(
                            controller: percentCtrl,
                            title: 'Comissão (%)',
                            hintText: 'Ex.: 5 (vazio = sem comissão)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) => parsePercent(v ?? '') == null
                                ? 'De 0 a 100'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextFormField(
                            controller: monthsCtrl,
                            title: 'Por quantas mensalidades',
                            hintText: 'Ex.: 3',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final months = int.tryParse((v ?? '').trim());
                              return months == null || months < 1 || months > 36
                                  ? 'De 1 a 36'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const TextDefault(
                      text:
                          'A comissão é o percentual sobre as primeiras '
                          'mensalidades pagas por cada pessoa que usou o cupom. '
                          'Depois disso, aquela pessoa não gera mais comissão.',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    AppTextFormField(
                      controller: accessCtrl,
                      title: 'Acesso ao painel (opcional)',
                      hintText: 'E-mail da conta do titular no app',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final text = (v ?? '').trim();
                        if (text.isEmpty) return null;
                        return RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(text)
                            ? null
                            : 'E-mail inválido';
                      },
                    ),
                    const SizedBox(height: 4),
                    const TextDefault(
                      text:
                          'Com acesso, o titular entra neste painel com o login '
                          'do app e vê só os números dele, sem e-mail nem '
                          'sobrenome dos usuários.',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    AppTextFormField(
                      controller: notesCtrl,
                      title: 'Observações',
                      maxLines: 3,
                    ),
                    CheckboxListTile(
                      value: isActive,
                      onChanged: (v) => setState(() => isActive = v ?? true),
                      title: const Text('Ativo'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const TextDefault(text: 'Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(context, (
              CouponOwnerModel(
                id: editing?.id ?? '',
                name: nameCtrl.text.trim(),
                kind: kind,
                instagram: instagramCtrl.text,
                email: emailCtrl.text,
                phone: phoneCtrl.text,
                notes: notesCtrl.text,
                commissionPercent: parsePercent(percentCtrl.text) ?? 0,
                commissionMonths: int.parse(monthsCtrl.text.trim()),
                accessUserId: editing?.accessUserId,
                accessEmail: editing?.accessEmail,
                isActive: isActive,
                createdAt: editing?.createdAt,
              ),
              accessCtrl.text.trim(),
            ));
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
