import 'package:flutter/material.dart';

class DashboardSchedulePage extends StatelessWidget {
  const DashboardSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schedule', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            Text(
              'Manage your appointments',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
