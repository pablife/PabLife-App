import 'package:flutter/foundation.dart';

/// Pedido para abrir "Criar horário" na Agenda, vindo do aviso "Você não tem
/// horários abertos" do Dashboard. A Agenda pode ainda não existir (abre
/// depois) ou já estar aberta em outra aba (escuta [tick]).
class CreateSlotRequest {
  CreateSlotRequest._();

  static bool _pending = false;
  static final tick = ValueNotifier<int>(0);

  static void ask() {
    _pending = true;
    tick.value++;
  }

  /// true uma única vez por pedido.
  static bool take() {
    final pending = _pending;
    _pending = false;
    return pending;
  }
}
