import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../infra/models/professional_schedule_slot.dart';

class CalendarRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPatientCalendarCounts({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final rows = await _client.rpc(
        'get_user_calendar_counts',
        params: {'start_date': startDate, 'end_date': endDate},
      );
      log('✅ [CalendarRepository] Dados recebidos: $rows.');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint(
        '❌ [CalendarRepository] Erro ao carregar dados do paciente: $e',
      );
      rethrow;
    }
  }

  Future<List<ProfessionalAppointmentModel>> getProfessionalAppointments({
    required String professionalId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final appointments = await _client
          .from('tb_appointments')
          .select()
          .eq('professional_id', professionalId)
          .gte('start_of_scheduled_window', startDate.toIso8601String())
          .lte('start_of_scheduled_window', endDate.toIso8601String())
          .isFilter('deleted_at', null);

      return (appointments as List).map((apt) {
        final jsonString = jsonEncode(apt);
        return ProfessionalAppointmentModel.fromJson(jsonString);
      }).toList();
    } catch (e) {
      debugPrint(
        '❌ [CalendarRepository] Erro ao carregar appointments do profissional: $e',
      );
      rethrow;
    }
  }

  Future<String?> getProfessionalIdByUserId({required String userId}) async {
    try {
      final result = await _client
          .from('tb_professionals')
          .select('id')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      return result?['id'] as String?;
    } catch (e) {
      debugPrint(
        '❌ [CalendarRepository] Erro ao buscar ID do profissional: $e',
      );
      return null;
    }
  }

  Future<List<ProfessionalScheduleSlot>> getProfessionalAvailableSlots({
    required String professionalId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      debugPrint(
        '🔍 [CalendarRepository] Buscando slots disponíveis: $startDateStr até $endDateStr',
      );

      final responseData = await _client
          .from('vw_professional_available_appointment_slots')
          .select('*')
          .eq('professional_id', professionalId)
          .gte('slot_date', startDateStr)
          .lte('slot_date', endDateStr)
          .eq('is_my_appointment', false)
          .order('slot_start_at', ascending: true);

      final slots = (responseData as List)
          .map(
            (row) => ProfessionalScheduleSlot.fromViewMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      debugPrint(
        '✅ [CalendarRepository] ${slots.length} slots disponíveis encontrados',
      );

      return slots;
    } catch (e) {
      debugPrint('❌ [CalendarRepository] Erro ao buscar slots disponíveis: $e');
      return [];
    }
  }
}
