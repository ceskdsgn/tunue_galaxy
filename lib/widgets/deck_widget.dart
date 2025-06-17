import 'package:flutter/material.dart';

import '../models/card_game.dart';
import 'card_back_widget.dart';

class DeckWidget extends StatelessWidget {
  final List<GameCard> deck;
  final bool isOpponent;
  final double cardWidth;
  final double cardHeight;
  final VoidCallback? onTap;

  const DeckWidget({
    super.key,
    required this.deck,
    this.isOpponent = false,
    this.cardWidth = 48,
    this.cardHeight = 64,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (deck.isEmpty) {
      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.withOpacity(0.2),
        ),
        child: Center(
          child: Icon(
            Icons.remove_circle_outline,
            color: Colors.grey.withOpacity(0.7),
            size: cardWidth * 0.4,
          ),
        ),
      );
    }

    return Container(
      width: cardWidth + 16,
      height: cardHeight + 16,
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < deck.length; i++)
              Positioned(
                left: (i * -0.3),
                top: (i * -0.4),
                child: Transform.rotate(
                  angle: (i % 2 == 0 ? 0.01 : -0.01),
                  child: CardBackWidget(
                    width: cardWidth,
                    height: cardHeight,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GraveyardWidget extends StatelessWidget {
  final List<GameCard> graveyard;
  final bool isOpponent;
  final double cardWidth;
  final double cardHeight;
  final VoidCallback? onTap;

  const GraveyardWidget({
    super.key,
    required this.graveyard,
    this.isOpponent = false,
    this.cardWidth = 48,
    this.cardHeight = 64,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (graveyard.isEmpty) {
      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.5),
            width: 2,
          ),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Center(
          child: Icon(
            Icons.delete_outline,
            color: Colors.grey.withOpacity(0.7),
            size: cardWidth * 0.4,
          ),
        ),
      );
    }

    // Mostra l'ultima carta del cimitero (quella in cima)
    final topCard = graveyard.last;

    return Container(
      width: cardWidth + 16, // Spazio extra per le ombre
      height: cardHeight + 16, // Spazio extra per le ombre
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none, // Permette alle carte di uscire dallo Stack
          children: [
            // Mostra alcune carte del cimitero sovrapposte (max 5 per performance)
            for (int i = 0;
                i < (graveyard.length > 5 ? 5 : graveyard.length);
                i++)
              Positioned(
                left: (i * 0.3), // Piccolo offset orizzontale
                top: (i * 0.3), // Piccolo offset verticale
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    topCard.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.purple.shade300,
                        child: Center(
                          child: Text(
                            topCard.name,
                            style: const TextStyle(
                              fontSize: 6,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
