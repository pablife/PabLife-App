import 'package:flutter/material.dart';
import '../../../infra/models/professional_with_user_model.dart';
import '../../../widgets/design_system/empty_state_widget.dart';
import 'professional_tile.dart';

class ProfessionalsListWidget extends StatelessWidget {
  final bool isLoading;
  final List<ProfessionalWithUserModel> professionals;
  final bool showOnlyScheduled;
  final void Function(ProfessionalWithUserModel) onProfessionalTap;
  final void Function(ProfessionalWithUserModel) onCalendarTap;

  const ProfessionalsListWidget({
    super.key,
    required this.isLoading,
    required this.professionals,
    required this.showOnlyScheduled,
    required this.onProfessionalTap,
    required this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00343C)),
      );
    }

    if (professionals.isEmpty) {
      return EmptyStateWidget(
        icon: showOnlyScheduled ? Icons.event_busy : Icons.search_off,
        title: showOnlyScheduled
            ? 'Nenhum agendamento'
            : 'Nenhum profissional encontrado',
        description: showOnlyScheduled
            ? 'Você ainda não tem horários marcados com profissionais'
            : 'Tente buscar por outro termo ou categoria',
        iconSize: 64,
        titleFontSize: 18,
        titleFontWeight: FontWeight.w600,
        descriptionFontSize: 14,
        descriptionFontWeight: FontWeight.w400,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 100),
      itemCount: professionals.length,
      itemBuilder: (context, index) {
        final professional = professionals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ProfessionalTile(
            professional: professional,
            onTap: () => onProfessionalTap(professional),
            onCalendarTap: () => onCalendarTap(professional),
          ),
        );
      },
    );
  }
}
