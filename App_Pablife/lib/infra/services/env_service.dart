import 'dart:developer';

enum Environment {
  dev,
  prod;

  String get alias {
    switch (this) {
      case Environment.dev:
        return 'desenvolvimento';
      case Environment.prod:
        return 'produção';
    }
  }
}

class EnvService {
  static final EnvService _instance = EnvService._internal();
  factory EnvService() => _instance;
  EnvService._internal();

  bool debugMode = false;
  static void setDebugMode(bool activate) {
    final envService = EnvService();
    envService.debugMode = activate;
    log(
      '[ENV SERVICE] - Aplicação rodando no ambiente de ${EnvService.enviroment.alias.toUpperCase()}',
    );
  }

  static Environment get enviroment {
    final envService = EnvService();
    if (envService.debugMode) {
      return Environment.dev;
    }
    return Environment.prod;
  }
}

class EnvVariables {
  EnvVariables._();

  static String get url {
    if (EnvService.enviroment == Environment.dev) {
      return 'https://ba9d6f12f27c.ngrok-free.app';
    }
    return 'https://codfvqwqsypxqewlcrcj.supabase.co';
  }

  static String get anonKey {
    if (EnvService.enviroment == Environment.dev) {
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
    }
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvZGZ2cXdxc3lweHFld2xjcmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2ODEyNzQsImV4cCI6MjA3NjI1NzI3NH0.Q16NJxk66lwykM3T5_xPL2fB1X1-OpRCNE4mc0bVZ8c';
  }

  static String get dashboardUrl {
    if (EnvService.enviroment == Environment.dev) {
      return '';
    }
    return '';
  }

  static String get oneSignalAppId {
    if (EnvService.enviroment == Environment.dev) {
      return '';
    }
    return '';
  }

  static String get terms => '';
  static String get policyAndPrivacy => '';
}
