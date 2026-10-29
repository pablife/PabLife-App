import 'dart:convert';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pablife/modules/waiting_approval/pages/waiting_approval_page.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../infra/models/professional_type.dart';
import '../../../infra/models/user_model.dart';
import '../../../infra/models/user_role.dart';
import '../../../infra/models/user_status.dart';
import '../../../infra/repositories/user_repository.dart';
import '../../../infra/services/auth_service.dart';

class ProfessionalProfileController extends GetxController
    with LoaderManagerMixin {
  final UserRepository _userRepository = UserRepository();

  String email = '';
  String password = '';
  String fullName = '';
  String phone = '';
  String cpfDocument = '';
  String description = '';
  ProfessionalType professionalType = ProfessionalType.nutritionist;
  String? documentBase64;
  String? documentFileName;
  String? profileImageBase64;
  String? profileImageFileName;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    email = args['email'] ?? '';
    password = args['password'] ?? '';
    fullName = args['fullName'] ?? '';
    phone = args['phone'] ?? '';
    cpfDocument = args['cpfDocument'] ?? '';
  }

  void updateProfessionalType(ProfessionalType value) {
    professionalType = value;
    update();
  }

  void updateDocumentBase64(String? base64, String? fileName) {
    documentBase64 = base64;
    documentFileName = fileName;
    update();
  }

  void updateProfileImageBase64(String? base64, String? fileName) {
    profileImageBase64 = base64;
    profileImageFileName = fileName;
    update();
  }

  Future<void> selectDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
        withData: true,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        await _convertDocumentToBase64(file);
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao selecionar arquivo: ${e.toString()}');
    }
  }

  Future<void> selectProfileImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        await _convertProfileImageToBase64(file);
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao selecionar imagem: ${e.toString()}');
    }
  }

  Future<void> _convertDocumentToBase64(PlatformFile file) async {
    try {
      changeLoading(true);

      if (file.bytes == null || file.bytes!.isEmpty) {
        AppSnackbar.to.show(
          'Erro ao ler arquivo. Por favor, tente selecionar o arquivo novamente.',
        );
        return;
      }

      final base64String = base64Encode(file.bytes!);
      final extension = file.extension ?? 'pdf';
      final fileName =
          'validation-document-${DateTime.now().millisecondsSinceEpoch}.$extension';

      updateDocumentBase64(base64String, fileName);
    } catch (e) {
      AppSnackbar.to.show('Erro ao processar arquivo: ${e.toString()}');
    } finally {
      changeLoading(false);
    }
  }

  Future<void> _convertProfileImageToBase64(PlatformFile file) async {
    try {
      changeLoading(true);

      if (file.bytes == null || file.bytes!.isEmpty) {
        AppSnackbar.to.show(
          'Erro ao ler imagem. Por favor, tente selecionar a imagem novamente.',
        );
        return;
      }

      final base64String = base64Encode(file.bytes!);
      final extension = file.extension ?? 'jpg';
      final fileName =
          'profile-image-${DateTime.now().millisecondsSinceEpoch}.$extension';

      updateProfileImageBase64(base64String, fileName);
    } catch (e) {
      AppSnackbar.to.show('Erro ao processar imagem: ${e.toString()}');
    } finally {
      changeLoading(false);
    }
  }

  Future<void> completeProfile() async {
    if (documentBase64 == null ||
        documentBase64!.isEmpty ||
        documentFileName == null ||
        documentFileName!.isEmpty) {
      AppSnackbar.to.show('Por favor, selecione seu documento de validação');
      return;
    }

    changeLoading(true);

    try {
      final userData = UserModel(
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
      );

      final response = await _userRepository.signUpWithEmailAndDocument(
        userData,
        password,
        documentBase64!,
        documentFileName!,
        profileImageBase64: profileImageBase64,
        profileImageFileName: profileImageFileName,
        description: description,
      );

      if (response.success) {
        final authService = AuthService.instance;
        final signInSuccess = await authService.signInWithEmail(
          email,
          password,
        );

        if (signInSuccess) {
          AppSnackbar.to.show('Conta profissional criada com sucesso!');
          Get.offAllNamed(WaitingApprovalPage.route);
        } else {
          AppSnackbar.to.show(
            'Conta criada, mas falha ao fazer login. Por favor, faça login manualmente.',
          );
          Get.offAllNamed('/auth/email');
        }
      } else {
        AppSnackbar.to.show(response.message);
      }
    } catch (e) {
      AppSnackbar.to.show('Erro ao criar conta: ${e.toString()}');
    } finally {
      changeLoading(false);
    }
  }

  void goBack() {
    Get.back();
  }
}
