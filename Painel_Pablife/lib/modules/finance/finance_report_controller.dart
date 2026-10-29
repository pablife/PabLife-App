import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../infra/models/professional_monthly_transfer_model.dart';
import '../../infra/models/user_model.dart';
import '../../infra/repositories/finance_report_repository.dart';
import '../../shared/enums/view_mode.dart';
import '../../shared/mixins/loader_manager.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../shared/utils/file_exporter.dart';

class FinanceReportController extends GetxController with LoaderManagerMixin {
  final FinanceReportRepository _financeRepository = FinanceReportRepository();
  static const List<String> _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  int selectedMonth = 1;
  int selectedYear = DateTime.now().year;
  ProfessionalType? selectedProfessionalType;
  String professionalNameQuery = '';

  int currentPage = 1;
  final int pageSize = 20;
  bool isExporting = false;
  bool _hasMorePages = true;

  List<ProfessionalMonthlyTransfer> transfers = [];

  ViewMode viewMode = ViewMode.list;

  int get totalPages {
    // Se não há mais páginas, a página atual é a última
    if (!_hasMorePages) return currentPage;
    // Caso contrário, assumimos que há pelo menos mais uma página
    return currentPage + 1;
  }

  bool get hasPreviousPage => currentPage > 1;
  bool get hasNextPage => _hasMorePages;

  @override
  void onInit() {
    super.onInit();

    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    selectedMonth = previousMonth.month;
    selectedYear = previousMonth.year;

    _loadTransfers();
  }

  Future<void> _loadTransfers({int page = 1}) async {
    changeLoading(true);
    currentPage = page;

    try {
      final response = await _financeRepository.getProfessionalMonthlyTransfers(
        month: selectedMonth,
        year: selectedYear,
        page: page,
        pageSize: pageSize,
        professionalType: selectedProfessionalType,
        professionalName: professionalNameQuery.trim().isEmpty
            ? null
            : professionalNameQuery,
      );

      transfers = response.data ?? [];
      // Se retornou menos itens que o pageSize, é a última página
      _hasMorePages = transfers.length >= pageSize;
    } catch (e) {
      AppSnackbar.to.error('Erro ao carregar relatórios: $e');
    } finally {
      changeLoading(false);
      update();
    }
  }

  Future<void> refreshData() => _loadTransfers(page: currentPage);

  Future<void> applyFilters() async {
    currentPage = 1;
    _loadTransfers(page: 1);
  }

  /// Vai para a página anterior
  Future<void> goToPreviousPage() async {
    if (!hasPreviousPage) return;
    await _loadTransfers(page: currentPage - 1);
  }

  /// Vai para a próxima página
  Future<void> goToNextPage() async {
    if (!hasNextPage) return;
    await _loadTransfers(page: currentPage + 1);
  }

  /// Vai para uma página específica
  Future<void> goToPage(int page) async {
    if (page < 1 || page == currentPage) return;
    await _loadTransfers(page: page);
  }

  Future<void> goToPreviousMonth() async {
    final date = DateTime(selectedYear, selectedMonth - 1, 1);
    selectedMonth = date.month;
    selectedYear = date.year;
    update();
    await applyFilters();
  }

  Future<void> goToCurrentMonth() async {
    final date = DateTime.now();
    selectedMonth = date.month;
    selectedYear = date.year;
    update();
    await applyFilters();
  }

  void setMonth(int month) {
    selectedMonth = month;
    update();
  }

  void setYear(int year) {
    selectedYear = year;
    update();
  }

  void setProfessionalType(ProfessionalType? type) {
    selectedProfessionalType = type;
    update();
  }

  void setProfessionalName(String value) {
    professionalNameQuery = value;
    update();
  }

  void setViewMode(ViewMode mode) {
    viewMode = mode;
    update();
  }

  List<ProfessionalMonthlyTransfer> get sortedTransfers {
    final list = [...transfers];
    list.sort((a, b) => b.totalTransferAmount.compareTo(a.totalTransferAmount));
    return list;
  }

  int get totalAppointments =>
      transfers.fold(0, (acc, item) => acc + item.appointmentsCount);

  int get totalDistinctUsers =>
      transfers.fold(0, (acc, item) => acc + item.distinctUsersCount);

  double get totalTransferAmount =>
      transfers.fold(0, (acc, item) => acc + item.totalTransferAmount);

  String get currentPeriodLabel =>
      '${_monthNames[selectedMonth - 1]} $selectedYear';

  String formatCurrency(double value) => 'R\$ ${value.toStringAsFixed(2)}';

  Future<void> exportCsv() async {
    if (isExporting) return;

    isExporting = true;
    update();

    try {
      final data = await _fetchAllPagesForExport();

      if (data.isEmpty) {
        AppSnackbar.to.warning('Nenhum dado para exportar neste período');
        return;
      }

      final csv = _buildCsv(data);
      final filename =
          'relatorio_financeiro_${selectedYear}_${selectedMonth.toString().padLeft(2, '0')}.csv';

      await saveCsvFile(csv, filename);
      AppSnackbar.to.success('Relatório exportado com sucesso');
    } on UnsupportedError {
      AppSnackbar.to.warning(
        'Exportação disponível apenas no navegador/web no momento.',
      );
    } catch (e) {
      AppSnackbar.to.error('Falha ao exportar: $e');
    } finally {
      isExporting = false;
      update();
    }
  }

  Future<List<ProfessionalMonthlyTransfer>> _fetchAllPagesForExport() async {
    const int maxPageSize = 50;
    int page = 1;
    final List<ProfessionalMonthlyTransfer> results = [];

    while (true) {
      final response = await _financeRepository.getProfessionalMonthlyTransfers(
        month: selectedMonth,
        year: selectedYear,
        page: page,
        pageSize: maxPageSize,
        professionalType: selectedProfessionalType,
        professionalName: professionalNameQuery.trim().isEmpty
            ? null
            : professionalNameQuery,
      );

      final data = response.data ?? [];
      results.addAll(data);

      if (data.length < maxPageSize) {
        break;
      }

      page++;
    }

    return results;
  }

  String _buildCsv(List<ProfessionalMonthlyTransfer> items) {
    final buffer = StringBuffer();
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final monthFormatter = DateFormat('MM/yyyy');

    buffer.writeln(
      'Profissional,Tipo,Mes,Periodo inicial,Periodo final,Consultas concluidas,Pacientes unicos,Total repasse (R\$),Calculado em',
    );

    for (final item in items) {
      final sanitizedName = item.professionalName.replaceAll('"', '""');
      buffer.writeln(
        [
          '"$sanitizedName"',
          item.professionalType.displayName,
          monthFormatter.format(item.monthStart),
          dateFormatter.format(item.periodStart),
          dateFormatter.format(item.periodEnd),
          item.appointmentsCount,
          item.distinctUsersCount,
          item.totalTransferAmount.toStringAsFixed(2),
          dateFormatter.format(item.calculatedAt),
        ].join(','),
      );
    }

    return buffer.toString();
  }
}
