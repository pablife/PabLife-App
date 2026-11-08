import 'dart:typed_data';

import 'package:brasil_fields/brasil_fields.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/professional_type.dart';
import '../../../infra/models/user_model.dart';
import '../../../infra/models/user_role.dart';
import '../../../infra/models/user_status.dart';
import '../../../infra/repositories/student_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../entry_visual.dart';
import '../pages/account_created_page.dart';
import '../pages/professional_profile_page.dart';
import '../pages/student_proof_page.dart';

/// Cadastro (canvas E3–E5 e, para profissional, PC1). Guarda os dados até a
/// conta ser criada: no fim de "Criar conta" ou do comprovante de estudante.
class SignUpController extends GetxController with LoaderManagerMixin {
  final AuthService _authService = AuthService.instance;

  String email = '';
  String password = '';
  String fullName = '';
  String phone = '';
  String cpfDocument = '';
  String accountType = 'cliente';
  bool termsAccepted = false;

  /// "Sou estudante" e o comprovante (passo 2).
  bool isStudent = false;
  String institution = '';
  String course = '';
  Uint8List? proofBytes;
  String? proofName;

  /// Profissional: profissão e registro no conselho.
  ProfessionalType? profession;
  String councilNumber = '';
  String councilRegion = '';

  /// Mostra o que falta depois da primeira tentativa de continuar.
  bool touched = false;
  String? error;

  bool get isProfessional => accountType == 'profissional';

  @override
  void onInit() {
    super.onInit();
    email = (Get.arguments as String? ?? '').trim().toLowerCase();
    if (AuthService.instance.entryChoice == 'professional') {
      accountType = 'profissional';
    }
  }

  void _set(VoidCallback change) {
    change();
    error = null;
    update();
  }

  void updateFullName(String v) => _set(() => fullName = v.trim());
  void updateEmail(String v) => _set(() => email = v.trim().toLowerCase());
  void updatePhone(String v) =>
      _set(() => phone = UtilBrasilFields.removeCaracteres(v));
  void updateCpfDocument(String v) =>
      _set(() => cpfDocument = UtilBrasilFields.removeCaracteres(v));
  void updatePassword(String v) => _set(() => password = v);
  void updateTerms(bool v) => _set(() => termsAccepted = v);
  void toggleStudent() => _set(() => isStudent = !isStudent);
  void updateInstitution(String v) => _set(() => institution = v);
  void updateCourse(String v) => _set(() => course = v);
  void updateProfession(ProfessionalType v) => _set(() => profession = v);
  void updateCouncilNumber(String v) => _set(() => councilNumber = v.trim());
  void updateCouncilRegion(String v) => _set(() => councilRegion = v.trim());

  // ------------------------------------------------------------ validação

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// O que ainda falta no primeiro passo (vazio = pode seguir).
  List<String> get missing => [
    if (fullName.length < 3) 'nome',
    if (!_emailPattern.hasMatch(email)) 'e-mail',
    if (phone.length < 10) 'WhatsApp',
    if (!UtilBrasilFields.isCPFValido(cpfDocument)) 'CPF',
    if (password.length < 8) 'senha',
    if (isProfessional && profession == null) 'profissão',
    if (isProfessional && councilNumber.length < 3) 'registro',
    if (!termsAccepted) 'aceite dos termos',
  ];

  String get missingText => 'Falta preencher: ${missing.join(', ')}.';

  bool get proofReady =>
      institution.trim().length >= 2 &&
      course.trim().length >= 2 &&
      proofBytes != null;

  // ---------------------------------------------------------- navegação

  /// Botão do primeiro passo.
  Future<void> continueFirstStep() async {
    if (missing.isNotEmpty) {
      touched = true;
      update();
      return;
    }
    if (isProfessional) {
      Get.toNamed(
        ProfessionalProfilePage.route,
        arguments: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'cpfDocument': cpfDocument,
          'professionalType': profession!.value,
          'councilNumber': councilNumber,
          'councilRegion': councilRegion,
        },
      );
      return;
    }
    if (isStudent) {
      Get.toNamed(StudentProofPage.route);
      return;
    }
    await createAccount(sendProof: false);
  }

  Future<void> pickProof({bool image = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: image ? FileType.image : FileType.custom,
        allowedExtensions: image ? null : const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      final file = result?.files.firstOrNull;
      if (file == null || file.bytes == null) return;
      if (file.size > 10 * 1024 * 1024) {
        _set(() => error = 'O arquivo passa de 10 MB. Escolha um menor.');
        return;
      }
      _set(() {
        proofBytes = file.bytes;
        proofName = file.name;
      });
    } catch (e) {
      _set(() => error = 'Não foi possível abrir o arquivo.');
    }
  }

  void removeProof() => _set(() {
    proofBytes = null;
    proofName = null;
  });

  /// Cria a conta de usuário. Com [sendProof], envia também o comprovante.
  Future<void> createAccount({required bool sendProof}) async {
    if (isLoading) return;
    if (sendProof && !proofReady) {
      touched = true;
      update();
      return;
    }
    changeLoading(true);
    error = null;
    update();
    try {
      final success = await _authService.signUpWithEmail(
        email,
        password,
        UserModel(
          fullName: fullName,
          email: email,
          phone: phone,
          cpfDocument: cpfDocument,
          termsAccepted: termsAccepted,
          role: UserRole.user,
          status: UserStatus.active,
          professionalType: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (!success) {
        error =
            _authService.lastSignUpError ??
            'Não foi possível criar a conta. Tente de novo.';
        return;
      }
      await EntryVisual.onAccountCreated(professional: false);

      String? proofError;
      if (sendProof) {
        final name = proofName!;
        proofError = await StudentRepository().submit(
          institution: institution,
          course: course,
          bytes: proofBytes!,
          extension: name.contains('.') ? name.split('.').last : 'pdf',
        );
      }
      Get.offAllNamed(
        AccountCreatedPage.route,
        arguments: {
          'proofSent': sendProof && proofError == null,
          'proofError': proofError,
        },
      );
    } catch (e) {
      error = 'Não foi possível criar a conta. Tente de novo.';
    } finally {
      changeLoading(false);
      update();
    }
  }
}
