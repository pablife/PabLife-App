import 'dart:convert';

import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../infra/models/subscription_plan_model.dart';
import '../../../infra/models/user_model.dart';
import '../../../infra/models/user_subscription_model.dart';
import '../../../infra/repositories/payment_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../shared/utils/payment_status_messages.dart';
import 'subscription_controller.dart';

class CheckoutController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final _paymentRepository = PaymentRepository();

  // Controllers do formulário
  final cardNumberController = TextEditingController();
  final cardHolderNameController = TextEditingController();
  final cardHolderCpfController = TextEditingController();
  final expirationMonthController = TextEditingController();
  final expirationYearController = TextEditingController();
  final securityCodeController = TextEditingController();

  // Estado
  SubscriptionPlanModel? _selectedPlan;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  String _idempotencyKey = '';
  int _pollingToken = 0;
  bool _isDisposed = false;

  static const Duration _pollInterval = Duration(seconds: 8);
  static const Duration _pollTimeout = Duration(minutes: 2);

  // Getters
  SubscriptionPlanModel? get selectedPlan => _selectedPlan;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  String get idempotencyKey => _idempotencyKey;

  String get cardNumber => cardNumberController.text.replaceAll(' ', '');
  String get cardHolderName => cardHolderNameController.text;
  String get cardHolderCpf =>
      cardHolderCpfController.text.replaceAll(RegExp(r'\D'), '');

  String get displayCardHolderName {
    if (cardHolderName.isEmpty) return 'NOME DO TITULAR';
    return cardHolderName.toUpperCase();
  }

  String get expirationMonth => expirationMonthController.text.padLeft(2, '0');
  String get expirationYear => expirationYearController.text;
  String get securityCode => securityCodeController.text;

  String get maskedCardNumber {
    if (cardNumber.isEmpty) return '**** **** **** ****';

    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.length < 4) {
      final visible = cleanNumber.padRight(4, '*');
      return '**** **** **** $visible';
    } else {
      final lastFour = cleanNumber.substring(cleanNumber.length - 4);
      return '**** **** **** $lastFour';
    }
  }

  String get cardBrandDisplayName {
    if (cardNumber.isEmpty) return 'CARTÃO';

    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.startsWith('4')) return 'VISA';
    if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
      return 'MASTERCARD';
    }
    if (cleanNumber.startsWith('3')) return 'AMERICAN EXPRESS';
    if (cleanNumber.startsWith('6')) return 'DISCOVER';
    return 'CARTÃO';
  }

  String get formattedExpirationDate {
    if (expirationMonth.isEmpty && expirationYear.isEmpty) return 'MM/AA';

    final month = expirationMonth.isEmpty
        ? 'MM'
        : expirationMonth.padLeft(2, '0');
    final year = expirationYear.isEmpty
        ? 'AA'
        : expirationYear.length == 4
        ? expirationYear.substring(2)
        : expirationYear;

    return '$month/$year';
  }

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    _loadCurrentUser();
    _addTextListeners();
    _idempotencyKey = _generateIdempotencyKey();
  }

  @override
  void onClose() {
    _isDisposed = true;
    _pollingToken++;
    _removeTextListeners();
    cardNumberController.dispose();
    cardHolderNameController.dispose();
    cardHolderCpfController.dispose();
    expirationMonthController.dispose();
    expirationYearController.dispose();
    securityCodeController.dispose();
    super.onClose();
  }

  void _addTextListeners() {
    cardNumberController.addListener(_onTextChanged);
    cardHolderNameController.addListener(_onTextChanged);
    expirationMonthController.addListener(_onTextChanged);
    expirationYearController.addListener(_onTextChanged);
  }

  void _removeTextListeners() {
    cardNumberController.removeListener(_onTextChanged);
    cardHolderNameController.removeListener(_onTextChanged);
    expirationMonthController.removeListener(_onTextChanged);
    expirationYearController.removeListener(_onTextChanged);
  }

  String _generateIdempotencyKey() {
    return const Uuid().v4();
  }

  void _resetIdempotencyKey() {
    _idempotencyKey = _generateIdempotencyKey();
  }

  void _onTextChanged() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) {
        update();
      }
    });
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['plan'] != null) {
      _selectedPlan = args['plan'] as SubscriptionPlanModel;
      update();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('tb_users')
            .select()
            .eq('id', user.id)
            .single();

        _currentUser = UserModel.fromMap(response);
        final cpfDocument = _currentUser?.cpfDocument ?? '';
        if (cpfDocument.isNotEmpty &&
            cardHolderCpfController.text.trim().isEmpty) {
          cardHolderCpfController.text = _formatCpfOrCnpj(cpfDocument);
        }
        update();
      }
    } catch (e) {
      debugPrint('Erro ao carregar usuário: $e');
    }
  }

  String _formatCpfOrCnpj(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return CPFValidator.format(digits);
    }
    if (digits.length == 14) {
      return CNPJValidator.format(digits);
    }
    return digits;
  }

  Future<void> processPayment() async {
    if (!formKey.currentState!.validate()) {
      AppSnackbar.to.show('Por favor, preencha todos os campos corretamente');
      return;
    }

    if (_selectedPlan == null) {
      AppSnackbar.to.show('Plano não selecionado');
      return;
    }

    if (_currentUser == null) {
      AppSnackbar.to.show('Usuário não encontrado');
      return;
    }

    _isLoading = true;
    _isProcessingPayment = true;
    update();

    try {
      final response = await _paymentRepository.createSubscription(
        planId: _selectedPlan!.id,
        idempotencyKey: _idempotencyKey,
        card: {
          'name': cardHolderName,
          'cpfOrCnpj': cardHolderCpf,
          'cardNumber': cardNumber,
          'expirationMonth': int.parse(expirationMonth),
          'expirationYear': int.parse(expirationYear),
          'securityCode': securityCode,
        },
      );

      if (response.success) {
        final data = response.data ?? <String, dynamic>{};
        final subscriptionData =
            data['subscription'] as Map<String, dynamic>?;
        final paymentData = data['payment'] as Map<String, dynamic>?;

        final preapprovalId = subscriptionData?['preapproval_id'] as String?;
        final subscriptionId =
            _extractSubscriptionId(paymentData?['external_reference'] as String?) ??
                _extractSubscriptionId(
                    subscriptionData?['external_reference'] as String?);

        final result = await _pollSubscriptionUntilDone(
          subscriptionId: subscriptionId,
          preapprovalId: preapprovalId,
        );

        if (result == _SubscriptionPollingResult.active) {
          final subscriptionController = Get.find<SubscriptionController>();
          subscriptionController.reload();
          await AuthService.instance.reloadUserAccessInfo();

          Get.back();
          AppSnackbar.to.show('Assinatura criada com sucesso!');
        } else if (result == _SubscriptionPollingResult.cancelled) {
          AppSnackbar.to.show(
            'Pagamento não aprovado. Tente novamente.',
          );
          _resetIdempotencyKey();
        } else {
          final subscription = subscriptionId != null
              ? await _fetchSubscriptionById(subscriptionId)
              : await _fetchSubscriptionByPreapprovalId(preapprovalId);
          final pendingMessage = await _buildPendingPaymentMessage(
            subscription,
          );
          final subscriptionController = Get.find<SubscriptionController>();
          Get.back();
          subscriptionController.reload();
          AppSnackbar.to.show(
            pendingMessage ??
                'Não foi possível confirmar o pagamento. Tente novamente.',
          );
        }
      } else {
        final errorPayload = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final errorCode = errorPayload['code'] as String?;
        final subscriptionId = errorPayload['user_subscription_id'] as String?;
        final userMessage = _buildUserErrorMessage(errorPayload, response.message);
        final errorStatus = (errorPayload['status'] as String?)?.toLowerCase();
        final errorStatusDetail = errorPayload['status_detail'] as String?;

        if (errorCode == 'PAYMENT_CREATE_FAILED') {
          AppSnackbar.to.show(userMessage);
        } else if (errorCode == 'PAYMENT_NOT_APPROVED') {
          if (errorStatus == 'rejected' ||
              errorStatus == 'cancelled' ||
              errorStatus == 'charged_back' ||
              errorStatus == 'refunded') {
            final subscription = await _fetchSubscriptionById(subscriptionId);
            if (subscription?.status == 'cancelled') {
              _resetIdempotencyKey();
            }
            AppSnackbar.to.show(userMessage);
            return;
          }

          final transactionResult = await _pollTransactionUntilApproved(
            userSubscriptionId: subscriptionId,
            lastKnownStatus: errorStatus,
            lastKnownStatusDetail: errorStatusDetail,
          );

          if (transactionResult == _TransactionPollingResult.approved) {
            final subscriptionResult = await _pollSubscriptionUntilDone(
              subscriptionId: subscriptionId,
            );
            if (subscriptionResult == _SubscriptionPollingResult.active) {
              final subscriptionController = Get.find<SubscriptionController>();
              subscriptionController.reload();
              await AuthService.instance.reloadUserAccessInfo();
              Get.back();
              AppSnackbar.to.show('Assinatura criada com sucesso!');
            } else if (subscriptionResult ==
                _SubscriptionPollingResult.cancelled) {
              AppSnackbar.to.show(
                'Pagamento não aprovado. Tente novamente.',
              );
              _resetIdempotencyKey();
            } else {
              AppSnackbar.to.show(
                'Não foi possível confirmar o pagamento. Tente novamente.',
              );
            }
          } else if (transactionResult == _TransactionPollingResult.rejected) {
            final subscription = await _fetchSubscriptionById(subscriptionId);
            if (subscription?.status == 'cancelled') {
              _resetIdempotencyKey();
            }
            AppSnackbar.to.show(userMessage);
          } else if (transactionResult.type == 'processing') {
            final message = _buildProcessingMessage(
              status: transactionResult.status,
              statusDetail: transactionResult.statusDetail,
            );
            final subscriptionController = Get.find<SubscriptionController>();
            Get.back();
            subscriptionController.reload();
            AppSnackbar.to.show(message);
          } else {
            AppSnackbar.to.show(userMessage);
          }
        } else {
          Get.snackbar(
            'Erro',
            userMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao criar assinatura: $e');
      AppSnackbar.to.show(
        'Ocorreu um erro ao criar a assinatura. Tente novamente.',
      );
    } finally {
      _isLoading = false;
      _isProcessingPayment = false;
      update();
    }
  }

  String _buildUserErrorMessage(
    Map<String, dynamic> errorPayload,
    String fallbackMessage,
  ) {
    final code = (errorPayload['code'] as String?) ?? '';
    final details = errorPayload['details'];
    final status = (errorPayload['status'] as String?)?.toLowerCase();
    final statusDetail = errorPayload['status_detail'] as String?;

    switch (code) {
      case 'PAYMENT_CREATE_FAILED':
        return 'Não foi possível iniciar o pagamento. Tente novamente.';
      case 'PAYMENT_NOT_APPROVED':
        if (status != null && status.isNotEmpty) {
          return mapPaymentStatusMessage(
            status: status,
            statusDetail: statusDetail,
          );
        }
        return 'Pagamento não aprovado. Verifique os dados do cartão.';
      case 'VALIDATION_ERROR':
        return _mapValidationError(details) ??
            'Alguns dados são inválidos. Revise e tente novamente.';
      case 'INVALID_JSON':
        return 'Não foi possível processar os dados. Tente novamente.';
      case 'METHOD_NOT_ALLOWED':
        return 'Operação indisponível no momento. Tente novamente.';
      case 'INTERNAL_ERROR':
        return 'Erro interno. Tente novamente mais tarde.';
      default:
        return fallbackMessage.isNotEmpty
            ? fallbackMessage
            : 'Ocorreu um erro ao processar o pagamento. Tente novamente.';
    }
  }

  String _buildProcessingMessage({
    String? status,
    String? statusDetail,
  }) {
    final normalizedStatus = (status ?? '').toLowerCase();
    if (normalizedStatus.isEmpty) {
      return 'Pagamento em processamento. Aguarde a confirmação.';
    }
    return mapPaymentStatusMessage(
      status: normalizedStatus,
      statusDetail: statusDetail,
    );
  }

  String? _mapValidationError(dynamic details) {
    if (details is! List) return null;
    final first = details.isNotEmpty ? details.first : null;
    if (first is Map) {
      final path = first['path'];
      if (path is List && path.isNotEmpty) {
        final field = path.join('.');
        return 'Campo inválido: $field. Verifique e tente novamente.';
      }
    }
    return null;
  }

  String? _extractSubscriptionId(String? externalReference) {
    if (externalReference == null || externalReference.isEmpty) return null;
    try {
      final decoded = Map<String, dynamic>.from(
        jsonDecode(externalReference) as Map,
      );
      return decoded['user_subscription_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<UserSubscriptionModel?> _fetchSubscriptionById(
    String? subscriptionId,
  ) async {
    if (subscriptionId == null || subscriptionId.isEmpty) return null;
    final response = await Supabase.instance.client
        .from('tb_user_subscriptions')
        .select()
        .eq('id', subscriptionId)
        .maybeSingle();

    if (response == null) return null;
    return UserSubscriptionModel.fromMap(response);
  }

  Future<UserSubscriptionModel?> _fetchSubscriptionByPreapprovalId(
    String? preapprovalId,
  ) async {
    if (preapprovalId == null || preapprovalId.isEmpty) return null;
    final response = await Supabase.instance.client
        .from('tb_user_subscriptions')
        .select()
        .eq('mp_preapproval_id', preapprovalId)
        .maybeSingle();

    if (response == null) return null;
    return UserSubscriptionModel.fromMap(response);
  }

  Future<String?> _buildPendingPaymentMessage(
    UserSubscriptionModel? subscription,
  ) async {
    if (subscription == null) return null;
    if (subscription.status != 'pending') return null;

    final response = await Supabase.instance.client
        .from('tb_subscription_transactions')
        .select()
        .eq('user_subscription_id', subscription.id)
        .order('mp_date_created', ascending: false)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return 'Pagamento em processamento. Aguarde a confirmação.';
    }

    final status = (response['status'] as String?)?.toLowerCase() ?? 'pending';
    final statusDetail = response['status_detail'] as String?;
    return mapPaymentStatusMessage(
      status: status,
      statusDetail: statusDetail,
    );
  }

  Future<_SubscriptionPollingResult> _pollSubscriptionUntilDone({
    String? subscriptionId,
    String? preapprovalId,
  }) async {
    final token = ++_pollingToken;
    final startedAt = DateTime.now();

    while (!_isDisposed && token == _pollingToken) {
      if (DateTime.now().difference(startedAt) > _pollTimeout) {
        return _SubscriptionPollingResult.timeout;
      }

      final subscription = subscriptionId != null
          ? await _fetchSubscriptionById(subscriptionId)
          : await _fetchSubscriptionByPreapprovalId(preapprovalId);

      if (subscription != null) {
        final isActive =
            subscription.status == 'active' &&
            subscription.startDate != null &&
            subscription.endDate != null;
        if (isActive) return _SubscriptionPollingResult.active;
        if (subscription.status == 'cancelled') {
          return _SubscriptionPollingResult.cancelled;
        }
      }

      await Future.delayed(_pollInterval);
    }

    return _SubscriptionPollingResult.timeout;
  }

  Future<_TransactionPollingResult> _pollTransactionUntilApproved({
    required String? userSubscriptionId,
    String? lastKnownStatus,
    String? lastKnownStatusDetail,
  }) async {
    if (userSubscriptionId == null || userSubscriptionId.isEmpty) {
      return _TransactionPollingResult.timeout;
    }

    final token = ++_pollingToken;
    final startedAt = DateTime.now();
    String? lastStatus = lastKnownStatus;
    String? lastStatusDetail = lastKnownStatusDetail;

    while (!_isDisposed && token == _pollingToken) {
      if (DateTime.now().difference(startedAt) > _pollTimeout) {
        if (lastStatus == 'pending' || lastStatus == 'in_process') {
          return _TransactionPollingResult.processing(
            status: lastStatus,
            statusDetail: lastStatusDetail,
          );
        }
        return _TransactionPollingResult.timeout;
      }

      final response = await Supabase.instance.client
          .from('tb_subscription_transactions')
          .select()
          .eq('user_subscription_id', userSubscriptionId)
          .order('mp_date_created', ascending: false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final status = (response['status'] as String?)?.toLowerCase();
        final statusDetail = response['status_detail'] as String?;
        lastStatus = status;
        lastStatusDetail = statusDetail;
        if (status == 'approved') return _TransactionPollingResult.approved;
        if (status == 'rejected' ||
            status == 'cancelled' ||
            status == 'charged_back' ||
            status == 'refunded') {
          return _TransactionPollingResult.rejected;
        }
      }

      await Future.delayed(_pollInterval);
    }

    return _TransactionPollingResult.timeout;
  }
}

enum _SubscriptionPollingResult { active, cancelled, timeout }

class _TransactionPollingResult {
  final String type;
  final String? status;
  final String? statusDetail;

  const _TransactionPollingResult._(
    this.type, {
    this.status,
    this.statusDetail,
  });

  static const approved = _TransactionPollingResult._('approved');
  static const rejected = _TransactionPollingResult._('rejected');
  static const timeout = _TransactionPollingResult._('timeout');

  factory _TransactionPollingResult.processing({
    String? status,
    String? statusDetail,
  }) {
    return _TransactionPollingResult._(
      'processing',
      status: status,
      statusDetail: statusDetail,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _TransactionPollingResult && other.type == type;

  @override
  int get hashCode => type.hashCode;
}
