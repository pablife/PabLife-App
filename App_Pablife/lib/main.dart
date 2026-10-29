import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pablife/firebase_options.dart';
import 'package:pablife/infra/services/env_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

  EnvService.setDebugMode(false);

  // Firebase (Crashlytics) e OneSignal não têm suporte na web.
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    OneSignal.initialize('ccef00af-323d-4e75-8957-0fca60659b73');
    OneSignal.Notifications.requestPermission(true);
  }

  await Supabase.initialize(
    url: EnvVariables.url,
    anonKey: EnvVariables.anonKey,
  );

  if (!kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const AppWidget());
}
