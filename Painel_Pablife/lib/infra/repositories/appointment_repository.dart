import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/appointment_model.dart';

class AppointmentRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  /// Buscar todos os agendamentos
  FStrautilsResponse<List<AppointmentModel>> getAllAppointments() async {
    return tryThis<List<AppointmentModel>>(
      () async {
        final response = await _client
            .from('tb_appointments')
            .select()
            .isFilter('deleted_at', null)
            .order('start_of_scheduled_window', ascending: false);

        final list = (response as List)
            .map((item) => AppointmentModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getAllAppointments(),
      action: 'buscar agendamentos',
    );
  }

  /// Buscar agendamentos com paginação
  /// [offset] - posição inicial
  /// [limit] - quantidade de itens a carregar
  FStrautilsResponse<List<AppointmentModel>> getAppointmentsPaginated({
    required int offset,
    int limit = 15,
  }) async {
    return tryThis<List<AppointmentModel>>(
      () async {
        final response = await _client
            .from('tb_appointments')
            .select()
            .isFilter('deleted_at', null)
            .order('start_of_scheduled_window', ascending: false)
            .range(offset, offset + limit - 1);

        final list = (response as List)
            .map((item) => AppointmentModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getAppointmentsPaginated(offset: offset, limit: limit),
      action: 'buscar agendamentos paginados',
    );
  }

  /// Buscar agendamentos por profissional
  FStrautilsResponse<List<AppointmentModel>> getAppointmentsByProfessional(
    String professionalId,
  ) async {
    return tryThis<List<AppointmentModel>>(
      () async {
        final response = await _client
            .from('tb_appointments')
            .select()
            .eq('professional_id', professionalId)
            .isFilter('deleted_at', null)
            .order('start_of_scheduled_window', ascending: false);

        final list = (response as List)
            .map((item) => AppointmentModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getAppointmentsByProfessional(professionalId),
      action: 'buscar agendamentos por profissional',
    );
  }

  /// Buscar agendamentos por usuário
  FStrautilsResponse<List<AppointmentModel>> getAppointmentsByUser(
    String userId,
  ) async {
    return tryThis<List<AppointmentModel>>(
      () async {
        final response = await _client
            .from('tb_appointments')
            .select()
            .eq('scheduled_by', userId)
            .isFilter('deleted_at', null)
            .order('start_of_scheduled_window', ascending: false);

        final list = (response as List)
            .map((item) => AppointmentModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getAppointmentsByUser(userId),
      action: 'buscar agendamentos por usuário',
    );
  }

  /// Buscar agendamentos por período
  FStrautilsResponse<List<AppointmentModel>> getAppointmentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return tryThis<List<AppointmentModel>>(
      () async {
        final response = await _client
            .from('tb_appointments')
            .select()
            .gte('start_of_scheduled_window', startDate.toIso8601String())
            .lte('start_of_scheduled_window', endDate.toIso8601String())
            .isFilter('deleted_at', null)
            .order('start_of_scheduled_window', ascending: true);

        final list = (response as List)
            .map((item) => AppointmentModel.fromMap(item))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () =>
          getAppointmentsByDateRange(startDate: startDate, endDate: endDate),
      action: 'buscar agendamentos por período',
    );
  }

  /// Contar agendamentos
  FStrautilsResponse<int> getTotalAppointments() async {
    return tryThis<int>(
      () async {
        final response = await _client
            .from('tb_appointments')
            .select('id')
            .isFilter('deleted_at', null)
            .count(CountOption.exact);

        return StrautilsResponse.success(response.count);
      },
      tryAgain: () => getTotalAppointments(),
      action: 'contar agendamentos',
    );
  }
}
