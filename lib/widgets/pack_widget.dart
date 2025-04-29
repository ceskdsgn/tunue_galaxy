// widgets/pack_widget.dart
import 'package:flutter/material.dart';

import '../models/pack.dart';

class PackWidget extends StatelessWidget {
  final Pack pack;
  final VoidCallback? onTap;
  final bool showDetails;

  const PackWidget({
    super.key,
    required this.pack,
    this.onTap,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: maxWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Immagine del pacchetto
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: maxWidth > 200 ? 180 : maxWidth * 0.8,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Image.network(
                      pack.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.card_giftcard,
                            size: 80, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
                // Nome del pacchetto
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        pack.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
