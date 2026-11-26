import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../infra/models/gender.dart';
import '../../../../shared/themes/pab_colors.dart';
import 'registration_layout.dart';

/// "Data de nascimento" (dd/mm/aaaa), no cadastro e em Editar perfil.
class BirthDateField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? error;
  final bool enabled;

  const BirthDateField({
    super.key,
    required this.onChanged,
    this.controller,
    this.initialValue,
    this.error,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return RegField(
      label: 'Data de nascimento',
      hint: 'dd/mm/aaaa',
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.birthday],
      formatters: [
        FilteringTextInputFormatter.digitsOnly,
        DataInputFormatter(),
      ],
      error: error,
      helper:
          'O Pablife é para maiores de 18 anos. As profissionais não '
          'veem esta data.',
    );
  }
}

/// "Gênero (opcional)": tocar de novo na opção marcada desmarca.
class GenderField extends StatelessWidget {
  final Gender? value;
  final ValueChanged<Gender?> onChanged;
  final bool enabled;

  const GenderField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => RegPillChoice<Gender>(
    label: 'Gênero (opcional)',
    options: Gender.values,
    labelOf: (g) => g.label,
    value: value,
    onChanged: onChanged,
    enabled: enabled,
  );
}

/// Escolha única em botões de pílula (Gênero, "Você é"). Com [allowClear],
/// tocar de novo na opção marcada desmarca.
class RegPillChoice<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final String Function(T) labelOf;
  final T? value;
  final ValueChanged<T?> onChanged;
  final bool enabled;
  final bool allowClear;
  final String? helper;

  const RegPillChoice({
    super.key,
    required this.label,
    required this.options,
    required this.labelOf,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.allowClear = true,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: PabColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final o in options) _option(o)],
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: PabColors.muted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _option(T option) {
    final on = value == option;
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? PabColors.ink : PabColors.card,
        shape: StadiumBorder(
          side: BorderSide(color: on ? PabColors.ink : PabColors.lineStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () => onChanged(on && allowClear ? null : option)
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  labelOf(option),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : PabColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
