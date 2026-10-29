import 'package:flutter/material.dart';

class DashboardReportsPage extends StatelessWidget {
  const DashboardReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            Text(
              'View your statistics and reports',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
