import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://codfvqwqsypxqewlcrcj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvZGZ2cXdxc3lweHFld2xjcmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2ODEyNzQsImV4cCI6MjA3NjI1NzI3NH0.Q16NJxk66lwykM3T5_xPL2fB1X1-OpRCNE4mc0bVZ8c',
  );

  runApp(const AppWidget());
}
