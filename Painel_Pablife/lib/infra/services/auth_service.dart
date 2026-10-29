import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  AuthService._internal();

  static AuthService get instance => _instance;

  final SupabaseClient _client = Supabase.instance.client;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<void> initialize() async {
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = _client.auth.currentUser;
    Get.log('AuthService: auth.currentUser = ${user?.id}');

    if (user != null) {
      try {
        final response = await _client
            .from('tb_users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        Get.log('AuthService: response = $response');

        if (response != null) {
          _currentUser = UserModel.fromMap(response);
          Get.log(
            'AuthService: _currentUser carregado = ${_currentUser?.email}, role = ${_currentUser?.role.value}',
          );
        } else {
          Get.log('AuthService: response é null');
        }
      } catch (e) {
        Get.log('AuthService: Erro ao carregar usuário: $e');
      }
    } else {
      Get.log('AuthService: user é null');
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadCurrentUser();
        return true;
      }
      return false;
    } catch (e) {
      // TODO: Implementar logging adequado
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _currentUser = null;
    } catch (e) {
      // TODO: Implementar logging adequado
    }
  }

  Future<bool> sendPasswordResetEmail(
    String email, {
    String? redirectTo,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get isAuthenticated => _client.auth.currentUser != null;

  bool get isAdmin {
    if (_currentUser == null) return false;
    Get.log(
      'AuthService.isAdmin: role = ${_currentUser?.role}, role.value = ${_currentUser?.role.value}',
    );
    return _currentUser?.role == UserRole.admin;
  }
}
