import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../infra/models/professional_type.dart';
import '../../../infra/models/user_model.dart';
import '../../../infra/models/user_role.dart';
import '../../../infra/models/user_status.dart';
import '../../../infra/repositories/user_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../dashboard/dashboard_page.dart';
import '../../waiting_approval/pages/waiting_approval_page.dart';
import '../entry_visual.dart';

/// "Documento do conselho" (canvas PC2): carteira do conselho (obrigatória)
/// e diploma ou certificado (opcional). Cria a conta de profissional e vai
/// para "Cadastro em análise".
///
/// Quem já tem conta de usuário e quer virar profissional
/// (`addToExisting`) preenche aqui também profissão e registro.
class ProfessionalProfileController extends GetxController
    with LoaderManagerMixin {
  final UserRepository _userRepository = UserRepository();

  String email = '';
  String password = '';
  String fullName = '';
  String phone = '';
  String cpfDocument = '';
  ProfessionalType? professionalType;
  String councilNumber = '';
  String councilRegion = '';
  bool termsAccepted = false;

  bool addToExistingAccount = false;

  Uint8List? cardBytes;
  String? cardName;
  Uint8List? diplomaBytes;
  String? diplomaName;

  bool touched = false;
  String? error;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    email = args['email'] ?? '';
    password = args['password'] ?? '';
    fullName = args['fullName'] ?? '';
    phone = args['phone'] ?? '';
    cpfDocument = args['cpfDocument'] ?? '';
    final type = args['professionalType'] as String?;
    professionalType = type == null ? null : ProfessionalType.fromString(type);
    councilNumber = args['councilNumber'] ?? '';
    councilRegion = args['councilRegion'] ?? '';
    addToExistingAccount = args['addToExisting'] == true;
    termsAccepted = !addToExistingAccount;
  }

  void _set(VoidCallback change) {
    change();
    error = null;
    update();
  }

  void updateProfessionalType(ProfessionalType v) =>
      _set(() => professionalType = v);
  void updateCouncilNumber(String v) => _set(() => councilNumber = v.trim());
  void updateCouncilRegion(String v) => _set(() => councilRegion = v.trim());
  void updateTerms(bool v) => _set(() => termsAccepted = v);

  List<String> get missing => [
    if (professionalType == null) 'profissão',
    if (councilNumber.length < 3) 'registro',
    if (!termsAccepted) 'aceite dos termos',
    if (cardBytes == null) 'carteira do conselho',
  ];

  Future<({Uint8List bytes, String name})?> _pick({bool image = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: image ? FileType.image : FileType.custom,
        allowedExtensions: image ? null : const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      final file = result?.files.firstOrNull;
      if (file == null || file.bytes == null) return null;
      if (file.size > 10 * 1024 * 1024) {
        _set(() => error = 'O arquivo passa de 10 MB. Escolha um menor.');
        return null;
      }
      return (bytes: file.bytes!, name: file.name);
    } catch (_) {
      _set(() => error = 'Não foi possível abrir o arquivo.');
      return null;
    }
  }

  Future<void> pickCard({bool image = false}) async {
    final file = await _pick(image: image);
    if (file == null) return;
    _set(() {
      cardBytes = file.bytes;
      cardName = file.name;
    });
  }

  Future<void> pickDiploma({bool image = false}) async {
    final file = await _pick(image: image);
    if (file == null) return;
    _set(() {
      diplomaBytes = file.bytes;
      diplomaName = file.name;
    });
  }

  void removeCard() => _set(() {
    cardBytes = null;
    cardName = null;
  });

  void removeDiploma() => _set(() {
    diplomaBytes = null;
    diplomaName = null;
  });

  String _ext(String name) =>
      name.contains('.') ? name.split('.').last.toLowerCase() : 'pdf';

  Future<void> completeProfile() async {
    if (isLoading) return;
    if (missing.isNotEmpty) {
      touched = true;
      update();
      return;
    }
    changeLoading(true);
    error = null;
    update();

    final documentBase64 = base64Encode(cardBytes!);
    final documentFileName =
        'validation-document-${DateTime.now().millisecondsSinceEpoch}.${_ext(cardName!)}';

    try {
      if (addToExistingAccount) {
        final response = await _userRepository.addProfessionalProfile(
          professionalType: professionalType!.value,
          documentBase64: documentBase64,
          documentFileName: documentFileName,
        );
        if (!response.success) {
          error = response.message;
          return;
        }
        final auth = AuthService.instance;
        await auth.reloadCurrentUser();
        await auth.setActingAsUser(false);
      } else {
        final response = await _userRepository.signUpWithEmailAndDocument(
          UserModel(
            fullName: fullName,
            email: email,
            phone: phone,
            cpfDocument: cpfDocument,
            termsAccepted: true,
            role: UserRole.professional,
            status: UserStatus.active,
            professionalType: professionalType,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          password,
          documentBase64,
          documentFileName,
        );
        if (!response.success) {
          error = response.message;
          return;
        }
        final signedIn = await AuthService.instance.signInWithEmail(
          email,
          password,
        );
        if (!signedIn) {
          error =
              'Conta criada, mas não conseguimos entrar. Entre com seu '
              'e-mail e senha.';
          Get.offAllNamed('/auth/email');
          return;
        }
        await EntryVisual.onAccountCreated(professional: true);
      }

      await _saveCouncilAndDiploma();
      Get.offAllNamed(WaitingApprovalPage.route);
    } catch (e) {
      error = 'Não foi possível enviar seu cadastro. Tente de novo.';
    } finally {
      changeLoading(false);
      update();
    }
  }

  /// Registro do conselho e diploma: gravados depois da conta criada, pela
  /// própria pessoa (as regras do banco só deixam mexer no próprio cadastro).
  Future<void> _saveCouncilAndDiploma() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    String? diplomaPath;
    if (diplomaBytes != null) {
      final ext = _ext(diplomaName!);
      final path = '$uid/diploma-${DateTime.now().millisecondsSinceEpoch}.$ext';
      try {
        await client.storage
            .from('professional-documents')
            .uploadBinary(
              path,
              diplomaBytes!,
              fileOptions: FileOptions(
                contentType: ext == 'pdf'
                    ? 'application/pdf'
                    : ext == 'png'
                    ? 'image/png'
                    : 'image/jpeg',
              ),
            );
        diplomaPath = path;
      } catch (e) {
        debugPrint('Diploma não enviado: $e');
      }
    }

    try {
      await client
          .from('tb_professionals')
          .update({
            'council_number': councilNumber,
            'council_region': councilRegion.isEmpty ? null : councilRegion,
            if (diplomaPath != null)
              'specialization_document_path': diplomaPath,
          })
          .eq('user_id', uid);
    } catch (e) {
      debugPrint('Registro do conselho não gravado: $e');
    }
  }

  void goBack() {
    if (addToExistingAccount) {
      Get.offAllNamed(DashboardPage.route);
    } else {
      Get.back();
    }
  }
}
