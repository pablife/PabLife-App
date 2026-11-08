import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/repositories/student_repository.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../controllers/sign_up_controller.dart';
import 'widgets/registration_layout.dart';

/// "Comprovante de estudante" (canvas E4). No cadastro, é o passo 2 de 2 e
/// cria a conta no fim. Pelo Perfil (`{'logged': true}`), só envia o arquivo.
class StudentProofPage extends StatefulWidget {
  const StudentProofPage({super.key});

  static const route = '/auth/student-proof';

  static Future<void> openFromProfile() =>
      Get.toNamed<void>(route, arguments: {'logged': true}) ?? Future.value();

  @override
  State<StudentProofPage> createState() => _StudentProofPageState();
}

class _StudentProofPageState extends State<StudentProofPage> {
  late final bool _logged =
      (Get.arguments is Map && (Get.arguments as Map)['logged'] == true) ||
      !Get.isRegistered<SignUpController>();

  // Estado próprio quando vem do Perfil.
  String _institution = '';
  String _course = '';
  Uint8List? _bytes;
  String? _name;
  bool _sending = false;
  bool _touched = false;
  String? _error;

  bool get _ready =>
      _institution.trim().length >= 2 &&
      _course.trim().length >= 2 &&
      _bytes != null;

  Future<void> _pick({bool image = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: image ? FileType.image : FileType.custom,
        allowedExtensions: image ? null : const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      final file = result?.files.firstOrNull;
      if (file == null || file.bytes == null) return;
      if (file.size > 10 * 1024 * 1024) {
        setState(() => _error = 'O arquivo passa de 10 MB. Escolha um menor.');
        return;
      }
      setState(() {
        _bytes = file.bytes;
        _name = file.name;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Não foi possível abrir o arquivo.');
    }
  }

  Future<void> _sendLogged() async {
    if (!_ready) {
      setState(() => _touched = true);
      return;
    }
    setState(() => _sending = true);
    final name = _name!;
    final error = await StudentRepository().submit(
      institution: _institution,
      course: _course,
      bytes: _bytes!,
      extension: name.contains('.') ? name.split('.').last : 'pdf',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Get.back<void>();
    AppSnackbar.to.show('Comprovante enviado! Avisamos quando for aprovado.');
  }

  @override
  Widget build(BuildContext context) {
    if (_logged) {
      return _page(
        institution: _institution,
        course: _course,
        fileName: _name,
        onInstitution: (v) => setState(() => _institution = v),
        onCourse: (v) => setState(() => _course = v),
        onPick: _pick,
        onRemove: () => setState(() {
          _bytes = null;
          _name = null;
        }),
        ready: _ready,
        loading: _sending,
        touched: _touched,
        error: _error,
        primaryLabel: 'Enviar comprovante',
        onPrimary: _sendLogged,
        step: 'Desconto de 10% para estudantes',
      );
    }

    return GetBuilder<SignUpController>(
      builder: (c) => _page(
        institution: c.institution,
        course: c.course,
        fileName: c.proofName,
        onInstitution: c.updateInstitution,
        onCourse: c.updateCourse,
        onPick: c.pickProof,
        onRemove: c.removeProof,
        ready: c.proofReady,
        loading: c.isLoading,
        touched: c.touched,
        error: c.error,
        primaryLabel: 'Enviar e criar conta',
        onPrimary: () => c.createAccount(sendProof: true),
        secondaryLabel: 'Enviar depois',
        onSecondary: c.isLoading
            ? null
            : () => c.createAccount(sendProof: false),
        step: 'Passo 2 de 2',
      ),
    );
  }

  Widget _page({
    required String institution,
    required String course,
    required String? fileName,
    required ValueChanged<String> onInstitution,
    required ValueChanged<String> onCourse,
    required Future<void> Function({bool image}) onPick,
    required VoidCallback onRemove,
    required bool ready,
    required bool loading,
    required bool touched,
    required String? error,
    required String primaryLabel,
    required VoidCallback onPrimary,
    required String step,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    final missing = [
      if (institution.trim().length < 2) 'instituição',
      if (course.trim().length < 2) 'curso',
      if (fileName == null) 'comprovante',
    ];
    return RegistrationLayout(
      title: 'Comprovante de estudante',
      step: step,
      onBack: () => Get.back<void>(),
      fields: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PabColors.lilac,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Text(
                '−10%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: PabColors.lilacText,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Em qualquer plano, depois que aprovarmos seu comprovante. '
                  'Avisamos por notificação.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF1F1B4D),
                  ),
                ),
              ),
            ],
          ),
        ),
        RegField(
          label: 'Instituição de ensino',
          hint: 'Nome da faculdade ou escola',
          initialValue: institution,
          onChanged: onInstitution,
          capitalization: TextCapitalization.words,
        ),
        RegField(
          label: 'Curso',
          hint: 'Ex.: Psicologia',
          initialValue: course,
          onChanged: onCourse,
          capitalization: TextCapitalization.sentences,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Comprovante',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PabColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            RegFilePicker(
              fileName: fileName,
              hint:
                  'Declaração de matrícula ou carteirinha de estudante '
                  'válida, com seu nome e a data.',
              onPick: () => onPick(),
              onTakePhoto: () => onPick(image: true),
              onRemove: onRemove,
            ),
          ],
        ),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 16, color: PabColors.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Seu comprovante é guardado com segurança e usado só para '
                'validar o desconto.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: PabColors.muted,
                ),
              ),
            ),
          ],
        ),
      ],
      footer: [
        RegPrimaryButton(
          label: primaryLabel,
          loading: loading,
          dim: !ready,
          onTap: onPrimary,
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 6),
          RegTextButton(label: secondaryLabel, onTap: onSecondary),
        ],
        if (touched && missing.isNotEmpty)
          RegError('Falta: ${missing.join(', ')}.'),
        if (error != null) RegError(error),
      ],
    );
  }
}
