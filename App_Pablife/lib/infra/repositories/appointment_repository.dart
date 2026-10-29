import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';

import '../models/professional_appointment_model.dart';
import '../models/professional_schedule_slot.dart';

class AppointmentRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<ProfessionalAppointmentModel>>
  getProfessionalAppointments({
    required String professionalId,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    return tryThis(() async {
      debugPrint('🔍 [AppointmentRepo] Buscando consultas');
      debugPrint('🔍 [AppointmentRepo] Professional: $professionalId');
      if (startAt != null) debugPrint('🔍 [AppointmentRepo] StartAt: $startAt');
      if (endAt != null) debugPrint('🔍 [AppointmentRepo] EndAt: $endAt');

      PostgrestFilterBuilder query = _client
          .from('tb_appointments')
          .select('''
            id,
            scheduled_by,
            professional_id,
            appointment_time_id,
            start_of_scheduled_window,
            end_of_scheduled_window,
            started_at,
            finished_at,
            status,
            created_at,
            updated_at,
            appointment_time:tb_appointment_times!inner(
              due_at,
              start_time_at,
              finish_time_at,
              timezone
            ),
            patient:tb_users!tb_appointments_scheduled_by_fkey(
              id,
              full_name,
              image_url,
              phone
            ),
            professional:tb_professionals!inner(
              id,
              user_id,
              type,
              user:tb_users!inner(
                id,
                full_name,
                image_url,
                phone
              )
            )
          ''')
          .eq('professional_id', professionalId)
          .isFilter('deleted_at', null);

      if (startAt != null) {
        query = query.gte(
          'appointment_time.due_at',
          startAt.toUtc().toIso8601String(),
        );
      }

      if (endAt != null) {
        query = query.lt(
          'appointment_time.due_at',
          endAt.toUtc().toIso8601String(),
        );
      }

      final List<dynamic> responseData;
      try {
        responseData = await query;
        debugPrint(
          '✅ [AppointmentRepo] Retornou ${responseData.length} consultas',
        );
        if (responseData.isNotEmpty) {
          debugPrint(
            '📋 [AppointmentRepo] Primeira consulta: ${responseData.first}',
          );
        }
      } on PostgrestException catch (e) {
        debugPrint('❌ [AppointmentRepo] Erro: ${e.message}');
        return StrautilsResponse.success(<ProfessionalAppointmentModel>[]);
      }

      final appointments = responseData
          .map(
            (row) => ProfessionalAppointmentModel.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      appointments.sort((a, b) => a.startAt.compareTo(b.startAt));

      debugPrint(
        '✅ [AppointmentRepo] ${appointments.length} consultas parseadas',
      );

      return StrautilsResponse.success(appointments);
    }, action: 'buscar consultas do profissional.');
  }

  FStrautilsResponse<List<ProfessionalScheduleSlot>>
  getProfessionalAvailability({
    required String professionalId,
    required DateTime date,
  }) {
    return tryThis(() async {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint('🔍 [AppointmentRepo] Buscando horários disponíveis');
      debugPrint('🔍 [AppointmentRepo] Professional: $professionalId');
      debugPrint('🔍 [AppointmentRepo] Date: $date');
      debugPrint(
        '🔍 [AppointmentRepo] StartOfDay UTC: ${startOfDay.toUtc().toIso8601String()}',
      );
      debugPrint(
        '🔍 [AppointmentRepo] EndOfDay UTC: ${endOfDay.toUtc().toIso8601String()}',
      );

      PostgrestFilterBuilder query =
          _client
                  .from('tb_appointment_times')
                  .select('''
            id,
            professional_id,
            due_at,
            start_time_at,
            finish_time_at,
            timezone
          ''')
                  .eq('professional_id', professionalId)
                  .isFilter('deleted_at', null)
              as PostgrestFilterBuilder;

      query = query.gte('due_at', startOfDay.toUtc().toIso8601String());
      query = query.lt('due_at', endOfDay.toUtc().toIso8601String());

      final orderedQuery = query.order('due_at', ascending: true);

      final List<dynamic> responseData;
      try {
        responseData = await orderedQuery;
        debugPrint(
          '✅ [AppointmentRepo] Retornou ${responseData.length} horários',
        );
        if (responseData.isNotEmpty) {
          debugPrint(
            '📋 [AppointmentRepo] Primeiro horário: ${responseData.first}',
          );
        }
      } on PostgrestException catch (e) {
        debugPrint('❌ [AppointmentRepo] Erro: ${e.message}');
        return StrautilsResponse.success(<ProfessionalScheduleSlot>[]);
      }

      final slots = responseData
          .map(
            (row) => ProfessionalScheduleSlot.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      debugPrint('✅ [AppointmentRepo] ${slots.length} horários parseados');

      return StrautilsResponse.success(slots);
    }, action: 'buscar horários disponíveis do profissional.');
  }

  FStrautilsResponse<List<ProfessionalScheduleSlot>>
  getProfessionalAvailabilityRange({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  }) {
    return tryThis(() async {
      PostgrestFilterBuilder query =
          _client
                  .from('tb_appointment_times')
                  .select('''
            id,
            professional_id,
            due_at,
            start_time_at,
            finish_time_at,
            timezone
          ''')
                  .eq('professional_id', professionalId)
                  .isFilter('deleted_at', null)
              as PostgrestFilterBuilder;

      query = query.gte('due_at', start.toUtc().toIso8601String());
      query = query.lt('due_at', end.toUtc().toIso8601String());

      final orderedQuery = query.order('due_at', ascending: true);

      final List<dynamic> responseData;
      try {
        responseData = await orderedQuery;
      } on PostgrestException {
        return StrautilsResponse.success(<ProfessionalScheduleSlot>[]);
      }

      final slots = responseData
          .map(
            (row) => ProfessionalScheduleSlot.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      return StrautilsResponse.success(slots);
    }, action: 'buscar horários disponíveis no período.');
  }

  FStrautilsResponse<List<ProfessionalScheduleSlot>>
  getProfessionalSlotsFromView({
    required String professionalId,
    required DateTime date,
  }) {
    return tryThis(() async {
      debugPrint('🔍 [AppointmentRepo] Buscando slots da view otimizada');
      debugPrint('🔍 [AppointmentRepo] Professional: $professionalId');
      debugPrint('🔍 [AppointmentRepo] Date (original): $date');

      final localDate = DateTime(date.year, date.month, date.day);
      final dateStr = DateFormat('yyyy-MM-dd').format(localDate);
      final endDate = localDate.add(const Duration(days: 180));
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      debugPrint('🔍 [AppointmentRepo] Date (normalizada): $localDate');
      debugPrint('🔍 [AppointmentRepo] Date string: $dateStr');

      final query = _client
          .from('vw_professional_available_appointment_slots')
          .select('*')
          .eq('professional_id', professionalId)
          .gte('slot_date', dateStr)
          .lte('slot_date', endDateStr)
          .eq('is_my_appointment', false)
          .order('slot_start_at', ascending: true);

      final List<dynamic> responseData;
      try {
        responseData = await query;
        debugPrint(
          '✅ [AppointmentRepo] Retornou ${responseData.length} slots da view',
        );
        if (responseData.isNotEmpty) {
          debugPrint(
            '📋 [AppointmentRepo] Primeiro slot: ${responseData.first}',
          );
        }
      } on PostgrestException catch (e) {
        debugPrint('❌ [AppointmentRepo] Erro: ${e.message}');
        return StrautilsResponse.success(<ProfessionalScheduleSlot>[]);
      }

      final slots = responseData
          .map(
            (row) => ProfessionalScheduleSlot.fromViewMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      debugPrint('✅ [AppointmentRepo] ${slots.length} slots parseados');

      return StrautilsResponse.success(slots);
    }, action: 'buscar slots da view otimizada.');
  }

  FStrautilsResponse<List<ProfessionalScheduleSlot>>
  getProfessionalSlotsFromViewForDay({
    required String professionalId,
    required DateTime date,
  }) {
    return tryThis(() async {
      debugPrint('🔍 [AppointmentRepo] Buscando slots da view (dia único)');
      debugPrint('🔍 [AppointmentRepo] Professional: $professionalId');
      debugPrint('🔍 [AppointmentRepo] Date (original): $date');

      final localDate = DateTime(date.year, date.month, date.day);
      final dateStr = DateFormat('yyyy-MM-dd').format(localDate);

      debugPrint('🔍 [AppointmentRepo] Date (normalizada): $localDate');
      debugPrint('🔍 [AppointmentRepo] Date string: $dateStr');

      final query = _client
          .from('vw_professional_available_appointment_slots')
          .select('*')
          .eq('professional_id', professionalId)
          .eq('slot_date', dateStr)
          .eq('is_my_appointment', false)
          .order('slot_start_at', ascending: true);

      final List<dynamic> responseData;
      try {
        responseData = await query;
        debugPrint(
          '✅ [AppointmentRepo] Retornou ${responseData.length} slots da view',
        );
        if (responseData.isNotEmpty) {
          debugPrint(
            '📋 [AppointmentRepo] Primeiro slot: ${responseData.first}',
          );
        }
      } on PostgrestException catch (e) {
        debugPrint('❌ [AppointmentRepo] Erro: ${e.message}');
        return StrautilsResponse.success(<ProfessionalScheduleSlot>[]);
      }

      final slots = responseData
          .map(
            (row) => ProfessionalScheduleSlot.fromViewMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      debugPrint('✅ [AppointmentRepo] ${slots.length} slots parseados');

      return StrautilsResponse.success(slots);
    }, action: 'buscar slots da view (dia único).');
  }

  FStrautilsResponse<List<ProfessionalAppointmentModel>>
  getPatientAppointments({
    required String patientId,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    return tryThis(() async {
      debugPrint('🔍 [AppointmentRepo] Buscando consultas do paciente');
      debugPrint('🔍 [AppointmentRepo] Patient: $patientId');
      if (startAt != null) debugPrint('🔍 [AppointmentRepo] StartAt: $startAt');
      if (endAt != null) debugPrint('🔍 [AppointmentRepo] EndAt: $endAt');

      PostgrestFilterBuilder query = _client
          .from('tb_appointments')
          .select('''
            id,
            scheduled_by,
            professional_id,
            appointment_time_id,
            start_of_scheduled_window,
            end_of_scheduled_window,
            started_at,
            finished_at,
            status,
            created_at,
            updated_at,
            appointment_time:tb_appointment_times!inner(
              due_at,
              start_time_at,
              finish_time_at,
              timezone
            ),
            professional:tb_professionals!inner(
              id,
              user_id,
              type,
              user:tb_users!inner(
                id,
                full_name,
                image_url,
                phone
              )
            )
          ''')
          .eq('scheduled_by', patientId)
          .isFilter('deleted_at', null);

      if (startAt != null) {
        query = query.gte(
          'appointment_time.due_at',
          startAt.toUtc().toIso8601String(),
        );
      }

      if (endAt != null) {
        query = query.lt(
          'appointment_time.due_at',
          endAt.toUtc().toIso8601String(),
        );
      }

      final List<dynamic> responseData;
      try {
        responseData = await query;
        debugPrint(
          '✅ [AppointmentRepo] Retornou ${responseData.length} consultas do paciente',
        );
        if (responseData.isNotEmpty) {
          debugPrint(
            '📋 [AppointmentRepo] Primeira consulta: ${responseData.first}',
          );
        }
      } on PostgrestException catch (e) {
        debugPrint('❌ [AppointmentRepo] Erro: ${e.message}');
        return StrautilsResponse.success(<ProfessionalAppointmentModel>[]);
      }

      final appointments = responseData.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        // Transform professional data to match patient structure
        if (map['professional'] != null) {
          final professional = map['professional'] as Map<String, dynamic>;
          final user = professional['user'] as Map<String, dynamic>?;
          if (user != null) {
            map['patient'] = {
              'id': user['id'],
              'full_name': user['full_name'],
              'image_url': user['image_url'],
              'phone': user['phone'],
            };
            map['professional_type'] = professional['type'];
          }
        }
        return ProfessionalAppointmentModel.fromMap(map);
      }).toList();

      appointments.sort((a, b) => a.startAt.compareTo(b.startAt));

      debugPrint(
        '✅ [AppointmentRepo] ${appointments.length} consultas do paciente parseadas',
      );

      return StrautilsResponse.success(appointments);
    }, action: 'buscar consultas do paciente.');
  }

  FStrautilsResponse<ProfessionalAppointmentModel?> getAppointmentById(
    String appointmentId,
  ) {
    return tryThis(() async {
      debugPrint(
        '🔍 [AppointmentRepo] Buscando consulta por ID: $appointmentId',
      );

      final response = await _client
          .from('tb_appointments')
          .select('''
            id,
            scheduled_by,
            professional_id,
            appointment_time_id,
            start_of_scheduled_window,
            end_of_scheduled_window,
            started_at,
            finished_at,
            status,
            created_at,
            updated_at,
            appointment_time:tb_appointment_times!inner(
              due_at,
              start_time_at,
              finish_time_at,
              timezone
            ),
            patient:tb_users!tb_appointments_scheduled_by_fkey(
              id,
              full_name,
              image_url,
              phone
            ),
            professional:tb_professionals!inner(
              id,
              user_id,
              type,
              user:tb_users!inner(
                id,
                full_name,
                image_url,
                phone
              )
            )
          ''')
          .eq('id', appointmentId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ [AppointmentRepo] Consulta não encontrada');
        return StrautilsResponse.success(null);
      }

      final appointment = ProfessionalAppointmentModel.fromMap(
        Map<String, dynamic>.from(response as Map),
      );

      debugPrint('✅ [AppointmentRepo] Consulta encontrada: ${appointment.id}');

      return StrautilsResponse.success(appointment);
    }, action: 'buscar consulta por ID.');
  }

  Future<void> markAppointmentAsCompleted(String appointmentId) async {
    await _client
        .from('tb_appointments')
        .update({'finished_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', appointmentId);
  }

  Future<void> startAppointment(String appointmentId) async {
    await _client
        .from('tb_appointments')
        .update({'started_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', appointmentId);
  }

  Future<void> markNoShow(String appointmentId) async {
    await _client
        .from('tb_appointments')
        .update({'status': 'no_show'})
        .eq('id', appointmentId);
  }

  Future<void> completeAppointment(String appointmentId) async {
    final now = DateTime.now();
    await _client
        .from('tb_appointments')
        .update({
          'status': 'completed',
          'finished_at': now.toUtc().toIso8601String(),
        })
        .eq('id', appointmentId);
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _client
        .from('tb_appointments')
        .update({'status': 'cancelled'})
        .eq('id', appointmentId);
  }

  FStrautilsResponse<List<ProfessionalAppointmentModel>>
  getProfessionalActiveAppointments({required String professionalId}) {
    return tryThis(() async {
      debugPrint(
        '🔍 [AppointmentRepo] Buscando consultas ativas do profissional',
      );
      debugPrint('🔍 [AppointmentRepo] Professional: $professionalId');

      final query = _client
          .from('tb_appointments')
          .select('''
            id,
            scheduled_by,
            professional_id,
            appointment_time_id,
            start_of_scheduled_window,
            end_of_scheduled_window,
            started_at,
            finished_at,
            status,
            created_at,
            updated_at,
            appointment_time:tb_appointment_times!inner(
              due_at,
              start_time_at,
              finish_time_at,
              timezone
            ),
            patient:tb_users!tb_appointments_scheduled_by_fkey(
              id,
              full_name,
              image_url,
              phone
            ),
            professional:tb_professionals!inner(
              id,
              user_id,
              type,
              user:tb_users!inner(
                id,
                full_name,
                image_url,
                phone
              )
            )
          ''')
          .eq('professional_id', professionalId)
          .eq('status', 'scheduled')
          .isFilter('deleted_at', null)
          .order('start_of_scheduled_window', ascending: true);

      final List<dynamic> responseData;
      try {
        responseData = await query;
        debugPrint(
          '✅ [AppointmentRepo] Retornou ${responseData.length} consultas ativas',
        );
      } on PostgrestException catch (e) {
        debugPrint('❌ [AppointmentRepo] Erro: ${e.message}');
        return StrautilsResponse.success(<ProfessionalAppointmentModel>[]);
      }

      final appointments = responseData
          .map(
            (row) => ProfessionalAppointmentModel.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      return StrautilsResponse.success(appointments);
    }, action: 'buscar consultas ativas do profissional.');
  }

  FStrautilsResponse<List<ProfessionalAppointmentModel>>
  getPatientActiveAppointments({required String patientId}) {
    return tryThis(() async {
      debugPrint('🔍 [AppointmentRepo] Buscando consultas ativas do paciente');
      debugPrint('🔍 [AppointmentRepo] Patient: $patientId');

      final query = _client
          .from('tb_appointments')
          .select('''
            id,
            scheduled_by,
            professional_id,
            appointment_time_id,
            finished_at,
            status,
            start_of_scheduled_window,
            end_of_scheduled_window,
            appointment_time:tb_appointment_times!inner(
              due_at,
              start_time_at,
              finish_time_at,
              timezone
            ),
            professional:tb_professionals!inner(
              id,
              user_id,
              type,
              user:tb_users!inner(
                id,
                full_name,
                image_url,
                phone
              )
            )
          ''')
          .eq('scheduled_by', patientId)
          .eq('status', 'scheduled')
          .isFilter('deleted_at', null)
          .order('start_of_scheduled_window', ascending: true);

      final List<dynamic> responseData;
      try {
        responseData = await query;
        debugPrint(
          '✅ [AppointmentRepo] Retornou ${responseData.length} consultas ativas do paciente',
        );
      } on PostgrestException catch (e) {
        debugPrint('❌ [AppointmentRepo] Erro: ${e.message}');
        return StrautilsResponse.success(<ProfessionalAppointmentModel>[]);
      }

      final appointments = responseData.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        // Transform professional data to match patient structure
        if (map['professional'] != null) {
          final professional = map['professional'] as Map<String, dynamic>;
          final user = professional['user'] as Map<String, dynamic>?;
          if (user != null) {
            map['patient'] = {
              'id': user['id'],
              'full_name': user['full_name'],
              'image_url': user['image_url'],
              'phone': user['phone'],
            };
            map['professional_type'] = professional['type'];
          }
        }
        return ProfessionalAppointmentModel.fromMap(map);
      }).toList();

      return StrautilsResponse.success(appointments);
    }, action: 'buscar consultas ativas do paciente.');
  }
}
