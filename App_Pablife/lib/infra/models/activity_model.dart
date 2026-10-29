import 'dart:convert';

import 'package:pablife/infra/services/auth_service.dart';
import 'package:timezone/timezone.dart' as tz;

class ActivityModel {
  final String id;
  final String userId;
  final String type;
  final String name;
  final String? description;
  final List<String>? steps;
  final String priority;
  final DateTime? dueAt;
  final bool allDay;
  final String? timezone;
  final String? activityRecurrenceRuleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? eventDate;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    this.description,
    this.steps,
    required this.priority,
    this.dueAt,
    this.allDay = false,
    this.timezone,
    this.activityRecurrenceRuleId,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.completedAt,
    this.eventDate,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'type': type,
      'name': name,
      'description': description,
      'steps': steps ?? [],
      'priority': priority,
      'due_at': dueAt?.toIso8601String(),
      'all_day': allDay,
      'timezone': timezone,
      'activity_recurrence_rule_id': activityRecurrenceRuleId,
    };

    if (id.isNotEmpty) {
      map['id'] = id;
    }
    if (createdAt != DateTime(1970)) {
      map['created_at'] = createdAt.toIso8601String();
    }
    if (updatedAt != DateTime(1970)) {
      map['updated_at'] = updatedAt.toIso8601String();
    }

    return map;
  }

  factory ActivityModel.fromEvent(Map<String, dynamic> event) {
    final userId = AuthService.instance.currentUser?.id;

    DateTime? dueAt;
    if (event['start_at'] != null) {
      final utcDateTime = DateTime.parse(event['start_at']);
      // Converte de UTC para o horário local do dispositivo
      final utcTZ = tz.TZDateTime.from(utcDateTime, tz.UTC);
      final localTZ = tz.TZDateTime.from(utcTZ, tz.local);
      dueAt = DateTime(
        localTZ.year,
        localTZ.month,
        localTZ.day,
        localTZ.hour,
        localTZ.minute,
        localTZ.second,
        localTZ.millisecond,
        localTZ.microsecond,
      );
    } else if (event['end_at'] != null) {
      final utcDateTime = DateTime.parse(event['end_at']);
      final utcTZ = tz.TZDateTime.from(utcDateTime, tz.UTC);
      final localTZ = tz.TZDateTime.from(utcTZ, tz.local);
      dueAt = DateTime(
        localTZ.year,
        localTZ.month,
        localTZ.day,
        localTZ.hour,
        localTZ.minute,
        localTZ.second,
        localTZ.millisecond,
        localTZ.microsecond,
      );
    }

    final eventDate = _parseDateOnly(event['event_date']);

    return ActivityModel(
      id: event['event_id'] ?? '',
      userId: userId ?? '',
      type: event['type'] ?? '',
      name: event['title'] ?? '',
      description: event['description'],
      steps: _parseSteps(event['steps']),
      priority: event['priority'] ?? 'medium',
      dueAt: dueAt,
      allDay: event['all_day'] ?? false,
      timezone: event['timezone'],
      activityRecurrenceRuleId: event['activity_recurrence_rule_id'],
      createdAt: event['created_at'] != null
          ? DateTime.parse(event['created_at'])
          : DateTime.now(),
      updatedAt: event['updated_at'] != null
          ? DateTime.parse(event['updated_at'])
          : DateTime.now(),
      isCompleted: event['is_completed'] ?? false,
      completedAt: event['completed_at'] != null
          ? DateTime.parse(event['completed_at'])
          : null,
      eventDate: eventDate,
    );
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    final register = map['tb_activity_registers'];
    bool isCompleted = false;
    DateTime? completedAt;
    final dueAt = map['due_at'] != null ? DateTime.parse(map['due_at']) : null;
    final activityDate = _resolveActivityDate(
      eventDate: _parseDateOnly(map['event_date']),
      dueAt: dueAt,
      timezone: map['timezone'],
    );

    if (register != null && register is List && register.isNotEmpty) {
      Map<String, dynamic>? activeRegister;
      try {
        activeRegister =
            register.firstWhere(
                  (r) =>
                      r != null &&
                      r is Map<String, dynamic> &&
                      r['id'] != null &&
                      r['deleted_at'] == null &&
                      _matchesActivityDate(r['activity_date'], activityDate),
                )
                as Map<String, dynamic>?;
      } catch (e) {
        activeRegister = null;
      }

      if (activeRegister == null && activityDate == null) {
        try {
          activeRegister =
              register.firstWhere(
                    (r) =>
                        r != null &&
                        r is Map<String, dynamic> &&
                        r['id'] != null &&
                        r['deleted_at'] == null,
                  )
                  as Map<String, dynamic>?;
        } catch (e) {
          activeRegister = null;
        }
      }

      if (activeRegister != null) {
        isCompleted = true;
        if (activeRegister['registered_at'] != null) {
          completedAt = DateTime.parse(activeRegister['registered_at']);
        }
      }
    }

    return ActivityModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      steps: _parseSteps(map['steps']),
      priority: map['priority'] ?? 'medium',
      dueAt: dueAt,
      allDay: map['all_day'] ?? false,
      timezone: map['timezone'],
      activityRecurrenceRuleId: map['activity_recurrence_rule_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      isCompleted: isCompleted,
      completedAt: completedAt,
      eventDate: _parseDateOnly(map['event_date']),
    );
  }

  static List<String>? _parseSteps(dynamic stepsData) {
    if (stepsData == null) return null;

    if (stepsData is List) {
      return stepsData.map((e) => e.toString()).toList();
    }

    if (stepsData is String) {
      try {
        final decoded = json.decode(stepsData);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  String toJson() => json.encode(toMap());

  factory ActivityModel.fromJson(String source) =>
      ActivityModel.fromMap(json.decode(source) as Map<String, dynamic>);

  ActivityModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? name,
    String? description,
    List<String>? steps,
    String? priority,
    DateTime? dueAt,
    bool? allDay,
    String? timezone,
    String? activityRecurrenceRuleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? eventDate,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      allDay: allDay ?? this.allDay,
      timezone: timezone ?? this.timezone,
      activityRecurrenceRuleId:
          activityRecurrenceRuleId ?? this.activityRecurrenceRuleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      eventDate: eventDate ?? this.eventDate,
    );
  }

  DateTime? get activityDate {
    if (eventDate != null) {
      return DateTime(eventDate!.year, eventDate!.month, eventDate!.day);
    }
    if (dueAt == null) return null;

    final tzName = timezone;
    if (tzName != null && tzName.isNotEmpty) {
      try {
        final location = tz.getLocation(tzName);
        final dueAtUtc = dueAt!.isUtc ? dueAt! : dueAt!.toUtc();
        final localized = tz.TZDateTime.from(dueAtUtc, location);
        return DateTime(localized.year, localized.month, localized.day);
      } catch (e) {
        // Fallback to local date when timezone resolution fails.
      }
    }

    final local = dueAt!.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime? _parseDateOnly(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    if (value is String && value.isNotEmpty) {
      try {
        final parsed = DateTime.parse(value);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static DateTime? _resolveActivityDate({
    DateTime? eventDate,
    DateTime? dueAt,
    String? timezone,
  }) {
    if (eventDate != null) {
      return DateTime(eventDate.year, eventDate.month, eventDate.day);
    }
    if (dueAt == null) return null;
    if (timezone != null && timezone.isNotEmpty) {
      try {
        final location = tz.getLocation(timezone);
        final dueAtUtc = dueAt.isUtc ? dueAt : dueAt.toUtc();
        final localized = tz.TZDateTime.from(dueAtUtc, location);
        return DateTime(localized.year, localized.month, localized.day);
      } catch (e) {
        // Fallback to local date when timezone resolution fails.
      }
    }
    final local = dueAt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool _matchesActivityDate(dynamic registerDate, DateTime? activityDate) {
    if (activityDate == null) return false;
    final parsed = _parseDateOnly(registerDate);
    if (parsed == null) return false;
    return parsed.year == activityDate.year &&
        parsed.month == activityDate.month &&
        parsed.day == activityDate.day;
  }
}
