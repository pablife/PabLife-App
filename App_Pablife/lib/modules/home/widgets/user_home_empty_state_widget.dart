import 'package:flutter/material.dart';
import '../../../widgets/design_system/empty_state_widget.dart';

class UserHomeEmptyStateWidget extends StatelessWidget {
  const UserHomeEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: EmptyStateWidget(
          icon: Icons.dashboard_outlined,
          title: 'Nada por aqui ainda',
          description:
              'Comece criando tarefas e metas para acompanhar seu progresso e alcançar seus objetivos.',
        ),
      ),
    );
  }
}
