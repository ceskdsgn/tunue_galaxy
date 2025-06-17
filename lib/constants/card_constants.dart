class CardConstants {
  // Dimensioni standard della carta
  static const double cardWidth = 63.0;
  static const double cardHeight = 88.0;
  static const double cardAspectRatio = cardWidth / cardHeight;

  // Dimensioni della carta nella homepage (più grande)
  static const double homeCardWidth = 302.0; // 252 * 1.2
  static const double homeCardHeight = 422.0; // 352 * 1.2
  static const double homeCardAspectRatio = homeCardWidth / homeCardHeight;

  // Dimensioni della carta nel dialogo dei dettagli
  static const double detailCardWidth = 200.0;
  static const double detailCardHeight = 280.0;
  static const double detailCardAspectRatio =
      detailCardWidth / detailCardHeight;

  // Dimensioni del testo
  static const double cardNameFontSize = 10.0;
  static const double cardRarityFontSize = 8.0;
  static const double cardQuantityFontSize = 8.0;

  // Padding e margini
  static const double cardPadding = 4.0;
  static const double cardBorderRadius = 8.0;
}
