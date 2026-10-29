import 'dart:convert';

import 'package:strawti_utils/strawti_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../models/user_role.dart';

class UserRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<void> setOneSignalUserId(String oneSignalUserId) {
    return tryThis(() async {
      if (_client.auth.currentUser == null) {
        return StrautilsResponse.error('Usuário não autenticado');
      }

      await _client
          .from('tb_users')
          .update({'one_signal_user_id': oneSignalUserId})
          .eq('id', _client.auth.currentUser!.id)
          .select()
          .maybeSingle();

      return StrautilsResponse.success(null);
    }, action: 'definir ID do OneSignal do usuário.');
  }

  FStrautilsResponse<UserModel?> getUserById(String userId) {
    return tryThis(() async {
      final response = await _client
          .from('tb_users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return StrautilsResponse.success(
        UserModel.fromMap(response as Map<String, dynamic>),
      );
    }, action: 'buscar usuário por ID.');
  }

  FStrautilsResponse<UserModel?> getUserByProfessionalId(
    String professionalId,
  ) {
    return tryThis(() async {
      final userId = await _client
          .from('tb_professionals')
          .select('user_id')
          .eq('id', professionalId)
          .maybeSingle();
      if (userId == null) {
        return StrautilsResponse.error('Profissional não encontrado');
      }

      final response = await _client
          .from('tb_users')
          .select()
          .eq('id', userId['user_id'])
          .maybeSingle();

      return StrautilsResponse.success(
        UserModel.fromMap(response as Map<String, dynamic>),
      );
    }, action: 'buscar usuário por ID do profissional.');
  }

  FStrautilsResponse<String?> getOneSignalUserId(String userId) {
    return tryThis(() async {
      final response = await _client
          .from('tb_users')
          .select('one_signal_user_id')
          .eq('id', userId)
          .maybeSingle();
      return StrautilsResponse.success(response?['one_signal_user_id']);
    }, action: 'buscar ID do OneSignal do usuário.');
  }

  FStrautilsResponse<UserModel?> getCurrentUser() {
    return tryThis(() async {
      final response = await _client.rpc('get_my_uid');
      if (response == null) {
        return StrautilsResponse.error('Usuário não autenticado');
      }

      final userResponse = await _client
          .from('tb_users')
          .select()
          .eq('id', response)
          .maybeSingle();

      if (userResponse == null) {
        return StrautilsResponse.error('Usuário não encontrado');
      }

      return StrautilsResponse.success(UserModel.fromMap(userResponse));
    }, action: 'buscar usuário atual.');
  }

  FStrautilsResponse<UserModel?> signUpWithEmail(
    UserModel user,
    String password,
  ) {
    return tryThis(
      () async {
        final response = await _client.functions.invoke(
          'create-account',
          body: {
            'fullName': user.fullName,
            'email': user.email,
            'password': password,
            'phone': user.phone,
            'cpfDocument': user.cpfDocument,
            'termsAccepted': user.termsAccepted,
            'imageUrl': user.imageUrl,
            'role': user.role.value,
            'professionalType': user.role == UserRole.professional
                ? user.professionalType?.value
                : null,
            'validationDocumentUrl': null,
          },
        );

        if (response.status == 201) {
          final data = response.data as Map<String, dynamic>;
          final userData = data['user'] as Map<String, dynamic>;

          return StrautilsResponse.success(UserModel.fromMap(userData));
        } else {
          Map<String, dynamic>? error;
          if (response.data is Map) {
            error = response.data as Map<String, dynamic>;
          } else if (response.data is String) {
            try {
              error =
                  json.decode(response.data as String) as Map<String, dynamic>;
            } catch (e) {
              error = {'error': response.data};
            }
          } else {
            error = {'error': response.data?.toString() ?? 'Erro desconhecido'};
          }

          final errorMessage = _formatErrorMessage(error);
          return StrautilsResponse.error(errorMessage);
        }
      },
      onCatch: (error) {
        if (error.toString().contains('duplicate key') &&
            error.toString().contains('cpf_document')) {
          return StrautilsResponse.error(
            'Este CPF já está cadastrado. Por favor, use outro CPF ou faça login.',
          );
        }
        if (error.toString().contains('duplicate key') &&
            error.toString().contains('email')) {
          return StrautilsResponse.error(
            'Este email já está cadastrado. Por favor, use outro email ou faça login.',
          );
        }
        return StrautilsResponse.error(error.toString());
      },
      action: 'criar conta com email.',
    );
  }

  FStrautilsResponse<UserModel?> signUpWithEmailAndDocument(
    UserModel user,
    String password,
    String documentBase64,
    String documentFileName, {
    String? profileImageBase64,
    String? profileImageFileName,
    String? description,
  }) {
    return tryThis(() async {
      final body = <String, dynamic>{
        'fullName': user.fullName,
        'email': user.email,
        'password': password,
        'phone': user.phone,
        'cpfDocument': user.cpfDocument,
        'termsAccepted': user.termsAccepted,
        'imageUrl': user.imageUrl,
        'role': user.role.value,
        'professionalType': user.role == UserRole.professional
            ? user.professionalType?.value
            : null,
        'validationDocumentBase64': documentBase64,
        'validationDocumentFileName': documentFileName,
      };

      if (profileImageBase64 != null && profileImageFileName != null) {
        body['profileImageBase64'] = profileImageBase64;
        body['profileImageFileName'] = profileImageFileName;
      }

      if (description != null) {
        body['description'] = description;
      }

      final response = await _client.functions.invoke(
        'create-account',
        body: body,
      );

      if (response.status == 201) {
        final data = response.data as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>;

        return StrautilsResponse.success(UserModel.fromMap(userData));
      } else {
        Map<String, dynamic>? error;
        if (response.data is Map) {
          error = response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          try {
            error =
                json.decode(response.data as String) as Map<String, dynamic>;
          } catch (e) {
            error = {'error': response.data};
          }
        } else {
          error = {'error': response.data?.toString() ?? 'Erro desconhecido'};
        }

        final errorMessage = _formatErrorMessage(error);
        return StrautilsResponse.error(errorMessage);
      }
    }, action: 'criar conta com email e documento.');
  }

  FStrautilsResponse<bool> validateEmail(String email) {
    return tryThis(() async {
      final response = await _client.rpc(
        'validate_user_email',
        params: {'user_email': email},
      );

      return StrautilsResponse.success(response as bool);
    }, action: 'validar email.');
  }

  FStrautilsResponse<String?> updateProfilePhoto({
    required String userId,
    required String imageBase64,
    required String fileName,
  }) {
    return tryThis(() async {
      final bytes = base64Decode(imageBase64);

      final extension = fileName.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      }

      final storagePath =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _client.storage
          .from('profile-photos')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      final publicUrl = _client.storage
          .from('profile-photos')
          .getPublicUrl(storagePath);

      await _client
          .from('tb_users')
          .update({'image_url': publicUrl})
          .eq('id', userId);

      return StrautilsResponse.success(publicUrl);
    }, action: 'atualizar foto de perfil.');
  }

  FStrautilsResponse<UserModel?> updateProfile({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    String? description,
  }) {
    return tryThis(() async {
      // Update user data
      final userResponse = await _client
          .from('tb_users')
          .update({
            'full_name': fullName,
            'email': email,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .maybeSingle();

      if (userResponse == null) {
        return StrautilsResponse.error('Usuário não encontrado');
      }

      // Update professional description if provided
      if (description != null) {
        await _client
            .from('tb_professionals')
            .update({'description': description})
            .eq('user_id', userId);
      }

      return StrautilsResponse.success(UserModel.fromMap(userResponse));
    }, action: 'atualizar perfil.');
  }

  FStrautilsResponse<bool> deleteAccount(String userId) {
    return tryThis(() async {
      await Supabase.instance.client.functions.invoke(
        'delete-account',
        body: {'user_id': userId},
      );

      return StrautilsResponse.success(true);
    }, action: 'excluir conta.');
  }

  String _formatErrorMessage(Map<String, dynamic> error) {
    final errorMessage = error['error']?.toString().toLowerCase() ?? '';
    if (errorMessage.contains('ja existe um usuario com este email') ||
        errorMessage.contains('já existe um usuário com este email') ||
        errorMessage.contains('ja existe um usuário com este email') ||
        errorMessage.contains('já existe um usuario com este email')) {
      return 'Este email já está cadastrado. Por favor, use outro email ou faça login.';
    }

    final nestedDetails = error['details'];
    if (nestedDetails is Map) {
      final deepDetailsString = nestedDetails['details'] as String?;
      if (deepDetailsString != null) {
        final detailsLower = deepDetailsString.toLowerCase();

        if (detailsLower.contains('cpf_document') &&
            detailsLower.contains('already exists')) {
          return 'Este CPF já está cadastrado. Por favor, use outro CPF ou faça login.';
        }

        if (detailsLower.contains('email') &&
            detailsLower.contains('already exists')) {
          return 'Este email já está cadastrado. Por favor, use outro email ou faça login.';
        }

        if (detailsLower.contains('phone') &&
            detailsLower.contains('already exists')) {
          return 'Este telefone já está cadastrado. Por favor, use outro telefone.';
        }
      }

      final nestedMessage = nestedDetails['message'] as String?;
      if (nestedMessage != null) {
        final messageLower = nestedMessage.toLowerCase();

        if (messageLower.contains('tb_users_cpf_document_key') ||
            (messageLower.contains('cpf_document') &&
                (messageLower.contains('duplicate') ||
                    messageLower.contains('unique constraint')))) {
          return 'Este CPF já está cadastrado. Por favor, use outro CPF ou faça login.';
        }

        if (messageLower.contains('tb_users_email_key') ||
            (messageLower.contains('email') &&
                (messageLower.contains('duplicate') ||
                    messageLower.contains('unique constraint')))) {
          return 'Este email já está cadastrado. Por favor, use outro email ou faça login.';
        }

        if (messageLower.contains('tb_users_phone_key') ||
            (messageLower.contains('phone') &&
                (messageLower.contains('duplicate') ||
                    messageLower.contains('unique constraint')))) {
          return 'Este telefone já está cadastrado. Por favor, use outro telefone.';
        }

        return nestedMessage;
      }
    }

    if (error.containsKey('details') && error['details'] != null) {
      final details = error['details'];
      if (details is List) {
        final errorMessages = details
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
        if (errorMessages.isNotEmpty) {
          if (errorMessages.length == 1) {
            return errorMessages.first;
          }
          return errorMessages.join(', ');
        }
      } else if (details is Map) {
        final message = details['message'] ?? details['error'];
        if (message != null) {
          return message.toString();
        }
      } else if (details is String) {
        return details;
      }
    }

    final mainErrorMessage = error['error'];
    if (mainErrorMessage != null) {
      return mainErrorMessage.toString();
    }

    return 'Erro ao criar usuário';
  }
}
