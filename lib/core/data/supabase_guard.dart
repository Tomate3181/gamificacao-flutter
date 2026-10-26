import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/game_failure.dart';

/// Cliente do Supabase injetável (os testes trocam os repositórios inteiros).
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Executa uma chamada ao Supabase e converte erros em [GameFailure].
Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on GameFailure {
    rethrow;
  } on PostgrestException catch (error) {
    throw GameFailure.fromCode(error.message);
  } on AuthException {
    throw GameFailure.fromCode('not_authenticated');
  } catch (_) {
    throw const GameFailure.network();
  }
}

/// Lê um número vindo do Postgres (numeric chega como num ou String).
double readNum(Object? value) => switch (value) {
  num n => n.toDouble(),
  String s => double.tryParse(s) ?? 0,
  _ => 0,
};
