import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '../shared/themes/app_colors.dart';
import '../shared/utils/wide_layout.dart';
import 'app_controller.dart';
import 'app_routes.dart';
import 'infra/repositories/appointment_repository.dart';
import 'infra/repositories/patient_record_repository.dart';
import 'infra/repositories/professional_repository.dart';
import 'infra/services/activity_service.dart';
import 'infra/services/notification_service.dart';
import 'modules/splash/splash_page.dart' show SplashPage;

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PabLife',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return WideScale(
          child: SafeArea(
            bottom: true,
            top: false,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.aqua,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'InstrumentSans',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'InstrumentSans'),
          displayMedium: TextStyle(fontFamily: 'InstrumentSans'),
          displaySmall: TextStyle(fontFamily: 'InstrumentSans'),
          headlineLarge: TextStyle(fontFamily: 'InstrumentSans'),
          headlineMedium: TextStyle(fontFamily: 'InstrumentSans'),
          headlineSmall: TextStyle(fontFamily: 'InstrumentSans'),
          titleLarge: TextStyle(fontFamily: 'InstrumentSans'),
          titleMedium: TextStyle(fontFamily: 'InstrumentSans'),
          titleSmall: TextStyle(fontFamily: 'InstrumentSans'),
          bodyLarge: TextStyle(fontFamily: 'InstrumentSans'),
          bodyMedium: TextStyle(fontFamily: 'InstrumentSans'),
          bodySmall: TextStyle(fontFamily: 'InstrumentSans'),
          labelLarge: TextStyle(fontFamily: 'InstrumentSans'),
          labelMedium: TextStyle(fontFamily: 'InstrumentSans'),
          labelSmall: TextStyle(fontFamily: 'InstrumentSans'),
        ),
      ),
      getPages: AppRoutes.pages,
      initialRoute: SplashPage.route,
      initialBinding: BindingsBuilder(() {
        Get.put(AppController());
        Get.put(ActivityService(), permanent: true);
        Get.put(NotificationService(), permanent: true);
        Get.lazyPut(PatientRecordRepository.new);
        Get.lazyPut(AppointmentRepository.new);
        Get.lazyPut(ProfessionalRepository.new);
      }),
    );
  }
}
