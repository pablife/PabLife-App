import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';

import '../models/patient_record_model.dart';

class PatientRecordRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<PatientRecordModel>> getPatientRecords({
    required String patientId,
    PatientRecordType? type,
  }) {
    return tryThis(() async {
      debugPrint('🔍 [PatientRecordRepo] Buscando registros do paciente');
      debugPrint('🔍 [PatientRecordRepo] PatientId: $patientId');
      if (type != null) {
        debugPrint('🔍 [PatientRecordRepo] Type: ${type.value}');
      }

      dynamic query = _client
          .from('tb_patient_records')
          .select('*')
          .eq('patient_id', patientId)
          .isFilter('deleted_at', null);

      if (type != null) {
        query = query.eq('type', type.value);
      }

      query = query.order('created_at', ascending: false);

      final List<dynamic> responseData;
      try {
        responseData = await query;
        debugPrint(
          '✅ [PatientRecordRepo] Retornou ${responseData.length} registros',
        );
      } on PostgrestException catch (e) {
        debugPrint('❌ [PatientRecordRepo] Erro: ${e.message}');
        return StrautilsResponse.success(<PatientRecordModel>[]);
      }

      final records = responseData
          .map(
            (row) => PatientRecordModel.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      return StrautilsResponse.success(records);
    }, action: 'buscar registros do paciente.');
  }

  FStrautilsResponse<String?> getPatientIdByAppointment(String appointmentId) {
    return tryThis(() async {
      debugPrint(
        '🔍 [PatientRecordRepo] Buscando patient_id pela consulta $appointmentId',
      );

      try {
        final response = await _client
            .from('tb_patients')
            .select('id')
            .eq('appointment_id', appointmentId)
            .maybeSingle();

        if (response == null) {
          debugPrint('⚠️ [PatientRecordRepo] Nenhum paciente encontrado');
          return StrautilsResponse.success(null);
        }

        final patientId = response['id']?.toString();
        debugPrint('✅ [PatientRecordRepo] patient_id encontrado: $patientId');
        return StrautilsResponse.success(patientId);
      } on PostgrestException catch (e) {
        debugPrint('❌ [PatientRecordRepo] Erro: ${e.message}');
        return StrautilsResponse.success(null);
      }
    }, action: 'buscar paciente da consulta.');
  }

  FStrautilsResponse<PatientRecordModel> createPatientRecord({
    required String patientId,
    required PatientRecordType type,
    required String title,
    required String description,
  }) {
    return tryThis(() async {
      final response = await _client
          .from('tb_patient_records')
          .insert({
            'patient_id': patientId,
            'type': type.value,
            'title': title,
            'description': description,
          })
          .select()
          .single();

      return StrautilsResponse.success(PatientRecordModel.fromMap(response));
    }, action: 'criar registro do paciente.');
  }

  FStrautilsResponse<PatientRecordModel> updatePatientRecord({
    required String recordId,
    String? title,
    String? description,
  }) {
    return tryThis(() async {
      final Map<String, dynamic> updateData = {};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;

      final response = await _client
          .from('tb_patient_records')
          .update(updateData)
          .eq('id', recordId)
          .select()
          .single();

      return StrautilsResponse.success(PatientRecordModel.fromMap(response));
    }, action: 'atualizar registro do paciente.');
  }

  Future<void> deletePatientRecord(String recordId) async {
    await _client
        .from('tb_patient_records')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', recordId);
  }
}
