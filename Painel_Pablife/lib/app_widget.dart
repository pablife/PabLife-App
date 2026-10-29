import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'app_controller.dart';
import 'app_routes.dart';
import 'shared/themes/app_themes.dart';
import 'shared/controllers/layout_controller.dart';
import 'widgets/layout/admin_layout.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PabLife - Painel Administrativo',
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      getPages: AppRoutes.routes,
      defaultTransition: Transition.noTransition,
      transitionDuration: Duration.zero,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialBinding: BindingsBuilder(() {
        Get.put(AppController(), permanent: true);
        Get.put(LayoutController(), permanent: true);
      }),
      routingCallback: (routing) {
        if (routing != null) {
          Get.find<LayoutController>().checkFullScreen(routing.current);
        }
      },
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        // Usa GetBuilder para reagir às mudanças do isFullScreen
        return GetBuilder<LayoutController>(
          builder: (controller) {
            // Se for rota fullscreen (login, splash), retorna direto sem AdminLayout
            if (controller.isFullScreen) {
              return child;
            }
            // Caso contrário, envolve com AdminLayout
            return AdminLayout(body: child);
          },
        );
      },
    );
  }
}
