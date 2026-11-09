/// Caminhos dos sprites gerados por `tool/sprites/generate_sprites.py`.
class Sprites {
  const Sprites._();

  static const _root = 'assets/sprites';

  /// Quadros da Lumi por estado (wandering, following, happy, collecting).
  static String lumi(String state, int frame) =>
      '$_root/lumi/lumi_${state}_$frame.png';

  static const lumiFrames = 4;

  static String tree(int speciesId) => '$_root/trees/tree_$speciesId.png';
  static const sprout = '$_root/trees/sprout.png';

  /// Chão de uma região. São 4 variações, escolhidas pela posição para o
  /// chão não parecer repetido.
  static String tile(
    String theme, {
    required bool restored,
    required int slot,
  }) {
    const variants = ['a', 'b', 'c', 'd'];
    final variant = variants[(slot * 7 + slot ~/ 10 * 3) % variants.length];
    final kind = restored ? 'restored' : 'polluted';
    return '$_root/tiles/${_theme(theme)}_${kind}_$variant.png';
  }

  static String planet(String theme) =>
      '$_root/planets/planet_${_theme(theme)}.png';

  /// Planeta usado como logo do app.
  static const logo = '$_root/planets/planet_forest.png';

  static const energy = '$_root/icons/energy.png';
  static const oxygen = '$_root/icons/oxygen.png';
  static const points = '$_root/icons/points.png';

  static const _themes = {'desert', 'forest', 'island', 'tundra', 'mountain'};

  static String _theme(String theme) =>
      _themes.contains(theme) ? theme : 'forest';
}
