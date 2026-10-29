import 'package:flutter/material.dart';

import '../../../widgets/design_system/pagination_widget.dart' as design_system;
import '../finance_report_controller.dart';

class PaginationWidget extends StatelessWidget {
  final FinanceReportController controller;

  const PaginationWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return design_system.PaginationWidget(
      currentPage: controller.currentPage,
      totalPages: controller.totalPages,
      onPreviousPage: controller.goToPreviousPage,
      onNextPage: controller.goToNextPage,
    );
  }
}

