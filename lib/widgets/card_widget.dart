// widgets/card_widget.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/card_constants.dart';
import '../models/card.dart';

class CardWidget extends StatelessWidget {
  final CollectionCard card;
  final bool showDetails;
  final VoidCallback? onTap;
  final bool greyOut;
  final bool isHomePage;

  const CardWidget({
    super.key,
    required this.card,
    this.showDetails = false,
    this.onTap,
    this.greyOut = false,
    this.isHomePage = false,
  });

  @override
  Widget build(BuildContext context) {
    final width =
        isHomePage ? CardConstants.homeCardWidth : CardConstants.cardWidth;
    final height =
        isHomePage ? CardConstants.homeCardHeight : CardConstants.cardHeight;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CardConstants.cardBorderRadius),
            side: BorderSide(
              color: greyOut
                  ? Colors.grey
                  : CollectionCard.getRarityColor(card.rarity),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Immagine della carta che riempie tutto lo spazio
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(CardConstants.cardBorderRadius),
                child: Container(
                  color: Colors.grey[200],
                  child: greyOut
                      ? ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.network(
                                  card.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.lock,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Image.network(
                          card.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.broken_image,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Errore nel caricamento dell\'immagine',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              // Overlay con nome e rarità
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft:
                          Radius.circular(CardConstants.cardBorderRadius),
                      bottomRight:
                          Radius.circular(CardConstants.cardBorderRadius),
                    ),
                  ),
                  padding: const EdgeInsets.all(CardConstants.cardPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nome della carta
                      Text(
                        card.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: CardConstants.cardNameFontSize,
                          color: greyOut ? Colors.grey : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Etichetta rarità
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 1, horizontal: 4),
                        decoration: BoxDecoration(
                          color: greyOut
                              ? Colors.grey
                              : CollectionCard.getRarityColor(card.rarity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CollectionCard.getRarityString(card.rarity),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: CardConstants.cardRarityFontSize),
                              textAlign: TextAlign.center,
                            ),
                            if (!greyOut && card.quantity > 1) ...[
                              const SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  'x${card.quantity}',
                                  style: TextStyle(
                                    color: CollectionCard.getRarityColor(
                                        card.rarity),
                                    fontSize:
                                        CardConstants.cardQuantityFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Overlay grigio se la carta non è posseduta
              if (greyOut)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(CardConstants.cardBorderRadius),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
