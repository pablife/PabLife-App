import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      resetCachedDecorations();
      WidgetsBinding.instance.reassembleApplication();
    });
  }

  /// O Flutter guarda a tinta do fundo de cada caixa. Como as cores são
  /// constantes, a caixa não percebe a troca de paleta e seguiria com a cor
  /// antiga: trocar a decoração descarta essa tinta guardada.
  @visibleForTesting
  static void resetCachedDecorations() {
    void visit(Element element) {
      final renderObject = element.renderObject;
      if (element is RenderObjectElement &&
          renderObject is RenderDecoratedBox) {
        final decoration = renderObject.decoration;
        renderObject.decoration = const BoxDecoration();
        renderObject.decoration = decoration;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }

  static const _normalSeed = Color(0xFF052F33);
  static const _roseSeed = Color(0xFF3A1D4F);

  static ThemeData get currentTheme =>
      appTheme(isRose ? _roseSeed : _normalSeed);
}

/// Tema base do app; muda só a cor de origem.
ThemeData appTheme(Color seed) {
  const family = 'PlusJakartaSans';
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
    AppPalette.isRose
        ? (_rose ?? _roseColors[_normal] ?? _normal)
        : (_pablifeColors[_normal] ?? _normal),
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

/// Cores antigas => paleta Pablife da repaginação (spec "Identidade visual").
/// As telas antigas ganham as cores novas sem mudar cada uma.
const _pablifeColors = <int, int>{
  // Escuros: topo, textos e botões.
  0xFF00343C: 0xFF052F33,
  0xFF00343D: 0xFF052F33,
  0xFF01424C: 0xFF052F33,
  0xFF082C32: 0xFF04262A,
  0xFF00262C: 0xFF04262A,
  0xFF0A3A42: 0xFF0B4146,
  0xFF033138: 0xFF0B4146,
  0xFF001417: 0xFF031E21,
  0xFF01181C: 0xFF031E21,
  0xFF374957: 0xFF4A5E60,
  // Painéis lilás viram fundo claro e cartões brancos.
  0xFFC1CDFF: 0xFFF4F7F7,
  0xFFC1CDFE: 0xFFF4F7F7,
  0xFFC0CDFF: 0xFFF4F7F7,
  0xFFAEBEEC: 0xFFFFFFFF,
  0xFFAFCDDB: 0xFFFFFFFF,
  0xFFA9B6EA: 0xFFDCE7E6,
  0xFFD0D7F5: 0xFFE3F6F5,
  0xFFD0D8E8: 0xFFE3F6F5,
  0xFFBFC9E5: 0xFFE3F6F5,
  // Destaques.
  0xFF0C8DA1: 0xFF0E7C78,
  0xFF007AFF: 0xFF0E7C78,
  0xFF3065FF: 0xFF3F3A8C,
  0xFF00C2A8: 0xFF13B8B2,
  0xFF95B0FF: 0xFF9DE3E0,
  0xFF9BB1F1: 0xFF9DE3E0,
};

/// Cor normal => cor rosé. Escuro continua escuro e claro continua claro, para
/// o texto seguir legível. Vermelho de erro, WhatsApp e cinzas ficam iguais.
const _roseColors = <int, int>{
  // Escuros (fundos e textos).
  0xFF00343C: 0xFF3A1D4F,
  0xFF00343D: 0xFF3A1D4F,
  0xFF01424C: 0xFF3A1D4F,
  0xFF082C32: 0xFF2B1440,
  0xFF00262C: 0xFF2B1440,
  0xFF001417: 0xFF22102E,
  0xFF01181C: 0xFF22102E,
  0xFF0A3A42: 0xFF4E2F66,
  0xFF033138: 0xFF4E2F66,
  0xFF06505B: 0xFF5E4A66,
  0xFF2D5A5A: 0xFF5E4A66,
  0xFF374957: 0xFF5E4A66,
  0xFF085041: 0xFF5E4A66,
  0xFF006064: 0xFF5E4A66,
  0xFF0F4C75: 0xFF5E4A66,
  0xFF0C6B7A: 0xFF5E4A66,
  0xFF22717D: 0xFF76657B,
  0xFF056574: 0xFF76657B,
  // Claros (painéis e textos sobre fundo escuro).
  0xFFC1CDFF: 0xFFFBF6FA,
  0xFFC1CDFE: 0xFFFBF6FA,
  0xFFC0CDFF: 0xFFFBF6FA,
  0xFFAEBEEC: 0xFFFFFFFF,
  0xFFAFCDDB: 0xFFFFFFFF,
  0xFFCDE5DB: 0xFFFFFFFF,
  0xFFC8E0D8: 0xFFFFFFFF,
  0xFFA9B6EA: 0xFFEEDDE9,
  0xFFD0D7F5: 0xFFF3E8EF,
  0xFFD0D8E8: 0xFFF3E8EF,
  0xFFBFC9E5: 0xFFFCE8F3,
  0xFFA9C9CE: 0xFFFCE8F3,
  0xFFD3CAB5: 0xFFFCE8F3,
  0xFFE7F6F7: 0xFFFCE8F3,
  0xFFE6F7F1: 0xFFFCE8F3,
  0xFFE0F7FA: 0xFFFCE8F3,
  0xFFF5FAFF: 0xFFFBF6FA,
  0xFFF5F3FF: 0xFFFBF6FA,
  // Destaques.
  0xFF0C8DA1: 0xFFA8336F,
  0xFF3065FF: 0xFFA8336F,
  0xFF007AFF: 0xFFA8336F,
  0xFF00C2A8: 0xFFC2417F,
  0xFF00A86B: 0xFFC2417F,
  0xFF1D9E75: 0xFFC2417F,
  0xFF0F6E56: 0xFFC2417F,
  0xFF017D93: 0xFFC2417F,
  0xFF0F8799: 0xFFC2417F,
  0xFF92CA4F: 0xFFC2417F,
  0xFF9A870C: 0xFFC2417F,
  0xFF95B0FF: 0xFFFFC2E6,
  0xFF9BB1F1: 0xFFFFC2E6,
  0xFF89BEC6: 0xFFE9A6CF,
  0xFF9ECAD0: 0xFFE9A6CF,
  0xFF9BD3CC: 0xFFE9A6CF,
  0xFF9FE1CB: 0xFFE9A6CF,
  0xFF90EE90: 0xFFE9A6CF,
  0xFFD2CC61: 0xFFE9A6CF,
  0xFF3D3A10: 0xFF2B1440,
  0xFFFF80BD: 0xFFFFC2E6,
  0xFFDA879A: 0xFFFFC2E6,
  0xFFFF3395: 0xFFA8336F,
  0xFFE0567A: 0xFFA8336F,
  0xFF8E99A8: 0xFF9C8CA8,
  0xFFB3A57F: 0xFF9C8CA8,
};
