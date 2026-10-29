import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/professional_monthly_transfer_model.dart';
import '../models/user_model.dart';

class FinanceReportRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<ProfessionalMonthlyTransfer>>
  getProfessionalMonthlyTransfers({
    required int month,
    required int year,
    int page = 1,
    int pageSize = 20,
    ProfessionalType? professionalType,
    String? professionalName,
  }) async {
    return tryThis<List<ProfessionalMonthlyTransfer>>(
      () async {
        final params = <String, dynamic>{
          'p_month': month,
          'p_year': year,
          'p_page': page,
          'p_page_size': pageSize,
        };

        if (professionalType != null) {
          params['p_type'] = professionalType.value;
        }

        if (professionalName != null && professionalName.trim().isNotEmpty) {
          params['p_professional_name'] = professionalName.trim();
        }

        final response = await _client.rpc(
          'get_professional_monthly_transfers',
          params: params,
        );

        final list = (response as List)
            .map(
              (item) => ProfessionalMonthlyTransfer.fromMap(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        return StrautilsResponse.success(list);
      },
      tryAgain: () => getProfessionalMonthlyTransfers(
        month: month,
        year: year,
        page: page,
        pageSize: pageSize,
        professionalType: professionalType,
        professionalName: professionalName,
      ),
      action: 'buscar repasses de profissionais',
    );
  }
}
