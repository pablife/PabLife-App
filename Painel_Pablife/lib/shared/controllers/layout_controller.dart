import 'package:get/get.dart';

class LayoutController extends GetxController {
  bool isCollapsed = false;
  String pageTitle = '';
  bool isFullScreen = false;
  String currentRoute = '';

  void toggleSidebar() {
    isCollapsed = !isCollapsed;
    update(['sidebar']);
  }

  void setCollapsed(bool value) {
    if (isCollapsed != value) {
      isCollapsed = value;
      update(['sidebar']);
    }
  }

  void updateTitle(String title) {
    if (pageTitle != title) {
      // Delay para evitar erro de build durante renderização
      Future.microtask(() {
        pageTitle = title;
        update(['header']);
      });
    }
  }

  void checkFullScreen(String? route) {
    if (route == null) return;
    currentRoute = route;

    // Normaliza a rota removendo barra final (exceto para '/')
    final normalizedRoute = route.length > 1 && route.endsWith('/')
        ? route.substring(0, route.length - 1)
        : route;

    // Lista de rotas que nao devem exibir o layout administrativo
    // Inclui rotas publicas acessiveis sem autenticacao
    const fullScreenRoutes = [
      '/',
      '/login',
      '/splash',
      '/politica-de-privacidade',
    ];

    final isFull = fullScreenRoutes.contains(normalizedRoute);

    // Só atualiza se houver mudança real de estado
    if (isFullScreen != isFull) {
      isFullScreen = isFull;
      // Delay para evitar erro de build durante renderização
      // Notifica todos os listeners (sidebar e layout)
      Future.microtask(() => update());
    } else {
      // Se apenas a rota mudou mas o modo fullscreen não,
      // precisamos atualizar para a sidebar saber qual item selecionar
      // Notifica sidebar e header
      Future.microtask(() {
        update(['sidebar']);
        update(['header']);
      });
    }
  }
}
