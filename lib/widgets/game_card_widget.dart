import 'package:flutter/material.dart';

import '../models/card_game.dart';

class GameCardWidget extends StatelessWidget {
  final GameCard card;
  final bool isSmall;
  final bool isSelected;
  final bool canPlay;
  final VoidCallback? onTap;

  const GameCardWidget({
    super.key,
    required this.card,
    this.isSmall = false,
    this.isSelected = false,
    this.canPlay = true,
    this.onTap,
  });

  void _showCardDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo: ${_getTypeString()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getTypeColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Costo: ${card.cost} energia'),
            if (card is PersonaggioCard) ...[
              const SizedBox(height: 4),
              Text('Forza: ${(card as PersonaggioCard).forza}'),
            ],
            const SizedBox(height: 12),
            const Text(
              'Effetto:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(card.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Dimensioni molto conservative per evitare overflow
    final baseWidth = isSmall ? 60.0 : 75.0; // Molto più piccole
    final baseHeight = isSmall ? 80.0 : 100.0; // Ridotte ulteriormente

    // Scala ancora più conservativa
    final scaleFactor = screenWidth < 600 ? 0.7 : 0.85;
    final width =
        (baseWidth * scaleFactor).clamp(45.0, 85.0); // Limiti molto ristretti
    final height =
        (baseHeight * scaleFactor).clamp(60.0, 110.0); // Altezza molto limitata

    // Font molto piccoli per evitare overflow
    final titleFontSize = isSmall
        ? (screenWidth < 600 ? 6.0 : 7.0)
        : (screenWidth < 600 ? 8.0 : 9.0);
    final costFontSize = (screenWidth < 600 ? 9.0 : 11.0).clamp(8.0, 12.0);
    final forzaFontSize = (screenWidth < 600 ? 7.0 : 8.0).clamp(6.0, 9.0);
    final iconSize = isSmall
        ? (screenWidth < 600 ? 8.0 : 10.0)
        : (screenWidth < 600 ? 12.0 : 14.0);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showCardDetails(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : _getTypeColor(),
            width: isSelected ? 1.5 : 1, // Bordi molto sottili
          ),
          color: canPlay ? Colors.white : Colors.grey.shade300,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.shade300,
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con costo molto compatto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                color: _getTypeColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
              child: Text(
                '${card.cost}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: costFontSize,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Corpo della carta molto compatto
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(screenWidth < 600 ? 2 : 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nome molto compatto
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          card.name,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2, // Massimo 2 righe sempre
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Icona tipo molto piccola
                    Flexible(
                      flex: 1,
                      child: Icon(
                        _getTypeIcon(),
                        size: iconSize,
                        color: _getTypeColor(),
                      ),
                    ),

                    // Forza molto compatta (solo per personaggi)
                    if (card is PersonaggioCard)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 600 ? 2 : 3,
                            vertical: 0.5),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${(card as PersonaggioCard).forza}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: forzaFontSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Indicatore effetto minimo
            if (card.description.isNotEmpty)
              Container(
                width: double.infinity,
                height: 8, // Altezza fissa minima
                decoration: BoxDecoration(
                  color: Colors.amber.shade200,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 6,
                  color: Colors.amber.shade800,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTypeString() {
    switch (card.type) {
      case CardType.personaggio:
        return 'Personaggio';
      case CardType.ambientazione:
        return 'Ambientazione';
      case CardType.interazione:
        return 'Interazione';
    }
  }

  Color _getTypeColor() {
    switch (card.type) {
      case CardType.personaggio:
        return Colors.purple.shade600;
      case CardType.ambientazione:
        return Colors.green.shade600;
      case CardType.interazione:
        return Colors.blue.shade600;
    }
  }

  IconData _getTypeIcon() {
    switch (card.type) {
      case CardType.personaggio:
        return Icons.person;
      case CardType.ambientazione:
        return Icons.landscape;
      case CardType.interazione:
        return Icons.auto_awesome;
    }
  }
}
