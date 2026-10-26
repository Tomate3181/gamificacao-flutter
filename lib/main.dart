import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/config/missing_config_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    // Aceita a chave "anon" (legada) ou a "publishable" do painel.
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: EcoPlanetApp()));
}
