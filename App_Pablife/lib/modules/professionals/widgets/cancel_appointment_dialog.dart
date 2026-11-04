import 'package:pablife/shared/themes/app_palette.dart';
import 'package:flutter/material.dart';
import '../../../widgets/design_system/app_dialog.dart';
import '../../../infra/models/professional_with_user_model.dart';

class CancelAppointmentDialog {
  static Future<bool?> show(
    BuildContext context,
    ProfessionalWithUserModel professional,
  ) {
    return AppDialog.showConfirmation(
      context: context,
      title: 'Cancelar Agendamento',
      message:
          'Deseja realmente cancelar o agendamento com ${professional.user.fullName} para ${professional.appointmentFormatted}?',
      confirmText: 'Cancelar',
      cancelText: 'Voltar',
      confirmButtonColor: const AppColor(0xFF00343C),
      cancelButtonColor: const AppColor(0xFF0C8DA1),
    );
  }
}
