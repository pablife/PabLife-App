import 'package:flutter/material.dart';

class ResponsiveGridHelper {
  /// Calcula o número de colunas baseado na largura da tela
  /// - Tela muito pequena (< 600): 1 coluna
  /// - Tela pequena (600-900): 2 colunas
  /// - Tela média (900-1200): 3 colunas
  /// - Tela grande (1200-1600): 4 colunas
  /// - Tela muito grande (1600-2000): 5 colunas
  /// - Tela extra grande (> 2000): 6 colunas
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    if (width < 1600) return 4;
    if (width < 2000) return 5;
    return 6;
  }

  /// Retorna um delegate para grid responsivo
  static SliverGridDelegate getResponsiveGridDelegate(
    BuildContext context, {
    double childAspectRatio = 0.8,
    double crossAxisSpacing = 16,
    double mainAxisSpacing = 16,
    double? maxCrossAxisExtent,
  }) {
    if (maxCrossAxisExtent != null) {
      return SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      );
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: getGridCrossAxisCount(context),
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  /// Widget wrapper que limita o tamanho máximo de um card
  static Widget constrainedCard({
    required Widget child,
    double maxWidth = 400,
    double maxHeight = 500,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: child,
      ),
    );
  }
}
