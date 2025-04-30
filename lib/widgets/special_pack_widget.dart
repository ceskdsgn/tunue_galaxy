import 'package:flutter/material.dart';

import '../models/special_pack.dart';

class SpecialPackWidget extends StatelessWidget {
  final SpecialPack pack;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool isFlipped;
  final bool hasGlow;

  const SpecialPackWidget({
    super.key,
    required this.pack,
    this.onTap,
    this.showDetails = true,
    this.isFlipped = false,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final packWidth = size.width * 0.7;
    final packHeight = packWidth * 1.4;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: packWidth,
        height: packHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: hasGlow
              ? [
                  BoxShadow(
                    color: pack.color.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Immagine di sfondo
              Positioned.fill(
                child: isFlipped
                    ? Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.card_giftcard,
                            size: packWidth * 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Image.network(
                        pack.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: pack.color.withOpacity(0.2),
                          child: Center(
                            child: Icon(
                              pack.icon,
                              size: packWidth * 0.5,
                              color: pack.color,
                            ),
                          ),
                        ),
                      ),
              ),

              // Overlay colorato
              if (!isFlipped)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          pack.color.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),

              // Contenuto del pacchetto
              if (!isFlipped)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icona
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            pack.icon,
                            size: 32,
                            color: pack.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Nome del pacchetto
                        Text(
                          pack.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (showDetails) ...[
                          const SizedBox(height: 8),
                          // Descrizione
                          Text(
                            pack.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Indicatore di tocco per aprire
              if (!isFlipped)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Apri',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
