import 'package:flutter/painting.dart';

import 'app_palette.dart';

/// Cores da repaginação (spec "Identidade visual"). A primeira é a do visual
/// Pablife; a segunda, a do visual Saúde da Mulher. A troca é automática.
abstract final class PabColors {
  /// Topo, barra inferior, textos principais e botões escuros.
  static const ink = AppColor.pair(0xFF052F33, 0xFF3A1D4F);

  /// Botão principal (texto em [ink]), item ativo, seleção.
  static const accent = AppColor.pair(0xFF13B8B2, 0xFFFF8ECF);

  /// Links e destaques sobre branco.
  static const accentText = AppColor.pair(0xFF0E7C78, 0xFFA8336F);

  /// Fundo das telas.
  static const background = AppColor.pair(0xFFF4F7F7, 0xFFFBF6FA);

  static const card = Color(0xFFFFFFFF);
  static const line = AppColor.pair(0xFFDCE7E6, 0xFFEEDDE9);
  static const lineStrong = AppColor.pair(0xFFCFE3E2, 0xFFE9A6CF);

  /// Legendas e textos de apoio.
  static const muted = AppColor.pair(0xFF4A5E60, 0xFF5E4A66);

  /// Texto claro sobre [ink].
  static const onInk = Color(0xFFFBFAFC);

  /// Textos de apoio sobre [ink] (saudação, legendas do topo).
  static const onInkSoft = AppColor.pair(0xFF9DE3E0, 0xFFFFC2E6);

  /// Ícones e nomes da barra inferior quando não estão ativos.
  static const navIdle = AppColor.pair(0xFFC9D8D9, 0xFFDCCBE3);

  /// Fundo suave dos ícones e avisos (com [softText]).
  static const soft = AppColor.pair(0xFFE3F6F5, 0xFFFCE8F3);
  static const softText = AppColor.pair(0xFF0B5754, 0xFF7A1F52);

  /// Trilho de barras de progresso e dias sem horário.
  static const track = AppColor.pair(0xFFE9EEEE, 0xFFEDE4EB);

  /// Destaques suaves: atalhos e avisos neutros.
  static const lilac = Color(0xFFEEEDFF);
  static const lilacText = Color(0xFF3F3A8C);

  /// Selo de notificações e marcação de "hoje".
  static const pink = Color(0xFFFF8ECF);

  /// Ações destrutivas.
  static const error = Color(0xFFA3263F);
  static const errorLine = Color(0xFFF2C4CF);

  /// Ciclo (Saúde da Mulher).
  static const menstruation = Color(0xFFD63A74);
  static const fertile = Color(0xFF8D84F0);
}

/// Fonte da repaginação.
const pabFontFamily = 'PlusJakartaSans';
