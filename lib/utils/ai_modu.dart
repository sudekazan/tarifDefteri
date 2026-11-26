/// Yapay zekâ isteğinin türü; sunucudaki `mode` değeriyle aynı. Ücretsiz
/// kullanıcının haftalık hakkı her tür için ayrı sayılır.
abstract final class AiModu {
  /// Yemek adıyla ya da linkten tarif (AI Şef).
  static const yemekAdi = 'dish_name';

  /// Elindeki malzemelerden tarif (Ne pişirsem).
  static const malzeme = 'ingredients';
}
