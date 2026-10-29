import 'package:get/get.dart';
import 'pages/email_input_page.dart';
import 'controllers/email_input_controller.dart';
import 'pages/password_page.dart';
import 'controllers/password_controller.dart';
import 'pages/sign_up_page.dart';
import 'controllers/sign_up_controller.dart';
import 'pages/professional_profile_page.dart';
import 'controllers/professional_profile_controller.dart';
import 'pages/recovery_password_page.dart';
import 'controllers/recovery_password_controller.dart';
import 'pages/recovery_password_code_page.dart';
import 'controllers/recovery_password_code_controller.dart';

final authRoutes = [
  GetPage(
    name: EmailInputPage.route,
    page: () => const EmailInputPage(),
    bindings: [BindingsBuilder.put(EmailInputController.new)],
  ),
  GetPage(
    name: PasswordPage.route,
    page: () => const PasswordPage(),
    bindings: [BindingsBuilder.put(PasswordController.new)],
  ),
  GetPage(
    name: SignUpPage.route,
    page: () => const SignUpPage(),
    bindings: [BindingsBuilder.put(SignUpController.new)],
  ),
  GetPage(
    name: ProfessionalProfilePage.route,
    page: () => const ProfessionalProfilePage(),
    bindings: [BindingsBuilder.put(ProfessionalProfileController.new)],
  ),
  GetPage(
    name: RecoveryPasswordPage.route,
    page: () => const RecoveryPasswordPage(),
    bindings: [BindingsBuilder.put(RecoveryPasswordController.new)],
  ),
  GetPage(
    name: RecoveryPasswordCodePage.route,
    page: () => const RecoveryPasswordCodePage(),
    bindings: [BindingsBuilder.put(RecoveryPasswordCodeController.new)],
  ),
];
