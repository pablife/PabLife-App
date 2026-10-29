import 'package:flutter/material.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';
import '../../../infra/models/user_model.dart';
import '../finance_report_controller.dart';

class FinanceFilterBar extends StatefulWidget {
  final FinanceReportController controller;

  const FinanceFilterBar({super.key, required this.controller});

  @override
  State<FinanceFilterBar> createState() => _FinanceFilterBarState();
}

class _FinanceFilterBarState extends State<FinanceFilterBar> {
  late final TextEditingController _professionalController;

  List<int> get _years {
    final now = DateTime.now().year;
    return [now - 1, now, now + 1];
  }

  @override
  void initState() {
    super.initState();
    _professionalController = TextEditingController(
      text: widget.controller.professionalNameQuery,
    );
  }

  @override
  void dispose() {
    _professionalController.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() async {
    widget.controller.setProfessionalName(_professionalController.text.trim());
    await widget.controller.applyFilters();
  }

  String _monthLabel(int month) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int>(
                  value: controller.selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Mês',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(_monthLabel(index + 1)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) controller.setMonth(value);
                  },
                ),
              ),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<int>(
                  value: controller.selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Ano',
                    border: OutlineInputBorder(),
                  ),
                  items: _years
                      .map(
                        (year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.setYear(value);
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<ProfessionalType?>(
                  value: controller.selectedProfessionalType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de profissional',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<ProfessionalType?>(
                      value: null,
                      child: Text('Todos os tipos'),
                    ),
                    ...ProfessionalType.values.map(
                      (type) => DropdownMenuItem<ProfessionalType?>(
                        value: type,
                        child: Text(type.displayName),
                      ),
                    ),
                  ],
                  onChanged: controller.setProfessionalType,
                ),
              ),
              SizedBox(
                width: 260,
                child: TextFormField(
                  controller: _professionalController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar profissional pelo nome',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onFieldSubmitted: (_) => _applyFilters(),
                ),
              ),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: controller.goToPreviousMonth,
                  icon: Icon(
                    Icons.history,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.white
                        : AppColors.aqua,
                  ),
                  label: const TextDefault(text: 'Mês anterior'),
                ),
              ),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: controller.goToCurrentMonth,
                  icon: Icon(
                    Icons.today,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.white
                        : AppColors.aqua,
                  ),
                  label: const TextDefault(text: 'Mês atual'),
                ),
              ),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Aplicar filtros'),
                ),
              ),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: controller.isExporting
                      ? null
                      : controller.exportCsv,
                  icon: controller.isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.download_outlined,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.white
                              : AppColors.aqua,
                        ),
                  label: TextDefault(
                    text: controller.isExporting
                        ? 'Exportando...'
                        : 'Exportar CSV',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
