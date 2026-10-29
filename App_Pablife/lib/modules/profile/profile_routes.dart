import 'package:get/get.dart';

import '../../infra/repositories/payment_repository.dart';
import 'controllers/checkout_controller.dart';
import 'controllers/subscription_controller.dart';
import 'pages/checkout_page.dart';
import 'pages/edit_profile_page.dart';
import 'pages/payment_method_page.dart';
import 'pages/subscription_page.dart';
import 'profile_controller.dart';
import 'profile_page.dart';

final profileRoutes = [
  GetPage(
    name: ProfilePage.route,
    page: () => const ProfilePage(),
    bindings: [BindingsBuilder.put(ProfileController.new)],
  ),
  GetPage(name: EditProfilePage.route, page: () => const EditProfilePage()),
  GetPage(name: PaymentMethodPage.route, page: () => const PaymentMethodPage()),
  GetPage(
    name: SubscriptionPage.route,
    page: () => const SubscriptionPage(),

    bindings: [
      BindingsBuilder.put(SubscriptionController.new),
      BindingsBuilder.put(PaymentRepository.new),
    ],
  ),
  GetPage(
    name: CheckoutPage.route,
    page: () => const CheckoutPage(),
    bindings: [BindingsBuilder.put(CheckoutController.new)],
  ),
];
