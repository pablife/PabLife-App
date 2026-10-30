import 'package:flutter/widgets.dart';

/// Telas a partir desta largura (navegador do computador) usam o layout
/// próprio para web: menu lateral e conteúdo em colunas.
const double wideLayoutBreakpoint = 900;

bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideLayoutBreakpoint;
