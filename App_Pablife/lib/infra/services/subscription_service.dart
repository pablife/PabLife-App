import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription_plan_model.dart';
import '../repositories/subscription_plan_repository.dart';

/// Status de acesso do usuário
enum SubscriptionAccessStatus {
  /// Usuário com assinatura ativa e paga
  active,

  /// Usuário em período trial de 7 dias (acesso apenas ao Planner)
  trial,

  /// Assinatura expirada ou sem assinatura
  expired,

  /// Nenhuma assinatura ou trial
  none,
}

int _toIntValue(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

/// Informações completas de acesso do usuário
class UserAccessInfo {
  final SubscriptionAccessStatus status;
  final int consultationsAvailable;
  final int consultationsUsed;
  final bool canAccessPlanner;
  final bool canAccessMentorias;
  final bool canScheduleAppointment;
  final int? trialDaysRemaining;
  final DateTime? subscriptionEndDate;

  UserAccessInfo({
    required this.status,
    this.consultationsAvailable = 0,
    this.consultationsUsed = 0,
    this.canAccessPlanner = false,
    this.canAccessMentorias = false,
    this.canScheduleAppointment = false,
    this.trialDaysRemaining,
    this.subscriptionEndDate,
  });

  /// Retorna quantas consultas ainda restam
  int get consultationsRemaining =>
      (consultationsAvailable - consultationsUsed).clamp(0, consultationsAvailable);

  /// Verifica se o usuário pode agendar mais consultas
  bool get hasConsultationsRemaining => consultationsRemaining > 0;

  /// Cria um UserAccessInfo para usuário sem nenhum acesso
  factory UserAccessInfo.noAccess() {
    return UserAccessInfo(
      status: SubscriptionAccessStatus.none,
      canAccessPlanner: false,
      canAccessMentorias: false,
      canScheduleAppointment: false,
    );
  }

  /// Cria um UserAccessInfo para usuário em trial
  factory UserAccessInfo.trial({required int daysRemaining}) {
    return UserAccessInfo(
      status: SubscriptionAccessStatus.trial,
      canAccessPlanner: true,
      canAccessMentorias: false,
      canScheduleAppointment: false,
      trialDaysRemaining: daysRemaining,
    );
  }

  @override
  String toString() {
    return 'UserAccessInfo(status: $status, '
        'consultations: $consultationsRemaining/$consultationsAvailable, '
        'planner: $canAccessPlanner, mentorias: $canAccessMentorias)';
  }
}

class ConsultationBalance {
  final int remaining;
  final DateTime expiresAt;
  final DateTime startDate;

  ConsultationBalance({
    required this.remaining,
    required this.expiresAt,
    required this.startDate,
  });

  factory ConsultationBalance.fromMap(Map<String, dynamic> map) {
    final expiresValue = map['expires_at'];
    final startValue = map['start_date'];
    return ConsultationBalance(
      remaining: _toIntValue(map['consultations_remaining']),
      expiresAt: expiresValue is DateTime
          ? expiresValue
          : DateTime.parse(expiresValue as String),
      startDate: startValue is DateTime
          ? startValue
          : DateTime.parse(startValue as String),
    );
  }
}

/// Serviço singleton para gerenciar verificação de assinatura
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static SubscriptionService get instance => _instance;

  final SupabaseClient _client = Supabase.instance.client;
  final SubscriptionPlanRepository _planRepository = SubscriptionPlanRepository();

  UserAccessInfo? _cachedAccessInfo;
  DateTime? _lastCheck;
  static const _cacheDuration = Duration(minutes: 5);

  /// Retorna as informações de acesso em cache, se disponíveis
  UserAccessInfo? get cachedAccessInfo => _cachedAccessInfo;

  /// Limpa o cache de acesso
  void clearCache() {
    _cachedAccessInfo = null;
    _lastCheck = null;
  }

  /// Verifica se o cache ainda é válido
  bool get _isCacheValid {
    if (_cachedAccessInfo == null || _lastCheck == null) return false;
    return DateTime.now().difference(_lastCheck!) < _cacheDuration;
  }

  /// Obtém as informações de acesso do usuário atual
  /// [forceRefresh] - Se true, ignora o cache e busca novamente
  Future<UserAccessInfo> getUserAccessInfo({
    required String userId,
    bool forceRefresh = false,
  }) async {
    // Retorna cache se válido e não forçando refresh
    if (!forceRefresh && _isCacheValid) {
      return _cachedAccessInfo!;
    }

    try {
      if (userId.isEmpty) {
        return UserAccessInfo.noAccess();
      }

      final response = await _client.rpc('get_user_subscription_access_info');
      final data = _normalizeRpcRow(response);

      if (data == null) {
        return UserAccessInfo.noAccess();
      }

      final accessType = (data['access_type'] ?? 'free').toString();
      final consultationsTotal = _toInt(data['consultations_total']);
      final consultationsUsed = _toInt(data['consultations_used']);
      final consultationsRemaining = (consultationsTotal - consultationsUsed)
          .clamp(0, consultationsTotal);

      final isSubscriber = accessType == 'subscriber';
      final isTrial = accessType == 'trial';

      final accessInfo = UserAccessInfo(
        status: isSubscriber
            ? SubscriptionAccessStatus.active
            : isTrial
                ? SubscriptionAccessStatus.trial
                : SubscriptionAccessStatus.none,
        consultationsAvailable: consultationsTotal,
        consultationsUsed: consultationsUsed,
        canAccessPlanner: true,
        canAccessMentorias: isSubscriber,
        canScheduleAppointment: isSubscriber && consultationsRemaining > 0,
      );

      _cachedAccessInfo = accessInfo;
      _lastCheck = DateTime.now();
      return accessInfo;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Erro ao verificar acesso: $e');
      return UserAccessInfo.noAccess();
    }
  }

  Map<String, dynamic>? _normalizeRpcRow(dynamic response) {
    if (response == null) return null;
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
    }
    return null;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Verifica rapidamente se o usuário pode acessar o Planner
  Future<bool> canAccessPlanner(String userId) async {
    final accessInfo = await getUserAccessInfo(userId: userId);
    return accessInfo.canAccessPlanner;
  }

  /// Verifica rapidamente se o usuário pode acessar as Mentorias
  Future<bool> canAccessMentorias(String userId) async {
    final accessInfo = await getUserAccessInfo(userId: userId);
    return accessInfo.canAccessMentorias;
  }

  /// Verifica se o usuário pode agendar uma consulta
  Future<bool> canScheduleAppointment(String userId) async {
    final accessInfo = await getUserAccessInfo(userId: userId);
    return accessInfo.canScheduleAppointment;
  }

  /// Retorna quantas consultas restam para o usuário
  Future<int> getRemainingConsultations(String userId) async {
    final accessInfo = await getUserAccessInfo(userId: userId);
    return accessInfo.consultationsRemaining;
  }

  Future<List<ConsultationBalance>> getConsultationBalances() async {
    try {
      final response = await _client.rpc('get_user_consultation_balances');
      if (response == null) return [];

      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map(ConsultationBalance.fromMap)
            .toList();
      }

      if (response is Map<String, dynamic>) {
        return [ConsultationBalance.fromMap(response)];
      }
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Erro ao carregar consultas: $e');
    }

    return [];
  }

  /// Retorna todos os planos disponíveis
  Future<List<SubscriptionPlanModel>> getAvailablePlans() async {
    final response = await _planRepository.getAll();
    if (response.success) {
      return response.data ?? [];
    }
    return [];
  }
}
