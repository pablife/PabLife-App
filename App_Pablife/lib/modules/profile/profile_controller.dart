import 'package:pablife/modules/auth/pages/choose_profile_page.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart' show Uint8List;
import '../../shared/utils/photo_resize.dart' show jpgFileName;
import '../../widgets/photo_crop/photo_crop_page.dart';
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
import '../../infra/repositories/consultation_repository.dart';
import '../../infra/repositories/professional_repository.dart';
import '../../infra/models/gender.dart';
import '../../infra/repositories/user_personal_data_repository.dart';
import '../../infra/repositories/user_preferences_repository.dart';
import '../../shared/utils/birth_date.dart';
import '../auth/pages/recovery_password_page.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../widgets/design_system/app_dialog.dart';
import 'pages/edit_profile_page.dart';
import 'pages/delete_account_page.dart';
import 'pages/my_subscription_page.dart';

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
  final TextEditingController preferredNameController = TextEditingController();
  final TextEditingController meetingUrlController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  /// Gênero (opcional) e data como vieram do banco. [_personalData] fica null
  /// se não deu para carregar; aí Salvar não mexe nesses dados.
  Gender? gender;
  UserPersonalData? _personalData;
  String? birthDateError;

  bool get personalDataLoaded => _personalData != null;

  void updateBirthDate(String _) {
    birthDateError = null;
    update();
  }

  void updateGender(Gender? value) {
    gender = value;
    update();
  }

  /// "Receber notificações" (Editar perfil).
  bool pushNotifications = true;
  String? _professionalId;

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
        preferredNameController.text = currentUser!.preferredName ?? '';
        pushNotifications = await UserPreferencesRepository()
            .loadPushNotifications();
        _personalData = await UserPersonalDataRepository().load();
        final birth = _personalData?.birthDate;
        birthDateController.text = birth == null ? '' : BirthDate.format(birth);
        gender = _personalData?.gender;
        birthDateError = null;
        emailController.text = currentUser!.email;
        phoneController.text = currentUser!.phone;

        if (currentUser!.role == UserRole.professional) {
          final professionalResponse = await _professionalRepository
              .getProfessionalByUserId(currentUser!.id!);
          if (professionalResponse.success &&
              professionalResponse.data != null) {
            descriptionController.text =
                professionalResponse.data!.description ?? '';
            _professionalId = professionalResponse.data!.id;
            meetingUrlController.text =
                await ConsultationRepository().myMeetingUrl(_professionalId!) ??
                '';
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
    preferredNameController.dispose();
    meetingUrlController.dispose();
    birthDateController.dispose();
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

        Uint8List? picked;
        if (kIsWeb) {
          picked = file.bytes;
        } else if (file.path != null) {
          picked = await File(file.path!).readAsBytes();
        }

        // A pessoa posiciona a foto no círculo antes de enviar.
        if (picked != null) {
          changeLoading(false);
          final cropped = await Get.to<Uint8List>(
            () => PhotoCropPage(bytes: picked!),
            fullscreenDialog: true,
          );
          if (cropped == null) return;
          changeLoading(true);
          base64Image = _encodeImageToBase64(cropped);
          fileName = jpgFileName(fileName);
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

  /// Liga ou desliga as notificações no celular e guarda a escolha.
  Future<void> setPushNotifications(bool on) async {
    pushNotifications = on;
    update();
    final saved = await UserPreferencesRepository().savePushNotifications(on);
    if (!saved) {
      pushNotifications = !on;
      update();
      AppSnackbar.to.show('Não foi possível salvar agora.');
      return;
    }
    if (!kIsWeb) {
      try {
        if (on) {
          await OneSignal.User.pushSubscription.optIn();
        } else {
          await OneSignal.User.pushSubscription.optOut();
        }
      } catch (e) {
        debugPrint('OneSignal: $e');
      }
    }
  }

  /// "Alterar senha": manda um código por e-mail (mesmo fluxo de "Esqueci").
  void changePassword() {
    Get.toNamed(RecoveryPasswordPage.route, arguments: currentUser?.email);
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

    // Contas antigas podem deixar a data em branco; quem já informou não apaga.
    final birthText = birthDateController.text.trim();
    if (personalDataLoaded &&
        (birthText.isNotEmpty || _personalData!.birthDate != null)) {
      birthDateError = BirthDate.errorFor(birthText);
      if (birthDateError != null) {
        update();
        return;
      }
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
      preferredName: preferredNameController.text,
    );

    String? linkError;
    if (response.success && _professionalId != null) {
      linkError = await ConsultationRepository().saveMeetingUrl(
        _professionalId!,
        meetingUrlController.text,
      );
    }

    final birthDate = BirthDate.parse(birthText);
    if (response.success &&
        linkError == null &&
        personalDataLoaded &&
        (birthDate != _personalData!.birthDate ||
            gender != _personalData!.gender)) {
      final saved = await UserPersonalDataRepository().save(
        birthDate: birthDate,
        gender: gender,
      );
      if (!saved) {
        changeLoading(false);
        AppSnackbar.to.show(
          'Não foi possível salvar a data de nascimento e o gênero. '
          'Tente de novo.',
        );
        return;
      }
    }

    changeLoading(false);
    if (linkError != null) {
      AppSnackbar.to.show(linkError);
      return;
    }

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
    await Get.toNamed(MySubscriptionPage.route);
    await reloadProfile();
  }

  /// Conta de profissional também entra como usuário.
  bool get canSwitchProfile => _authService.isProfessionalAccount;

  /// Profissional na área dele (não entrando como usuário).
  bool get isProfessionalView =>
      _authService.isProfessionalAccount && !_authService.isActingAsUser;

  String get switchProfileLabel => _authService.isActingAsUser
      ? 'Entrar como profissional'
      : 'Entrar como usuário';

  void switchProfile() => Get.offAllNamed(ChooseProfilePage.route);

  Future<void> showLogoutDialog() async {
    final confirmed = await AppDialog.showConfirmation(
      context: Get.context!,
      title: 'Sair da conta',
      message: 'Tem certeza de que deseja sair da sua conta?',
      confirmText: 'Sair',
      cancelText: 'Cancelar',
    );

    if (confirmed == true) {
      await _authService.signOut();
      Get.offAllNamed(ChooseProfilePage.route);
    }
  }

  /// "Excluir conta" (canvas S3): confirma digitando EXCLUIR.
  Future<void> showDeleteAccountDialog() async {
    await Get.toNamed(DeleteAccountPage.route);
  }

  Future<void> deleteAccount() async {
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
      Get.offAllNamed(ChooseProfilePage.route);
    }
  }

  void openNotifications() {
    Get.toNamed('/notifications');
  }
}
