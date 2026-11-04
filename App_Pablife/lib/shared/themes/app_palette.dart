import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Paleta do app inteiro: a normal ou a rosé (modo Saúde da mulher). As cores
/// são escritas como `AppColor(0xFF...)`, com o valor da paleta normal; a
/// tabela abaixo diz qual cor entra no lugar dela na paleta rosé.
abstract final class AppPalette {
  static bool isRose = false;

  static const _storageKey = 'app_palette_rose';

  /// Volta com a paleta escolhida ao abrir o app, antes da primeira tela
  /// (assim ela continua mesmo depois de sair da conta).
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    isRose = prefs.getBool(_storageKey) ?? false;
  }

  /// Troca a paleta e redesenha todas as telas abertas.
  static void apply(bool rose) {
    if (isRose == rose) return;
    isRose = rose;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_storageKey, rose),
    );
    Get.changeTheme(appTheme(rose ? _roseSeed : _normalSeed));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.reassembleApplication();
    });
  }

  static const _normalSeed = Color(0xFF00343D);
  static const _roseSeed = Color(0xFF4A3560);

  static ThemeData get currentTheme =>
      appTheme(isRose ? _roseSeed : _normalSeed);
}

/// Tema base do app; muda só a cor de origem.
ThemeData appTheme(Color seed) {
  const family = 'InstrumentSans';
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    fontFamily: family,
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: family),
      displayMedium: TextStyle(fontFamily: family),
      displaySmall: TextStyle(fontFamily: family),
      headlineLarge: TextStyle(fontFamily: family),
      headlineMedium: TextStyle(fontFamily: family),
      headlineSmall: TextStyle(fontFamily: family),
      titleLarge: TextStyle(fontFamily: family),
      titleMedium: TextStyle(fontFamily: family),
      titleSmall: TextStyle(fontFamily: family),
      bodyLarge: TextStyle(fontFamily: family),
      bodyMedium: TextStyle(fontFamily: family),
      bodySmall: TextStyle(fontFamily: family),
      labelLarge: TextStyle(fontFamily: family),
      labelMedium: TextStyle(fontFamily: family),
      labelSmall: TextStyle(fontFamily: family),
    ),
  );
}

/// Cor que segue a paleta atual. Continua constante, então pode ser usada
/// em qualquer lugar onde `Color(...)` era usada.
class AppColor extends Color {
  final int _normal;
  final int? _rose;

  const AppColor(int normal) : _normal = normal, _rose = null, super(normal);

  /// Para quando a cor rosé não é a da tabela (ex.: fundo claro do planner).
  const AppColor.pair(int normal, int rose)
    : _normal = normal,
      _rose = rose,
      super(normal);

  Color get _current => Color(
    AppPalette.isRose ? (_rose ?? _roseColors[_normal] ?? _normal) : _normal,
  );

  @override
  double get a => _current.a;

  @override
  double get r => _current.r;

  @override
  double get g => _current.g;

  @override
  double get b => _current.b;

  @override
  // ignore: deprecated_member_use
  int get value => _current.value;
}

/// Cor normal => cor rosé. Escuro continua escuro e claro continua claro, para
/// o texto seguir legível. Vermelho de erro, WhatsApp e cinzas ficam iguais.
const _roseColors = <int, int>{
  // Escuros (fundos e textos).
  0xFF00343C: 0xFF4A3560,
  0xFF00343D: 0xFF4A3560,
  0xFF01424C: 0xFF4A3560,
  0xFF082C32: 0xFF2E1F3F,
  0xFF00262C: 0xFF2E1F3F,
  0xFF001417: 0xFF1F1430,
  0xFF01181C: 0xFF1F1430,
  0xFF0A3A42: 0xFF3B2A4D,
  0xFF033138: 0xFF3B2A4D,
  0xFF06505B: 0xFF5A466E,
  0xFF2D5A5A: 0xFF5A466E,
  0xFF374957: 0xFF5A466E,
  0xFF085041: 0xFF5A466E,
  0xFF006064: 0xFF5A466E,
  0xFF0F4C75: 0xFF5A466E,
  0xFF0C6B7A: 0xFF5A466E,
  0xFF22717D: 0xFF6A5384,
  0xFF056574: 0xFF6A5384,
  // Claros (painéis e textos sobre fundo escuro).
  0xFFC1CDFF: 0xFFF4EEE9,
  0xFFC1CDFE: 0xFFF4EEE9,
  0xFFC0CDFF: 0xFFF4EEE9,
  0xFFAEBEEC: 0xFFE3D8F8,
  0xFFAFCDDB: 0xFFE3D8F8,
  0xFFCDE5DB: 0xFFE3D8F8,
  0xFFC8E0D8: 0xFFE3D8F8,
  0xFFA9B6EA: 0xFFD6C8DE,
  0xFFD0D7F5: 0xFFEADFEA,
  0xFFD0D8E8: 0xFFEADFEA,
  0xFFBFC9E5: 0xFFE6D9E8,
  0xFFA9C9CE: 0xFFE6D9E8,
  0xFFD3CAB5: 0xFFE6D9E8,
  0xFFE7F6F7: 0xFFF1E7EE,
  0xFFE6F7F1: 0xFFF1E7EE,
  0xFFE0F7FA: 0xFFF1E7EE,
  0xFFF5FAFF: 0xFFFBF8F6,
  0xFFF5F3FF: 0xFFFBF8F6,
  // Destaques.
  0xFF0C8DA1: 0xFF8F72E0,
  0xFF3065FF: 0xFF8F72E0,
  0xFF007AFF: 0xFF8F72E0,
  0xFF00C2A8: 0xFF7A5FB8,
  0xFF00A86B: 0xFF7A5FB8,
  0xFF1D9E75: 0xFF7A5FB8,
  0xFF0F6E56: 0xFF7A5FB8,
  0xFF017D93: 0xFF7A5FB8,
  0xFF0F8799: 0xFF7A5FB8,
  0xFF92CA4F: 0xFF7A5FB8,
  0xFF9A870C: 0xFF7A5FB8,
  0xFF95B0FF: 0xFFAD94EE,
  0xFF9BB1F1: 0xFFAD94EE,
  0xFF89BEC6: 0xFFD6A6DB,
  0xFF9ECAD0: 0xFFD6A6DB,
  0xFF9BD3CC: 0xFFD6A6DB,
  0xFF9FE1CB: 0xFFD6A6DB,
  0xFF90EE90: 0xFFD6A6DB,
  0xFFD2CC61: 0xFFD6A6DB,
  0xFF3D3A10: 0xFF2E1F3F,
  0xFFFF80BD: 0xFFEEC3D8,
  0xFFDA879A: 0xFFEEC3D8,
  0xFFFF3395: 0xFFB0477A,
  0xFFE0567A: 0xFFB0477A,
  0xFF8E99A8: 0xFF9C8CA8,
  0xFFB3A57F: 0xFF9C8CA8,
};
