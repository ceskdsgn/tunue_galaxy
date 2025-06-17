// widgets/card_widget.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../constants/card_constants.dart';
import '../models/card.dart';

class CardWidget extends StatelessWidget {
  final CollectionCard card;
  final bool showDetails;
  final VoidCallback? onTap;
  final bool greyOut;
  final bool isHomePage;
  final bool isCompactMode;
  final bool isCollection;
  final VideoPlayerController? videoController;
  final bool shouldPlayVideo;

  const CardWidget({
    super.key,
    required this.card,
    this.showDetails = false,
    this.onTap,
    this.greyOut = false,
    this.isHomePage = false,
    this.isCompactMode = false,
    this.isCollection = false,
    this.videoController,
    this.shouldPlayVideo = false,
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
          ),
          child: Stack(
            children: [
              // Immagine della carta o video che riempie tutto lo spazio
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
                                _buildMediaContent(),
                                const Icon(
                                  Icons.lock,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildMediaContent(),
                ),
              ),
              // Overlay con quantità (solo se maggiore di 1 e solo in collection)
              if (!greyOut &&
                  card.quantity > 1 &&
                  !isCompactMode &&
                  isCollection)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                      child: Container(
                        width: 32,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: ShapeDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(-0.00, 0.00),
                            end: const Alignment(1.00, 1.01),
                            colors: [
                              Colors.white.withOpacity(0.7),
                              Colors.white.withOpacity(0.4),
                              Colors.white.withOpacity(0)
                            ],
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x28000000),
                              blurRadius: 8,
                              offset: Offset(0, 0),
                              spreadRadius: 0,
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${card.quantity}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: 'NeueHaasDisplay',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildMediaContent() {
    // Se c'è un video controller e dovrebbe riprodurre il video, mostra il video
    if (videoController != null &&
        shouldPlayVideo &&
        videoController!.value.isInitialized) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoController!.value.size.width,
              height: videoController!.value.size.height,
              child: VideoPlayer(videoController!),
            ),
          ),
        ),
      );
    }

    // Altrimenti mostra l'immagine normale
    return Image.network(
      card.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
      ),
    );
  }
}
