// screens/collection_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/user.dart';
import '../services/card_service.dart';
import '../widgets/card_widget.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage>
    with AutomaticKeepAliveClientMixin {
  final CardService cardService = CardService();
  List<CollectionCard> allCards = []; // Inizializziamo con una lista vuota
  List<CollectionCard> filteredCards = []; // Inizializziamo con una lista vuota
  bool isLoading = true;

  CardRarity? rarityFilter;
  bool showOnlyOwned = false;
  String searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      isLoading = true;
    });

    await cardService.loadCards();

    setState(() {
      allCards = cardService.getAllCards();
      filteredCards = List.from(allCards);
      isLoading = false;
    });
  }

  void _applyFilters(User user) {
    if (allCards.isEmpty) return; // Non applicare filtri se non ci sono carte

    setState(() {
      filteredCards = allCards.where((card) {
        // Filtro per rarità
        if (rarityFilter != null && card.rarity != rarityFilter) {
          return false;
        }

        // Filtro per possesso
        if (showOnlyOwned && !user.ownedCards.any((c) => c.id == card.id)) {
          return false;
        }

        // Filtro per ricerca
        if (searchQuery.isNotEmpty &&
            !card.name.toLowerCase().contains(searchQuery.toLowerCase())) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = Provider.of<User>(context);
    final collectionProgress =
        user.ownedCards.length / (allCards.isEmpty ? 1 : allCards.length);

    // Applica i filtri quando l'utente cambia
    if (!isLoading &&
        filteredCards.length == allCards.length &&
        user.ownedCards.isNotEmpty) {
      _applyFilters(user);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('La mia Collezione'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cerca carte...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                searchQuery = value;
                _applyFilters(user);
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Filtri e progresso
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Progresso collezione
                      Row(
                        children: [
                          Text(
                            'Progresso Collezione: ${(collectionProgress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: collectionProgress,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.amber),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${user.ownedCards.length}/${allCards.length}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Filtri
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Possedute'),
                            selected: showOnlyOwned,
                            onSelected: (selected) {
                              setState(() {
                                showOnlyOwned = selected;
                                _applyFilters(user);
                              });
                            },
                          ),
                          ...CardRarity.values.map((rarity) {
                            return FilterChip(
                              label:
                                  Text(CollectionCard.getRarityString(rarity)),
                              selected: rarityFilter == rarity,
                              selectedColor:
                                  CollectionCard.getRarityColor(rarity)
                                      .withOpacity(0.7),
                              onSelected: (selected) {
                                setState(() {
                                  rarityFilter = selected ? rarity : null;
                                  _applyFilters(user);
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // Griglia delle carte
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.67,
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                      ),
                      itemCount: filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = filteredCards[index];
                        final ownedCard = user.ownedCards.firstWhere(
                          (c) => c.id == card.id,
                          orElse: () => card,
                        );
                        final isOwned =
                            user.ownedCards.any((c) => c.id == card.id);

                        return CardWidget(
                          card: ownedCard,
                          greyOut: !isOwned,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  _buildCardDetailDialog(ownedCard, isOwned),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCardDetailDialog(CollectionCard card, bool isOwned) {
    // Debug per vedere il formato dell'URL
    print('DEBUG Collection: Card ${card.name}, imageUrl: ${card.imageUrl}');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isOwned ? Colors.black : Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    if (isOwned && card.quantity > 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CollectionCard.getRarityColor(card.rarity),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'x${card.quantity}',
                          style: TextStyle(
                            color: CollectionCard.getRarityColor(card.rarity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOwned
                            ? CollectionCard.getRarityColor(card.rarity)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        CollectionCard.getRarityString(card.rarity),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isOwned
                    ? _buildCardImage(card)
                    : const ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.image, size: 80, color: Colors.grey),
                            Icon(Icons.lock, size: 48),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Descrizione:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOwned ? card.description : 'Devi ancora scoprire questa carta!',
              style: TextStyle(
                color: isOwned ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Chiudi'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(CollectionCard card) {
    // Se l'URL inizia con http, usa Image.network
    if (card.imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          card.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Errore caricamento immagine network: $error');
            return _buildFallbackImage(card);
          },
        ),
      );
    } else {
      // Prova prima con il percorso diretto
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          card.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Errore caricamento immagine asset: $error');
            // Se fallisce, prova con il formato del gioco delle carte
            return Image.asset(
              'assets/images/cards/${card.name.toLowerCase().replaceAll(' ', '_')}.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error2, stackTrace2) {
                print('Errore caricamento immagine formato gioco: $error2');
                return _buildFallbackImage(card);
              },
            );
          },
        ),
      );
    }
  }

  Widget _buildFallbackImage(CollectionCard card) {
    return Container(
      decoration: BoxDecoration(
        color: CollectionCard.getRarityColor(card.rarity).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 60,
              color: CollectionCard.getRarityColor(card.rarity),
            ),
            const SizedBox(height: 8),
            Text(
              card.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: CollectionCard.getRarityColor(card.rarity),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
