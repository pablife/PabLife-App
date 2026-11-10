import 'package:flutter/material.dart';

import '../../../shared/themes/pab_colors.dart';
import '../../auth/pages/widgets/registration_layout.dart';

/// Peças das telas "Nova tarefa", "Nova meta" e "Nova anotação" no visual
/// da repaginação (mesmos campos de Editar perfil e do cadastro).

OutlineInputBorder _border(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: PabColors.ink,
        ),
      ),
    );
  }
}

/// Campo que abre o calendário ou o relógio ao tocar.
class EditorPickerField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback? onTap;
  final IconData icon;

  const EditorPickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        TextField(
          controller: controller,
          readOnly: true,
          enabled: enabled,
          onTap: onTap,
          style: const TextStyle(fontSize: 16, color: PabColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: PabColors.muted),
            filled: true,
            fillColor: enabled ? PabColors.card : PabColors.background,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            suffixIcon: Icon(icon, size: 20, color: PabColors.muted),
            enabledBorder: _border(PabColors.lineStrong),
            disabledBorder: _border(PabColors.line),
            focusedBorder: _border(PabColors.accent, 2),
          ),
        ),
      ],
    );
  }
}

/// Texto longo (estratégia da meta).
class EditorTextArea extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const EditorTextArea({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 16, color: PabColors.ink),
          cursorColor: PabColors.ink,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: PabColors.muted),
            filled: true,
            fillColor: PabColors.card,
            contentPadding: const EdgeInsets.all(14),
            enabledBorder: _border(PabColors.lineStrong),
            focusedBorder: _border(PabColors.accent, 2),
          ),
        ),
      ],
    );
  }
}

/// Prioridade em três botões: Baixa, Média e Alta.
class EditorPriorityPicker extends StatelessWidget {
  final List<Map<String, String>> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const EditorPriorityPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('Prioridade'),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: EditorChip(
                  label: options[i]['label']!,
                  selected: value == options[i]['value'],
                  onTap: () => onChanged(options[i]['value']),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Botão de escolha (prioridade e dias da semana).
class EditorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Sem margem lateral (dias da semana, sete numa linha).
  final bool compact;

  const EditorChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? PabColors.ink : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? PabColors.ink : PabColors.lineStrong,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: selected ? PabColors.onInk : PabColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha com chave liga/desliga dentro de um cartão branco.
class EditorSwitchCard extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? child;

  const EditorSwitchCard({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PabColors.ink,
                      ),
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PabColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: PabColors.card,
                activeTrackColor: PabColors.accent,
                inactiveThumbColor: PabColors.card,
                inactiveTrackColor: PabColors.track,
                trackOutlineColor: const WidgetStatePropertyAll(
                  PabColors.lineStrong,
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 6),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

/// Rodapé com "Cancelar" (contornado) e "Salvar" (cor de destaque).
class EditorFooter extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool loading;

  const EditorFooter({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: loading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 54),
              foregroundColor: PabColors.ink,
              side: const BorderSide(color: PabColors.lineStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RegPrimaryButton(
            label: 'Salvar',
            loading: loading,
            onTap: onSave,
          ),
        ),
      ],
    );
  }
}

/// Calendário e relógio claros, nas cores da repaginação.
Widget pabPickerTheme(BuildContext context, Widget? child) {
  final base = Theme.of(context);
  return Theme(
    data: base.copyWith(
      colorScheme: ColorScheme.light(
        primary: PabColors.ink,
        onPrimary: PabColors.onInk,
        secondary: PabColors.accent,
        onSecondary: PabColors.ink,
        surface: PabColors.card,
        onSurface: PabColors.ink,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: PabColors.card),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PabColors.accentText,
          textStyle: const TextStyle(
            fontFamily: pabFontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
    child: child!,
  );
}
