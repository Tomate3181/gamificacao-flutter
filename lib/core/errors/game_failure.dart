/// Erro de uma ação do jogo, com mensagem pronta para a UI.
///
/// Os códigos vêm das RPCs do Supabase (veja a migration core_economy).
class GameFailure implements Exception {
  const GameFailure(this.code, this.message);

  factory GameFailure.fromCode(String raw) {
    for (final entry in _messages.entries) {
      if (raw.contains(entry.key)) return GameFailure(entry.key, entry.value);
    }
    return const GameFailure.unknown();
  }

  const GameFailure.network()
    : code = 'network',
      message = 'Sem conexão com o servidor. Verifique sua internet.';

  const GameFailure.unknown()
    : code = 'unknown',
      message = 'Algo deu errado. Tente de novo.';

  final String code;
  final String message;

  static const _messages = {
    'not_authenticated': 'Sua sessão expirou. Entre de novo.',
    'not_enough_energy': 'Energia insuficiente. Caminhe mais um pouco!',
    'not_enough_oxygen': 'Oxigênio insuficiente para este upgrade.',
    'slot_taken': 'Essa região já tem uma árvore.',
    'invalid_slot': 'Região inválida. Atualize a tela e tente de novo.',
    'invalid_species': 'Espécie inválida. Atualize a tela e tente de novo.',
    'no_active_planet': 'Planeta concluído! O próximo chega em breve.',
    'invalid_upgrade': 'Upgrade inválido. Atualize a tela e tente de novo.',
    'upgrade_unavailable': 'Este upgrade ainda não está disponível.',
    'max_level': 'Este upgrade já está no nível máximo.',
    'invalid_steps': 'Contagem de passos inválida.',
  };

  @override
  String toString() => 'GameFailure($code)';
}
