import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/themes/app_colors.dart';
import '../../shared/controllers/layout_controller.dart';
import 'sidebar.dart';

class AdminLayout extends StatelessWidget {
  final Widget body;

  const AdminLayout({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LayoutController>(
      id: 'layout',
      builder: (controller) {
        // Se for tela cheia (login/splash), retorna apenas o body sem layout
        if (controller.isFullScreen) {
          return body;
        }

        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;

        return Scaffold(
          // backgroundColor: AppColors.background,
          body: Row(
            children: [
              // Sidebar sempre visível (exceto fullscreen)
              const Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    // Header
                    GetBuilder<LayoutController>(
                      id: 'header',
                      builder: (headerController) {
                        final theme = Theme.of(context);
                        return Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            // color: AppColors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.greyLight.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (!isMobile) const SizedBox(width: 16),
                              Text(
                                headerController.pageTitle,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  // Garante contraste maior no dark
                                  color: theme.brightness == Brightness.dark
                                      ? theme.textTheme.headlineMedium?.color ??
                                            const Color(0xFFE0E0E0)
                                      : theme.textTheme.headlineMedium?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Conteúdo da página
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
