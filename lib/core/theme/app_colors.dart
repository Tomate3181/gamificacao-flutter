import 'package:flutter/painting.dart';

/// Paleta do GDD (seção 11): céu noturno azul-marinho, aurora em teal e
/// lilás, rosa-quente como acento e dourado para ações e recompensas.
class AppColors {
  const AppColors._();

  // Céu
  static const skyDeep = Color(0xFF0B1630);
  static const skyMid = Color(0xFF142449);
  static const surface = Color(0xFF1B2D57);
  static const outline = Color(0xFF2E4377);

  // Aurora e acentos
  static const auroraTeal = Color(0xFF2EC4B6);
  static const auroraLilac = Color(0xFFB69CFF);
  static const hotPink = Color(0xFFFF5D8F);

  // Ações e recompensas
  static const gold = Color(0xFFFFC94A);

  // Planeta
  static const leafGreen = Color(0xFF5BD16F);

  // Texto e estados
  static const textPrimary = Color(0xFFEAF0FF);
  static const textMuted = Color(0xFF9AA8C7);
  static const error = Color(0xFFFF6B6B);
}
