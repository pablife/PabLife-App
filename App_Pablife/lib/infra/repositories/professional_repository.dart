import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:strawti_utils/strawti_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/professional_model.dart';
import '../models/professional_with_user_model.dart';
import '../models/user_model.dart';
import '../services/one_signal_service.dart';
import 'user_repository.dart';

class ProfessionalRepository extends StrautilsTryThis {
  ProfessionalRepository();
  final UserRepository _userRepository = UserRepository();

  final SupabaseClient _client = Supabase.instance.client;
  static const Duration _defaultSlotDuration = Duration(hours: 1);
  static const String _defaultTimezone = 'America/Sao_Paulo';

  DateTime _convertToBackendLocalTime(DateTime startAt, String timezone) {
    final backendTimezone = tz.getLocation(timezone);
    final localDateTime = DateTime(
      startAt.year,
      startAt.month,
      startAt.day,
      startAt.hour,
      startAt.minute,
    );
    final utcDateTime = localDateTime.toUtc();
    final utcTZDateTime = tz.TZDateTime.from(utcDateTime, tz.UTC);
    final backendLocalTime = tz.TZDateTime.from(utcTZDateTime, backendTimezone);
    return DateTime(
      backendLocalTime.year,
      backendLocalTime.month,
      backendLocalTime.day,
      backendLocalTime.hour,
      backendLocalTime.minute,
    );
  }

