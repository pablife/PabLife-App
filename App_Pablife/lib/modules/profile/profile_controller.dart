import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:brasil_fields/brasil_fields.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../infra/repositories/user_repository.dart';
import '../../infra/services/auth_service.dart';
import '../../infra/services/subscription_service.dart';
import '../../infra/models/user_model.dart';
import '../../infra/models/user_role.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../widgets/design_system/app_dialog.dart';
import 'pages/edit_profile_page.dart';
import 'pages/subscription_page.dart';

class ProfileController extends GetxController with LoaderManagerMixin {
  final UserRepository _userRepository = UserRepository();
  final ProfessionalRepository _professionalRepository =
      ProfessionalRepository();
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  UserModel? currentUser;
  List<ConsultationBalance> consultationBalances = [];
  bool isConsultationBalancesLoading = false;
  bool hasValidSubscription = false;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void onReady() {
    super.onReady();
    reloadProfile();
  }

  Future<void> reloadProfile() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    changeLoading(true);
    isConsultationBalancesLoading = true;
    update();

    try {
      await _authService.reloadCurrentUser();
      await _authService.reloadUserAccessInfo();

      currentUser = _authService.currentUser;

      if (currentUser != null) {
        fullNameController.text = currentUser!.fullName;
        emailController.text = currentUser!.email;
        phoneController.text = currentUser!.phone;

        if (currentUser!.role == UserRole.professional) {
          final professionalResponse = await _professionalRepository
              .getProfessionalByUserId(currentUser!.id!);
          if (professionalResponse.success &&
              professionalResponse.data != null) {
            descriptionController.text =
                professionalResponse.data!.description ?? '';
          }
        }

        consultationBalances = await _subscriptionService
            .getConsultationBalances();
        hasValidSubscription =
            _authService.accessStatus == SubscriptionAccessStatus.active;
      } else {
        consultationBalances = [];
        hasValidSubscription = false;
      }
    } catch (e) {
      consultationBalances = [];
      hasValidSubscription = false;
      debugPrint('Erro ao recarregar perfil: $e');
    } finally {
      isConsultationBalancesLoading = false;
      changeLoading(false);
      update();
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> editProfilePhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        changeLoading(true);

        String? base64Image;
        String fileName = file.name;

        if (kIsWeb) {
          if (file.bytes != null) {
            base64Image = _encodeImageToBase64(file.bytes!);
          }
        } else {
          if (file.path != null) {
            final fileBytes = await File(file.path!).readAsBytes();
            base64Image = _encodeImageToBase64(fileBytes);
          }
        }

        if (base64Image == null) {
          changeLoading(false);
          AppSnackbar.to.show('Erro ao processar imagem');
          return;
        }

        if (currentUser?.id == null) {
          changeLoading(false);
          AppSnackbar.to.show('Erro: ID do usuário não encontrado');
          return;
        }

        final response = await _userRepository.updateProfilePhoto(
          userId: currentUser!.id!,
          imageBase64: base64Image,
          fileName: fileName,
        );

        changeLoading(false);

        if (!response.success) {
          AppSnackbar.to.show(response.message);
        } else {
          AppSnackbar.to.show('Foto atualizada com sucesso');
          await _authService.reloadCurrentUser();
          await _loadUserData();
        }
      }
    } catch (e) {
      changeLoading(false);
      AppSnackbar.to.show('Erro ao selecionar imagem: $e');
    }
  }

  String _encodeImageToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }

  void navigateToEditProfile() {
    Get.toNamed(EditProfilePage.route);
  }

  bool get shouldShowConsultationCard =>
      isConsultationBalancesLoading ||
      consultationBalances.isNotEmpty ||
      hasValidSubscription;

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (currentUser?.id == null) {
      AppSnackbar.to.show('Erro: ID do usuário não encontrado');
      return;
    }

    changeLoading(true);

    final phoneDigits = UtilBrasilFields.removeCaracteres(phoneController.text);

    final response = await _userRepository.updateProfile(
      userId: currentUser!.id!,
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim().toLowerCase(),
      phone: phoneDigits,
      description: currentUser!.role == UserRole.professional
          ? descriptionController.text.trim()
          : null,
    );

    changeLoading(false);

    if (!response.success) {
      AppSnackbar.to.show(response.message);
    } else {
      await _authService.reloadCurrentUser();

      await _loadUserData();
      Get.back();
      AppSnackbar.to.show('Perfil atualizado com sucesso');
    }
  }

  Future<void> navigateToSubscription() async {
    await Get.toNamed(SubscriptionPage.route);
    await reloadProfile();
  }

  Future<void> showLogoutDialog() async {
    final confirmed = await AppDialog.showConfirmation(
      context: Get.context!,
      title: 'Sair da conta',
      message: 'Tem certeza de que deseja sair da sua conta?',
      confirmText: 'Sair',
      cancelText: 'Cancelar',
      confirmButtonColor: const Color(0xFF00343C),
    );

    if (confirmed == true) {
      await _authService.signOut();
      Get.offAllNamed('/onboarding');
    }
  }

  Future<void> showDeleteAccountDialog() async {
    final confirmed = await AppDialog.showConfirmation(
      context: Get.context!,
      title: 'Excluir Conta',
      message:
          'Tem certeza que deseja excluir sua conta? Esta ação é irreversível e todos os seus dados serão perdidos.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      confirmButtonColor: const Color(0xFFFF3395),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

Future<void> _deleteAccount() async {
    if (currentUser?.id == null) {
      AppSnackbar.to.show('Erro: ID do usuário não encontrado');
      return;
    }

    changeLoading(true);

    final response = await _userRepository.deleteAccount(currentUser!.id!);

    changeLoading(false);

    if (!response.success) {
      AppSnackbar.to.show(response.message);
    } else {
      AppSnackbar.to.show('Conta excluída com sucesso');
      Get.offAllNamed('/onboarding');
    }
  }

  void openNotifications() {
    Get.toNamed('/notifications');
  }
}
