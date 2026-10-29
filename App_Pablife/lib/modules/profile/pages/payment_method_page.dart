import 'package:flutter/material.dart';
import '../../../widgets/design_system/app_bar_default.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../shared/themes/app_colors.dart';

class PaymentMethodPage extends StatelessWidget {
  const PaymentMethodPage({super.key});

  static const route = '/profile/payment-method';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00343C),
      appBar: const AppBarDefault(),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFC1CDFF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(39),
            topRight: Radius.circular(39),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.credit_card_outlined,
                size: 80,
                color: AppColors.second.withAlpha(128),
              ),
              const SizedBox(height: 24),
              TextDefault(
                'Método de Pagamento',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.second,
              ),
              const SizedBox(height: 12),
              TextDefault(
                'Em desenvolvimento',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.second.withAlpha(153),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