  String _formatDbTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:00';
  }

  int _toWeekSelect(DateTime dateTime) {
    return dateTime.weekday % 7;
  }

  Future<bool> _hasRecurringConflict({
    required String professionalId,
    required DateTime startAt,
    required DateTime finishAt,
    required String timezone,
  }) async {
    final convertedStart = _convertToBackendLocalTime(startAt, timezone);
    final convertedFinish = _convertToBackendLocalTime(finishAt, timezone);
    final weekSelect = _toWeekSelect(convertedStart);
    final startTime = _formatDbTime(convertedStart);
    final finishTime = _formatDbTime(convertedFinish);

    final response = await _client
        .from('tb_appointment_times')
        .select(
          'id, appointment_recurrence_rule:tb_appointment_recurrence_rules!inner(week_select, end_at)',
        )
        .eq('professional_id', professionalId)
        .eq('start_time_at', startTime)
        .eq('finish_time_at', finishTime)
        .eq('appointment_recurrence_rule.week_select', weekSelect)
        .not('appointment_recurrence_rule_id', 'is', null)
        .isFilter('deleted_at', null)
        .limit(1);

    if ((response as List).isEmpty) {
      return false;
    }

    final first = response.first;
    final rule = first['appointment_recurrence_rule'] as Map?;
    if (rule == null) {
      return false;
    }

    final endAtRaw = rule['end_at'];
    if (endAtRaw == null) {
      return true;
    }

    final endAt = endAtRaw is DateTime
        ? endAtRaw
        : DateTime.tryParse(endAtRaw.toString());
    if (endAt == null) {
      return true;
    }

    final normalizedStart = DateTime(
      convertedStart.year,
      convertedStart.month,
      convertedStart.day,
    );
    final normalizedEnd = DateTime(endAt.year, endAt.month, endAt.day);
    return !normalizedStart.isAfter(normalizedEnd);
  }

  Future<bool> _hasAppointmentBookedForSlot({
    required String appointmentTimeId,
    required DateTime slotDate,
  }) async {
    final slotDateStr = DateFormat('yyyy-MM-dd').format(slotDate);
    final response = await _client
        .from('tb_appointments')
        .select(
          'id, start_of_scheduled_window, appointment_time:tb_appointment_times!inner(timezone)',
        )
        .eq('appointment_time_id', appointmentTimeId)
        .isFilter('deleted_at', null);

    for (final row in response as List) {
      final timeData = (row as Map)['appointment_time'] as Map?;
      final timezone = timeData?['timezone']?.toString() ?? _defaultTimezone;
      final startRaw = row['start_of_scheduled_window'];
      if (startRaw == null) continue;
      final startAt = startRaw is DateTime
          ? startRaw
          : DateTime.tryParse(startRaw.toString());
      if (startAt == null) continue;
      final startDate = tz.TZDateTime.from(startAt, tz.getLocation(timezone));
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      if (startDateStr == slotDateStr) {
        return true;
      }
    }

    return false;
  }

  FStrautilsResponse<bool> removeScheduleSlot({
    required String appointmentTimeId,
    required DateTime slotDate,
    required bool applyToFuture,
  }) {
    return tryThis(() async {
      debugPrint(
        '🗑️ [ProfessionalRepo] Removendo horário $appointmentTimeId em $slotDate (futuros: $applyToFuture)',
      );
      final currentUserId = _client.auth.currentUser?.id;
      debugPrint(
        '🗑️ [ProfessionalRepo] Current user: ${currentUserId ?? 'null'}',
      );
      final appointmentRow = await _client
          .from('tb_appointment_times')
          .select(
            'id, due_at, appointment_recurrence_rule_id, professional_id, timezone',
          )
          .eq('id', appointmentTimeId)
          .maybeSingle();

      if (appointmentRow == null) {
        debugPrint(
          '🗑️ [ProfessionalRepo] Horário não encontrado para remover.',
        );
        return StrautilsResponse.error('Horário não encontrado.');
      }
      debugPrint(
        '🗑️ [ProfessionalRepo] Slot carregado: ${appointmentRow['id']} prof=${appointmentRow['professional_id']} recurrence=${appointmentRow['appointment_recurrence_rule_id']} timezone=${appointmentRow['timezone']} due_at=${appointmentRow['due_at']}',
      );
      try {
        if (currentUserId != null) {
          final userRow = await _client
              .from('tb_users')
              .select('id, role, status')
              .eq('id', currentUserId)
              .maybeSingle();
          debugPrint(
            '🗑️ [ProfessionalRepo] User row: id=${userRow?['id']} role=${userRow?['role']} status=${userRow?['status']}',
          );
        }

        final professionalId = appointmentRow['professional_id']?.toString();
        if (professionalId != null) {
          final professionalRow = await _client
              .from('tb_professionals')
              .select('id, user_id, deleted_at')
              .eq('id', professionalId)
              .maybeSingle();
          debugPrint(
            '🗑️ [ProfessionalRepo] Professional row: id=${professionalRow?['id']} user_id=${professionalRow?['user_id']} deleted_at=${professionalRow?['deleted_at']}',
          );
        }
      } catch (e) {
        debugPrint('🗑️ [ProfessionalRepo] Debug lookup failed: $e');
      }

      final hasAppointment = await _hasAppointmentBookedForSlot(
        appointmentTimeId: appointmentTimeId,
        slotDate: slotDate,
      );
      if (hasAppointment) {
        debugPrint(
          '🗑️ [ProfessionalRepo] Remoção bloqueada: horário já agendado.',
        );
        return StrautilsResponse.error(
          'Não é possível remover este horário porque já existe agendamento.',
        );
      }
      debugPrint('🗑️ [ProfessionalRepo] Nenhum agendamento no dia do slot.');

      final recurrenceRuleId = appointmentRow['appointment_recurrence_rule_id']
          ?.toString();
      final timezone =
          appointmentRow['timezone']?.toString() ?? _defaultTimezone;

      if (recurrenceRuleId == null) {
        try {
          await _client.rpc(
            'soft_delete_appointment_time',
            params: {'appointment_time_id': appointmentTimeId},
          );
        } on PostgrestException catch (e) {
          debugPrint(
            '🗑️ [ProfessionalRepo] Erro ao remover horário pontual: ${e.message}',
          );
          return StrautilsResponse.error(
            'Erro ao remover horário: ${e.message}',
          );
        }

        return StrautilsResponse.success(true);
      }

      if (applyToFuture) {
        final endAtBase = DateTime(
          slotDate.year,
          slotDate.month,
          slotDate.day,
          0,
          0,
        ).subtract(const Duration(seconds: 1));
        final endAtTz = tz.TZDateTime.from(endAtBase, tz.getLocation(timezone));

        try {
          await _client
              .from('tb_appointment_recurrence_rules')
              .update({'end_at': endAtTz.toIso8601String()})
              .eq('id', recurrenceRuleId);
        } on PostgrestException catch (e) {
          debugPrint(
            '🗑️ [ProfessionalRepo] Erro ao encerrar recorrência: ${e.message}',
          );
          return StrautilsResponse.error(
            'Erro ao encerrar recorrência: ${e.message}',
          );
        }

        return StrautilsResponse.success(true);
      }

      final slotDateStr = DateFormat('yyyy-MM-dd').format(slotDate);
      try {
        await _client.from('tb_appointment_recurrence_exceptions').insert({
          'appointment_time_id': appointmentTimeId,
          'slot_date': slotDateStr,
        });
      } on PostgrestException catch (e) {
        debugPrint(
          '🗑️ [ProfessionalRepo] Erro ao criar exceção: ${e.message}',
        );
        return StrautilsResponse.error(
          'Erro ao remover horário do dia: ${e.message}',
        );
      }

      return StrautilsResponse.success(true);
    }, action: 'remover horário.');
  }

  Future<String> _createAppointmentRecurrenceRule({
    required DateTime startAt,
    required int weekSelect,
    required String timezone,
  }) async {
    final response = await _client
        .from('tb_appointment_recurrence_rules')
        .insert({
          'start_at': startAt.toIso8601String(),
          'week_select': weekSelect,
          'timezone': timezone,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  FStrautilsResponse<Map<String, dynamic>?> createProfessionalAccount({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String cpfDocument,
    required String professionalType,
    required String validationDocumentUrl,
  }) {
    return tryThis(() async {
      final response = await _client.functions.invoke(
        'create-account',
        body: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'cpfDocument': cpfDocument,
          'termsAccepted': true,
          'imageUrl': null,
          'role': 'professional',
          'professionalType': professionalType,
          'validationDocumentUrl': validationDocumentUrl,
        },
      );

      if (response.status == 201) {
        final data = response.data as Map<String, dynamic>;
        return StrautilsResponse.success(data);
      } else {
        final error = response.data as Map<String, dynamic>;
        return StrautilsResponse.error(
          error['error'] ?? 'Erro ao criar conta profissional',
        );
      }
    }, action: 'criar conta profissional.');
  }

  FStrautilsResponse<ProfessionalModel?> getProfessionalById(String id) {
    return tryThis(() async {
      final response = await _client
          .from('tb_professionals')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.error('Profissional não encontrado');
      }

      return StrautilsResponse.success(ProfessionalModel.fromMap(response));
    }, action: 'buscar profissional por ID.');
  }

  FStrautilsResponse<ProfessionalModel?> getProfessionalByUserId(
    String userId,
  ) {
    return tryThis(() async {
      final response = await _client
          .from('tb_professionals')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return StrautilsResponse.error(
          'Profissional não encontrado para este usuário',
        );
      }

      return StrautilsResponse.success(ProfessionalModel.fromMap(response));
    }, action: 'buscar profissional por user ID.');
  }

  FStrautilsResponse<List<ProfessionalWithUserModel>> getAllProfessionals() {
    return tryThis(() async {
      final responseData = await _client
          .from('tb_professionals')
          .select('''
          id,
          user_id,
          type,
          validation_document_url,
          validation_status,
          description,
          created_at,
          updated_at,
          deleted_at,
          tb_users:tb_users!inner(
            id,
            full_name,
            email,
            phone,
            cpf_document,
            image_url,
            terms_accepted,
            role,
            status,
            created_at,
            updated_at,
            deleted_at
          )
          ''')
          .eq('validation_status', 'approved')
          .eq('tb_users.status', 'active')
          .isFilter('deleted_at', null)
          .order(
            'full_name_normalized',
            referencedTable: 'tb_users',
            ascending: true,
          )
          .order('created_at', ascending: true);

      final professionals = responseData.map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        final userData = Map<String, dynamic>.from(data.remove('tb_users'));

        final professional = ProfessionalModel.fromMap(data);
        final user = UserModel.fromMap(userData);

        return ProfessionalWithUserModel(
          professional: professional,
          user: user,
        );
      }).toList();

      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId != null && professionals.isNotEmpty) {
        final professionalIds = professionals
            .map((p) => p.professional.id)
            .whereType<String>()
            .toList();

        final appointments = await _fetchUserAppointments(
          professionalIds,
          currentUserId,
        );

        for (var i = 0; i < professionals.length; i++) {
          final professional = professionals[i];
          final professionalId = professional.professional.id;
          if (professionalId == null) continue;

          final snapshot = appointments[professionalId];
          if (snapshot == null) continue;

          professionals[i] = professional.copyWith(
            appointmentId: snapshot.appointmentId,
            appointmentTimeId: snapshot.appointmentTimeId,
            appointmentDate: snapshot.startAt,
            appointmentTime: _formatTime(snapshot.startAt),
            appointmentTimezone: snapshot.timezone,
          );
        }
      }

      return StrautilsResponse.success(professionals);
    }, action: 'buscar todos os profissionais.');
  }

  FStrautilsResponse<List<ProfessionalWithUserModel>> getProfessionalsByType(
    String type,
  ) {
    return tryThis(() async {
      final allResponse = await getAllProfessionals();
      if (!allResponse.success) {
        return StrautilsResponse.error(allResponse.message);
      }

      final filtered = allResponse.data!
          .where((p) => p.professional.type == type)
          .toList();

      return StrautilsResponse.success(filtered);
    }, action: 'buscar profissionais por tipo.');
  }

  FStrautilsResponse<List<ProfessionalWithUserModel>> searchProfessionals(
    String query,
  ) {
    return tryThis(() async {
      final allResponse = await getAllProfessionals();
      if (!allResponse.success) {
        return StrautilsResponse.error(allResponse.message);
      }

      if (query.isEmpty) {
        return StrautilsResponse.success(allResponse.data!);
      }

      final filtered = allResponse.data!.where((p) {
        final lowerQuery = query.toLowerCase();
        return p.user.fullName.toLowerCase().contains(lowerQuery) ||
            p.user.email.toLowerCase().contains(lowerQuery) ||
            p.typeFormatted.toLowerCase().contains(lowerQuery);
      }).toList();

      return StrautilsResponse.success(filtered);
    }, action: 'buscar profissionais por termo.');
  }

  FStrautilsResponse<Map<DateTime, List<String>>> getUnavailableSlots(
    String professionalId,
  ) {
    return tryThis(() async {
      final List<dynamic> responseData;
      try {
        responseData = await _client
            .from('tb_appointments')
            .select('''
            appointment_time:tb_appointment_times!inner(due_at, start_time_at)
            ''')
            .eq('professional_id', professionalId)
            .isFilter('deleted_at', null);
      } on PostgrestException {
        return StrautilsResponse.success(<DateTime, List<String>>{});
      }

      final unavailableSlots = <DateTime, List<String>>{};
      for (final item in responseData) {
        final timeData = (item as Map)['appointment_time'] as Map?;
        final dueAtStr = timeData?['due_at']?.toString();
        final startTimeStr = timeData?['start_time_at']?.toString();
        if (dueAtStr == null || startTimeStr == null) continue;

        final dueAt = DateTime.parse(dueAtStr);
        final timeParts = startTimeStr.split(':');
        final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
        final minute = timeParts.length > 1
            ? int.tryParse(timeParts[1]) ?? 0
            : 0;
        final startAt = DateTime(
          dueAt.year,
          dueAt.month,
          dueAt.day,
          hour,
          minute,
        );

        final normalizedDate = DateTime(
          startAt.year,
          startAt.month,
          startAt.day,
        );
        final timeLabel = _formatTime(startAt);

        unavailableSlots.putIfAbsent(normalizedDate, () => []).add(timeLabel);
      }

      return StrautilsResponse.success(unavailableSlots);
    }, action: 'buscar horários indisponíveis.');
  }

  FStrautilsResponse<bool> scheduleAppointment({
    required String professionalId,
    required String appointmentTimeId,
    required DateTime slotStartAt,
  }) {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return StrautilsResponse.error('Usuário não autenticado.');
      }

      final slotDateStr = DateFormat('yyyy-MM-dd').format(slotStartAt);

      // Verify the slot is still available in the view
      final Map<String, dynamic>? availableSlot;
      try {
        availableSlot = await _client
            .from('vw_professional_available_appointment_slots')
            .select('appointment_time_id, slot_start_at, slot_finish_at')
            .eq('professional_id', professionalId)
            .eq('appointment_time_id', appointmentTimeId)
            .eq('slot_date', slotDateStr)
            .eq('is_my_appointment', false)
            .maybeSingle();
      } on PostgrestException catch (e) {
        return StrautilsResponse.error(
          'Erro ao verificar disponibilidade: ${e.message}',
        );
      }

      if (availableSlot == null) {
        return StrautilsResponse.error(
          'Este horário não está mais disponível.',
        );
      }

      final slotStartAtFromDb = DateTime.parse(
        availableSlot['slot_start_at'] as String,
      );
      final slotFinishAtFromDb = DateTime.parse(
        availableSlot['slot_finish_at'] as String,
      );

      // Create the appointment
      String? appointmentId;
      try {
        final response = await _client
            .from('tb_appointments')
            .insert({
              'scheduled_by': userId,
              'professional_id': professionalId,
              'appointment_time_id': appointmentTimeId,
              'start_of_scheduled_window': slotStartAtFromDb.toIso8601String(),
              'end_of_scheduled_window': slotFinishAtFromDb.toIso8601String(),
            })
            .select('id')
            .single();

        appointmentId = response['id']?.toString();
      } on PostgrestException catch (e) {
        return StrautilsResponse.error(
          'Erro ao agendar consulta: ${e.message}',
        );
      }

      if (appointmentId != null) {
        try {
          await _client.from('tb_patients').insert({
            'user_id': userId,
            'professional_id': professionalId,
            'appointment_id': appointmentId,
          });
        } on PostgrestException catch (e) {
          debugPrint(
            '⚠️ [ProfessionalRepo] Erro ao criar/atualizar paciente: ${e.message}',
          );
        }
      }

      UserModel? professional = await _userRepository
          .getUserByProfessionalId(professionalId)
          .then((value) => value.data);
      UserModel? pacient = await _userRepository
          .getUserById(userId)
          .then((value) => value.data);

      // Garantir que slotStartAt está em UTC para cálculos corretos
      final slotStartAtUtc = slotStartAtFromDb.isUtc
          ? slotStartAtFromDb
          : slotStartAtFromDb.toUtc();

      DateTime thirtyHoursBeforeAppointment = slotStartAtUtc.subtract(
        const Duration(hours: 30),
      );

      DateTime thirtyMinutesBeforeAppointment = slotStartAtUtc.subtract(
        const Duration(minutes: 30),
      );

      DateTime nowUtc = DateTime.now().toUtc();

      if (thirtyHoursBeforeAppointment.isAfter(nowUtc)) {
        // notificação para 30 horas antes da consulta:
        final formattedDate = DateFormat(
          'dd/MM/yyyy',
        ).format(slotStartAtFromDb.toLocal());
        final formattedTime = DateFormat(
          'HH:mm',
        ).format(slotStartAtFromDb.toLocal());

        // Para o paciente
        await OneSignalService.scheduleNotification(
          title: 'Pablife - Lembrete de consulta',
          message:
              'Lembrete de consulta com ${professional?.fullName} no dia $formattedDate às $formattedTime',
          oneSignalUserId: await _userRepository
              .getOneSignalUserId(userId)
              .then((value) => value.data),
          sendAfter: thirtyHoursBeforeAppointment,
        );

        if (professional != null) {
          // Para o profissional
          await OneSignalService.scheduleNotification(
            title: 'Pablife - Lembrete de consulta',
            message:
                'Lembrete de consulta com ${pacient?.fullName} no dia $formattedDate às $formattedTime',
            oneSignalUserId: await _userRepository
                .getOneSignalUserId(professional.id!)
                .then((value) => value.data),
            sendAfter: thirtyHoursBeforeAppointment,
          );
        }
      }

      if (thirtyMinutesBeforeAppointment.isAfter(nowUtc)) {
        // notificação para 30 minutos antes da consulta:
        final formattedDate = DateFormat(
          'dd/MM/yyyy',
        ).format(slotStartAtFromDb.toLocal());
        final formattedTime = DateFormat(
          'HH:mm',
        ).format(slotStartAtFromDb.toLocal());

        // Para o paciente
        await OneSignalService.scheduleNotification(
          title: 'Pablife - Lembrete de consulta',
          message:
              'Lembrete de consulta com ${professional?.fullName} no dia $formattedDate às $formattedTime',
          oneSignalUserId: await _userRepository
              .getOneSignalUserId(userId)
              .then((value) => value.data),
          sendAfter: thirtyMinutesBeforeAppointment,
        );

        if (professional != null) {
          // Para o profissional
          await OneSignalService.scheduleNotification(
            title: 'Pablife - Lembrete de consulta',
            message:
                'Lembrete de consulta com ${pacient?.fullName} no dia $formattedDate às $formattedTime',
            oneSignalUserId: await _userRepository
                .getOneSignalUserId(professional.id!)
                .then((value) => value.data),
            sendAfter: thirtyMinutesBeforeAppointment,
          );
        }
      }

      return StrautilsResponse.success(true);
    }, action: 'agendar horário.');
  }

  FStrautilsResponse<bool> cancelAppointment(String appointmentId) {
    return tryThis(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return StrautilsResponse.error('Usuário não autenticado.');
      }

      final existing = await _client
          .from('tb_appointments')
          .select('id')
          .eq('id', appointmentId)
          .eq('scheduled_by', userId)
          .maybeSingle();

      if (existing == null) {
        return StrautilsResponse.error('Agendamento não encontrado.');
      }

      await _client.from('tb_appointments').delete().eq('id', appointmentId);

      return StrautilsResponse.success(true);
    }, action: 'cancelar horário.');
  }

  Future<Map<String, _AppointmentSnapshot>> _fetchUserAppointments(
    List<String> professionalIds,
    String userId,
  ) async {
    if (professionalIds.isEmpty) {
      return {};
    }

    final List<dynamic> appointmentsResponse;
    try {
      appointmentsResponse = await _client
          .from('tb_appointments')
          .select('''
          id,
          professional_id,
          appointment_time_id,
          appointment_time:tb_appointment_times!inner(due_at, start_time_at, timezone)
          ''')
          .eq('scheduled_by', userId)
          .eq('status', 'scheduled')
          .isFilter('deleted_at', null)
          .inFilter('professional_id', professionalIds);
    } on PostgrestException {
      return {};
    }

    final map = <String, _AppointmentSnapshot>{};

    for (final item in appointmentsResponse) {
      final data = Map<String, dynamic>.from(item as Map);
      final professionalId = data['professional_id']?.toString();
      final appointmentId = data['id']?.toString();
      final appointmentTimeId = data['appointment_time_id']?.toString();
      final timeData = data['appointment_time'] as Map?;
      final dueAtStr = timeData?['due_at']?.toString();
      final startTimeStr = timeData?['start_time_at']?.toString();
      if (professionalId == null ||
          appointmentId == null ||
          appointmentTimeId == null ||
          dueAtStr == null ||
          startTimeStr == null) {
        continue;
      }

      final dueAt = DateTime.parse(dueAtStr);
      final timeParts = startTimeStr.split(':');
      final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
      final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
      final startAt = DateTime(
        dueAt.year,
        dueAt.month,
        dueAt.day,
        hour,
        minute,
      );

      final timezone = timeData?['timezone']?.toString() ?? _defaultTimezone;

      map[professionalId] = _AppointmentSnapshot(
        appointmentId: appointmentId,
        appointmentTimeId: appointmentTimeId,
        startAt: startAt,
        timezone: timezone,
      );
    }

    return map;
  }

  Future<String> _ensureAppointmentTime({
    required String professionalId,
    required DateTime startAt,
    required DateTime finishAt,
    required String timezone,
  }) async {
    final date = DateTime(startAt.year, startAt.month, startAt.day);
    final startTime =
        '${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')}:00';
    final finishTime =
        '${finishAt.hour.toString().padLeft(2, '0')}:${finishAt.minute.toString().padLeft(2, '0')}:00';
    final dateStr = date.toIso8601String().split('T')[0];

    final Map<String, dynamic>? existing;
    try {
      existing = await _client
          .from('tb_appointment_times')
          .select('id')
          .eq('professional_id', professionalId)
          .eq('due_at', dateStr)
          .eq('start_time_at', startTime)
          .eq('finish_time_at', finishTime)
          .maybeSingle();
    } on PostgrestException catch (e) {
      throw Exception('Falha ao consultar horários: ${e.message}');
    }

    if (existing != null && existing['id'] != null) {
      return existing['id'].toString();
    }

    final Map<String, dynamic>? inserted;
    try {
      inserted = await _client
          .from('tb_appointment_times')
          .insert({
            'professional_id': professionalId,
            'due_at': dateStr,
            'start_time_at': startTime,
            'finish_time_at': finishTime,
            'timezone': timezone,
          })
          .select('id')
          .maybeSingle();
    } on PostgrestException catch (e) {
      throw Exception('Falha ao registrar horário: ${e.message}');
    }

    if (inserted == null || inserted['id'] == null) {
      throw Exception('Não foi possível registrar o horário selecionado.');
    }

    return inserted['id'].toString();
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime.toLocal());
  }

  FStrautilsResponse<bool> createScheduleSlot({
    required String professionalId,
    required DateTime startAt,
    Duration duration = _defaultSlotDuration,
    String timezone = _defaultTimezone,
  }) {
    return tryThis(() async {
      final finishAt = startAt.add(duration);
      final hasRecurringConflict = await _hasRecurringConflict(
        professionalId: professionalId,
        startAt: startAt,
        finishAt: finishAt,
        timezone: timezone,
      );
      if (hasRecurringConflict) {
        throw Exception(
          'Já existe um horário recorrente para este dia e horário.',
        );
      }

      final convertedStart = _convertToBackendLocalTime(startAt, timezone);
      final convertedFinish = convertedStart.add(duration);

      try {
        await _ensureAppointmentTime(
          professionalId: professionalId,
          startAt: convertedStart,
          finishAt: convertedFinish,
          timezone: timezone,
        );
      } catch (error) {
        debugPrint('Error in createScheduleSlot: $error');
        rethrow;
      }

      return StrautilsResponse.success(true);
    }, action: 'criar horário disponível.');
  }

  FStrautilsResponse<bool> createRecurringScheduleSlot({
    required String professionalId,
    required DateTime startAt,
    Duration duration = _defaultSlotDuration,
    String timezone = _defaultTimezone,
  }) {
    return tryThis(() async {
      final finishAt = startAt.add(duration);
      final hasRecurringConflict = await _hasRecurringConflict(
        professionalId: professionalId,
        startAt: startAt,
        finishAt: finishAt,
        timezone: timezone,
      );
      if (hasRecurringConflict) {
        throw Exception(
          'Já existe um horário recorrente para este dia e horário.',
        );
      }

      final convertedStart = _convertToBackendLocalTime(startAt, timezone);
      final convertedFinish = convertedStart.add(duration);
      final weekSelect = _toWeekSelect(convertedStart);

      final recurrenceRuleId = await _createAppointmentRecurrenceRule(
        startAt: convertedStart,
        weekSelect: weekSelect,
        timezone: timezone,
      );

      try {
        await _client.from('tb_appointment_times').insert({
          'professional_id': professionalId,
          'start_time_at': _formatDbTime(convertedStart),
          'finish_time_at': _formatDbTime(convertedFinish),
          'timezone': timezone,
          'appointment_recurrence_rule_id': recurrenceRuleId,
        });
      } on PostgrestException catch (e) {
        try {
          await _client
              .from('tb_appointment_recurrence_rules')
              .delete()
              .eq('id', recurrenceRuleId);
        } catch (_) {}
        throw Exception('Falha ao registrar horário recorrente: ${e.message}');
      }

      return StrautilsResponse.success(true);
    }, action: 'criar horário recorrente.');
  }

  FStrautilsResponse<Map<String, List<String>>> getExistingScheduleSlots({
    required String professionalId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return tryThis(() async {
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      final response = await _client
          .from('tb_appointment_times')
          .select('due_at, start_time_at')
          .eq('professional_id', professionalId)
          .gte('due_at', startDateStr)
          .lte('due_at', endDateStr);

      final existingSlots = <String, List<String>>{};
      for (final item in response as List) {
        final dueAtStr = item['due_at'] as String?;
        final startTimeStr = item['start_time_at'] as String?;
        if (dueAtStr != null && startTimeStr != null) {
          final timeParts = startTimeStr.split(':');
          final timeLabel = '${timeParts[0]}:${timeParts[1]}';

          if (!existingSlots.containsKey(dueAtStr)) {
            existingSlots[dueAtStr] = [];
          }
          existingSlots[dueAtStr]!.add(timeLabel);
        }
      }

      for (final key in existingSlots.keys) {
        existingSlots[key]!.sort();
      }

      return StrautilsResponse.success(existingSlots);
    }, action: 'buscar horários existentes.');
  }
}

class _AppointmentSnapshot {
  const _AppointmentSnapshot({
    required this.appointmentId,
    required this.appointmentTimeId,
    required this.startAt,
    required this.timezone,
  });

  final String appointmentId;
  final String appointmentTimeId;
  final DateTime startAt;
  final String timezone;
}
