import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/themes/app_palette.dart';
import '../../../../shared/themes/pab_colors.dart';
import '../../../../shared/utils/wide_layout.dart';

/// Fundo da página atrás do cartão no computador (canvas "Web · E3").
const _page = AppColor.pair(0xFFE9EEEE, 0xFFF6EEF3);

/// Moldura das telas de cadastro (canvas E3–E5 e PC1–PC3): voltar, título,
/// passo, barra de progresso opcional, conteúdo rolável e botões embaixo.
/// No celular ocupa a tela; no computador vira um cartão no centro.
class RegistrationLayout extends StatelessWidget {
  final String title;
  final String? step;
  final VoidCallback? onBack;

  /// Barra de progresso: passo atual (1, 2 ou 3) de [totalSteps].
  final int? progress;
  final int totalSteps;
  final List<Widget> fields;
  final List<Widget> footer;
  final double maxWidth;

  const RegistrationLayout({
    super.key,
    required this.title,
    required this.fields,
    required this.footer,
    this.step,
    this.onBack,
    this.progress,
    this.totalSteps = 3,
    this.maxWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (onBack != null) ...[
                RegBackButton(onTap: onBack!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: PabColors.ink,
                      ),
                    ),
                    if (step != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        step!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PabColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (progress != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Semantics(
              label: 'Passo $progress de $totalSteps',
              child: Row(
                children: [
                  for (var i = 1; i <= totalSteps; i++) ...[
                    if (i > 1) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: i <= progress!
                              ? PabColors.ink
                              : PabColors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                fields[i],
              ],
            ],
          ),
        ),
        if (footer.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: PabColors.card,
              border: Border(top: BorderSide(color: PabColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: footer,
              ),
            ),
          ),
      ],
    );

    if (!wide) {
      return Scaffold(
        backgroundColor: PabColors.background,
        body: SafeArea(bottom: false, child: content),
      );
    }

    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 860),
              child: Container(
                decoration: BoxDecoration(
                  color: PabColors.background,
                  border: Border.all(color: PabColors.line),
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const RegBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Voltar',
      child: Material(
        color: PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: PabColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back, size: 20, color: PabColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Campo com rótulo em cima (canvas: 50px de altura, cantos de 14px).
class RegField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter> formatters;
  final List<String> autofillHints;
  final bool obscure;
  final Widget? suffix;
  final String? helper;
  final String? error;
  final bool enabled;
  final TextCapitalization capitalization;

  const RegField({
    super.key,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.formatters = const [],
    this.autofillHints = const [],
    this.obscure = false,
    this.suffix,
    this.helper,
    this.error,
    this.enabled = true,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

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
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          autofillHints: autofillHints,
          obscureText: obscure,
          textCapitalization: capitalization,
          autocorrect: false,
          style: const TextStyle(fontSize: 16, color: PabColors.ink),
          cursorColor: PabColors.ink,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: PabColors.muted),
            filled: true,
            fillColor: PabColors.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            suffixIcon: suffix,
            enabledBorder: border(
              error != null ? PabColors.error : PabColors.lineStrong,
            ),
            disabledBorder: border(PabColors.line),
            focusedBorder: border(
              error != null ? PabColors.error : PabColors.accent,
              2,
            ),
          ),
        ),
        if (error != null || helper != null) ...[
          const SizedBox(height: 6),
          Text(
            error ?? helper!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: error != null ? FontWeight.w600 : FontWeight.w500,
              color: error != null ? PabColors.error : PabColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Caixa de marcar dos termos.
class RegCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;
  final bool boxed;

  const RegCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.text,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: boxed ? PabColors.card : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: boxed
              ? const BorderSide(color: PabColors.line)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.all(boxed ? 12 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: value ? PabColors.accent : PabColors.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: PabColors.accent, width: 2),
                  ),
                  child: value
                      ? const Icon(Icons.check, size: 15, color: PabColors.ink)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: PabColors.ink,
                    ),
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

/// Botão principal (canvas: 54px, cantos de 16px, cor de destaque).
class RegPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool dim;
  final Widget? icon;

  const RegPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.dim = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          backgroundColor: PabColors.accent,
          foregroundColor: PabColors.ink,
          disabledBackgroundColor: PabColors.accent,
          disabledForegroundColor: PabColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: PabColors.ink,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class RegTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const RegTextButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        foregroundColor: PabColors.accentText,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Mensagem de erro embaixo do botão.
class RegError extends StatelessWidget {
  final String text;

  const RegError(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: PabColors.error,
          ),
        ),
      ),
    );
  }
}

/// Área de envio de arquivo: vazia (dois botões) ou com o arquivo escolhido.
class RegFilePicker extends StatelessWidget {
  final String? fileName;
  final String hint;
  final VoidCallback onPick;
  final VoidCallback? onTakePhoto;
  final VoidCallback onRemove;
  final bool dashed;

  const RegFilePicker({
    super.key,
    required this.fileName,
    required this.hint,
    required this.onPick,
    required this.onRemove,
    this.onTakePhoto,
    this.dashed = true,
  });

  @override
  Widget build(BuildContext context) {
    final name = fileName;
    if (name != null) {
      final ext = name.split('.').last.toUpperCase();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PabColors.card,
          border: Border.all(color: PabColors.accent),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PabColors.soft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ext.length > 4 ? 'ARQ' : ext,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: PabColors.accentText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Pronto para enviar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PabColors.accentText,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remover arquivo',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18, color: PabColors.error),
            ),
          ],
        ),
      );
    }

    Widget button(String label, IconData icon, VoidCallback onTap) => Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: PabColors.ink,
          backgroundColor: PabColors.background,
          side: const BorderSide(color: PabColors.lineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.accent, width: dashed ? 2 : 1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF2E4446),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onTakePhoto != null) ...[
                button('Tirar foto', Icons.photo_camera_outlined, onTakePhoto!),
                const SizedBox(width: 8),
              ],
              button('Escolher arquivo', Icons.upload_file, onPick),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'JPG, PNG ou PDF, até 10 MB',
            style: TextStyle(fontSize: 12, color: PabColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Moldura das telas com topo próprio (consulta, sala de espera): ocupa a
/// tela no celular e vira um cartão no centro no computador.
class PabCardFrame extends StatelessWidget {
  final Widget child;
  final Color background;
  final double maxWidth;

  const PabCardFrame({
    super.key,
    required this.child,
    this.background = PabColors.background,
    this.maxWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWideLayout(context)) {
      return Scaffold(backgroundColor: background, body: child);
    }
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 860),
              child: Container(
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: PabColors.line),
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
