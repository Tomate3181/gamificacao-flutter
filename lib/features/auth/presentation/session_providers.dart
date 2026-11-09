import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_auth_repository.dart';

/// Id do usuário logado. Os dados do jogo observam este provider, então
/// são recarregados do zero quando outra pessoa entra na conta.
final currentUserIdProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).userIdChanges(),
);

/// Espera o usuário logado. Lança erro se não houver sessão.
///
/// Use no `build` dos controladores (observa a troca de usuário).
Future<String> requireUserId(Ref ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) throw StateError('Sem usuário logado');
  return userId;
}

/// Mesmo que [requireUserId], para usar fora do `build`.
Future<String> readUserId(Ref ref) async {
  final userId = await ref.read(currentUserIdProvider.future);
  if (userId == null) throw StateError('Sem usuário logado');
  return userId;
}
