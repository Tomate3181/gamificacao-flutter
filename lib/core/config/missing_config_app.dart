import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tela mostrada quando o app roda sem as chaves do Supabase.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoPlanet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Configuração do Supabase ausente.\n\n'
              'Rode o app com:\n'
              'flutter run --dart-define-from-file=config/supabase.json\n\n'
              'Veja o README para criar esse arquivo.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
