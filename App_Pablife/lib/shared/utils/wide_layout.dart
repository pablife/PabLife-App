import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../themes/app_colors.dart';

/// Telas a partir desta largura (navegador do computador) usam o layout
/// próprio para web: menu lateral e conteúdo em colunas.
const double wideLayoutBreakpoint = 900;

bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideLayoutBreakpoint;

/// No navegador do celular, o selo "Powered by Netlify" (obrigatório no plano
/// gratuito da Netlify) fica fixo no canto de baixo da tela. Esta faixa
/// reserva o espaço dele para o selo não cobrir o menu e os botões do app.
class WebBadgeSpace extends StatelessWidget {
  final Widget child;

  static const height = 56.0;

  const WebBadgeSpace({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || isWideLayout(context)) return child;
    return ColoredBox(
      color: AppColors.aqua,
      child: Padding(
        padding: const EdgeInsets.only(bottom: height),
        child: child,
      ),
    );
  }
}

/// Em telas largas, mostra [child] numa coluna centralizada de até
/// [maxWidth], para telas desenhadas para celular não esticarem.
class WideCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WideCenter({super.key, required this.child, this.maxWidth = 960});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!isWideLayout(context) || media.size.width <= maxWidth) return child;

    return ColoredBox(
      color: AppColors.aqua,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(
            data: media.copyWith(size: Size(maxWidth, media.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Em telas largas mais baixas (notebook), desenha o app um pouco menor
/// para as telas caberem sem cortar, como num zoom de navegador.
class WideScale extends StatelessWidget {
  final Widget child;

  /// Altura (em pixels lógicos) que as telas precisam para caber bem.
  static const _comfortableHeight = 900.0;
  static const _minScale = 0.75;

  const WideScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    if (size.width < wideLayoutBreakpoint) return child;

    final scale = (size.height / _comfortableHeight).clamp(_minScale, 1.0);
    if (scale == 1.0) return child;

    final scaledSize = size / scale;
    // A OverflowBox fica por fora: ela tem o tamanho da tela, então aceita
    // cliques em toda a área; o Transform reduz o conteúdo maior lá dentro.
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: scaledSize.width,
        maxWidth: scaledSize.width,
        minHeight: scaledSize.height,
        maxHeight: scaledSize.height,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: MediaQuery(
            data: media.copyWith(size: scaledSize),
            child: child,
          ),
        ),
      ),
    );
  }
}
