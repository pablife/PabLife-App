import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'notification_service.dart';
import 'subscription_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  final SupabaseClient _client = Supabase.instance.client;
  final UserRepository _userRepository = UserRepository();
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  UserModel? _currentUser;
  UserAccessInfo? _userAccessInfo;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  UserAccessInfo? get userAccessInfo => _userAccessInfo;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Verifica se o usuário pode acessar o Planner
  bool get canAccessPlanner => _userAccessInfo?.canAccessPlanner ?? false;

  /// Verifica se o usuário pode acessar as Mentorias
  bool get canAccessMentorias => _userAccessInfo?.canAccessMentorias ?? false;

  /// Verifica se o usuário pode agendar consultas
  bool get canScheduleAppointment =>
      _userAccessInfo?.canScheduleAppointment ?? false;

  /// Retorna quantas consultas restam
  int get remainingConsultations =>
      _userAccessInfo?.consultationsRemaining ?? 0;

  /// Retorna o status de acesso do usuário
  SubscriptionAccessStatus get accessStatus =>
      _userAccessInfo?.status ?? SubscriptionAccessStatus.none;

  /// Verifica se o usuário está em trial
  bool get isInTrial =>
      _userAccessInfo?.status == SubscriptionAccessStatus.trial;

  /// Dias restantes no trial
  int? get trialDaysRemaining => _userAccessInfo?.trialDaysRemaining;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;

    try {
      _client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          await _loadCurrentUser();
          try {
            final notificationService = Get.find<NotificationService>();
            await notificationService.loadUnreadCount();
          } catch (e) {
            debugPrint('Erro ao carregar contador de notificações: $e');
          }
        } else if (event == AuthChangeEvent.signedOut) {
          _currentUser = null;
          _userAccessInfo = null;
          _subscriptionService.clearCache();
          try {
            final notificationService = Get.find<NotificationService>();
            notificationService.setUnreadCount(0);
          } catch (e) {
            debugPrint('Erro ao resetar contador de notificações: $e');
          }
        }
      });

      final session = _client.auth.currentSession;
      if (session != null) {
        await _loadCurrentUser();
        try {
          final notificationService = Get.find<NotificationService>();
          await notificationService.loadUnreadCount();
        } catch (e) {
          debugPrint('Erro ao carregar contador de notificações: $e');
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Erro ao inicializar AuthService: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await _userRepository.getCurrentUser();
      if (response.success && response.data != null) {
        _currentUser = response.data;
        // Carregar informações de assinatura
        await _loadUserAccessInfo();
      } else {
        _currentUser = null;
        _userAccessInfo = null;
      }
    } catch (e) {
      debugPrint('Erro ao carregar usuário atual: $e');
      _currentUser = null;
      _userAccessInfo = null;
    }
  }

  /// Carrega as informações de acesso/assinatura do usuário
  Future<void> _loadUserAccessInfo() async {
    if (_currentUser?.id == null) {
      _userAccessInfo = null;
      return;
    }

    try {
      _userAccessInfo = await _subscriptionService.getUserAccessInfo(
        userId: _currentUser!.id!,
      );
      debugPrint('📋 [AuthService] AccessInfo: $_userAccessInfo');
    } catch (e) {
      debugPrint('❌ [AuthService] Erro ao carregar acesso: $e');
      _userAccessInfo = UserAccessInfo.noAccess();
    }
  }

  /// Recarrega as informações de assinatura (útil após uma compra)
  Future<void> reloadUserAccessInfo() async {
    _subscriptionService.clearCache();
    await _loadUserAccessInfo();
  }

  Future<void> reloadCurrentUser() async {
    await _loadCurrentUser();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadCurrentUser();
        try {
          final notificationService = Get.find<NotificationService>();
          await notificationService.loadUnreadCount();
        } catch (e) {
          debugPrint('Erro ao carregar contador de notificações: $e');
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao fazer login: $e');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  String? _lastSignUpError;

  String? get lastSignUpError => _lastSignUpError;

  Future<bool> signUpWithEmail(
    String email,
    String password,
    UserModel userData,
  ) async {
    _isLoading = true;
    _lastSignUpError = null;

    try {
      final response = await _userRepository.signUpWithEmail(
        userData,
        password,
      );

      if (response.success) {
        final signInSuccess = await signInWithEmail(email, password);
        if (signInSuccess) {
          return true;
        }
        await _loadCurrentUser();
        return true;
      } else {
        _lastSignUpError = response.message;
        return false;
      }
    } catch (e) {
      _lastSignUpError = 'Erro ao criar conta: ${e.toString()}';
      debugPrint('Erro ao criar conta: $e');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;

    try {
      await _client.auth.signOut();
      _currentUser = null;
      _userAccessInfo = null;
      _subscriptionService.clearCache();
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      debugPrint('Erro ao resetar senha: $e');
      return false;
    }
  }

  Future<({bool success, String? error})> verifyOtpAndUpdatePassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );

      if (response.session == null) {
        return (success: false, error: 'Código inválido ou expirado');
      }

      await _client.auth.updateUser(UserAttributes(password: newPassword));

      await _client.auth.signOut();

      return (success: true, error: null);
    } on AuthException catch (e) {
      debugPrint('Erro de autenticação ao verificar OTP: ${e.message}');
      if (e.message.contains('Token has expired')) {
        return (success: false, error: 'Código expirado. Solicite um novo.');
      }
      if (e.message.contains('Invalid') || e.message.contains('invalid')) {
        return (
          success: false,
          error: 'Código inválido. Verifique e tente novamente.',
        );
      }
      return (success: false, error: e.message);
    } catch (e) {
      debugPrint('Erro ao verificar OTP e atualizar senha: $e');
      return (
        success: false,
        error: 'Erro ao redefinir senha. Tente novamente.',
      );
    }
  }
}
