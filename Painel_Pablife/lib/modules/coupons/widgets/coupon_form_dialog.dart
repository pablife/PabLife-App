import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:painel_pablife/infra/models/coupon_model.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/app_text_form_field.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';

/// Criar/editar cupom. Devolve o [CouponModel] preenchido ao salvar.
class CouponFormDialog extends StatelessWidget {
  final CouponModel? editing;
  final List<CouponOwnerModel> owners;

  const CouponFormDialog({super.key, this.editing, this.owners = const []});

  static final _codePattern = RegExp(r'^[A-Z0-9_-]{3,40}$');

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: editing?.code ?? '');
    final descriptionCtrl = TextEditingController(
      text: editing?.description ?? '',
    );
    final daysCtrl = TextEditingController(text: '${editing?.freeDays ?? 30}');
    final maxUsesCtrl = TextEditingController(
      text: editing?.maxUses?.toString() ?? '',
    );
    DateTime? validFrom = editing?.validFrom;
    DateTime? validUntil = editing?.validUntil;
    bool isActive = editing?.isActive ?? true;
    String? ownerId = owners.any((o) => o.id == editing?.ownerId)
        ? editing?.ownerId
        : null;
    String? dateError;
    // setState do conteúdo, para o botão Salvar mostrar erro de data.
    void Function(void Function())? refreshContent;

    String formatDate(DateTime? date) =>
        date == null ? '' : DateFormat('dd/MM/yyyy').format(date);

    Future<DateTime?> pickDate(DateTime? initial) {
      final now = DateTime.now();
      return showDatePicker(
        context: context,
        initialDate: initial ?? now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
        locale: const Locale('pt', 'BR'),
      );
    }

    return AlertDialog(
      title: Text(editing == null ? 'Novo cupom' : 'Editar cupom'),
      content: SizedBox(
        width: 460,
        child: StatefulBuilder(
          builder: (context, setState) {
            refreshContent = setState;
            Widget dateField({
              required String label,
              required DateTime? value,
              required String emptyText,
              required ValueChanged<DateTime?> onChanged,
            }) {
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextDefault(
                      text: label,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(
                        value == null ? emptyText : formatDate(value),
                      ),
                      onPressed: () async {
                        final picked = await pickDate(value);
                        if (picked != null) setState(() => onChanged(picked));
                      },
                    ),
                    if (value != null)
                      TextButton(
                        onPressed: () => setState(() => onChanged(null)),
                        child: const Text('Limpar'),
                      ),
                  ],
                ),
              );
            }

            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextFormField(
                      controller: codeCtrl,
                      title: 'Código do cupom',
                      hintText: 'Ex.: BEMVINDO30',
                      validator: (value) {
                        final code = (value ?? '').trim().toUpperCase();
                        if (!_codePattern.hasMatch(code)) {
                          return 'Use de 3 a 40 letras, números, "-" ou "_", sem espaços';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextFormField(
                      controller: descriptionCtrl,
                      title: 'Descrição (opcional, só para o painel)',
                      hintText: 'Ex.: Campanha de lançamento no Instagram',
                    ),
                    const SizedBox(height: 12),
                    const TextDefault(
                      text: 'Titular (quem divulga o cupom)',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: ownerId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sem titular'),
                        ),
                        ...owners.map(
                          (o) => DropdownMenuItem<String?>(
                            value: o.id,
                            child: Text('${o.name} (${o.kindLabel})'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => ownerId = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextFormField(
                            controller: daysCtrl,
                            title: 'Dias grátis',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final days = int.tryParse((value ?? '').trim());
                              if (days == null || days < 1 || days > 365) {
                                return 'De 1 a 365 dias';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextFormField(
                            controller: maxUsesCtrl,
                            title: 'Limite de usos',
                            hintText: 'Vazio = sem limite',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return null;
                              final max = int.tryParse(text);
                              if (max == null || max < 1) {
                                return 'Número a partir de 1';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        dateField(
                          label: 'Válido a partir de',
                          value: validFrom,
                          emptyText: 'Já vale',
                          onChanged: (d) => validFrom = d,
                        ),
                        const SizedBox(width: 12),
                        dateField(
                          label: 'Válido até',
                          value: validUntil,
                          emptyText: 'Sem prazo',
                          onChanged: (d) => validUntil = d,
                        ),
                      ],
                    ),
                    if (dateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextDefault(
                          text: dateError!,
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: isActive,
                      onChanged: (v) => setState(() => isActive = v ?? true),
                      title: const Text('Ativo (pode ser usado no app)'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const TextDefault(
                      text:
                          'O cupom libera o plano escolhido pela pessoa pelos '
                          'dias grátis, sem cartão. Cada pessoa usa o mesmo '
                          'cupom uma vez.',
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

            // "Válido até" vale até o fim do dia escolhido.
            final until = validUntil == null
                ? null
                : DateTime(
                    validUntil!.year,
                    validUntil!.month,
                    validUntil!.day,
                    23,
                    59,
                    59,
                  );
            final from = validFrom == null
                ? null
                : DateTime(validFrom!.year, validFrom!.month, validFrom!.day);
            if (from != null && until != null && until.isBefore(from)) {
              refreshContent?.call(
                () => dateError = '"Válido até" precisa ser depois do início',
              );
              return;
            }

            final maxText = maxUsesCtrl.text.trim();
            Navigator.pop(
              context,
              CouponModel(
                id: editing?.id ?? '',
                code: codeCtrl.text.trim().toUpperCase(),
                description: descriptionCtrl.text.trim(),
                freeDays: int.parse(daysCtrl.text.trim()),
                validFrom: from,
                validUntil: until,
                maxUses: maxText.isEmpty ? null : int.parse(maxText),
                isActive: isActive,
                ownerId: ownerId,
                createdAt: editing?.createdAt,
                uses: editing?.uses ?? 0,
                activeNow: editing?.activeNow ?? 0,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
