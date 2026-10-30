import 'package:flutter/widgets.dart';

import '../themes/app_colors.dart';

/// Telas a partir desta largura (navegador do computador) usam o layout
/// próprio para web: menu lateral e conteúdo em colunas.
const double wideLayoutBreakpoint = 900;

bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideLayoutBreakpoint;

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
