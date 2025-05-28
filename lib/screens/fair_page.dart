// screens/fair_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fair_news.dart';
import '../services/fair_service.dart';

class FairPage extends StatefulWidget {
  const FairPage({super.key});

  @override
  _FairPageState createState() => _FairPageState();
}

class _FairPageState extends State<FairPage>
    with AutomaticKeepAliveClientMixin {
  final FairService fairService = FairService();
  List<FairNews>? news;
  bool isLoading = true;
  bool showOnlyEvents = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (showOnlyEvents) {
        news = await fairService.getUpcomingEvents();
      } else {
        news = await fairService.getNews();
      }
    } catch (e) {
      // Gestisci errori
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nel caricamento delle notizie')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tunuè in Fiera'),
        actions: [
          IconButton(
            icon: Icon(showOnlyEvents ? Icons.event : Icons.article),
            onPressed: () {
              setState(() {
                showOnlyEvents = !showOnlyEvents;
                _loadNews();
              });
            },
            tooltip: showOnlyEvents
                ? 'Mostra tutte le notizie'
                : 'Mostra solo eventi',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : news!.isEmpty
                ? Center(
                    child: Text(
                      showOnlyEvents
                          ? 'Nessun evento in programma'
                          : 'Nessuna notizia disponibile',
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: news!.length,
                    itemBuilder: (context, index) {
                      final item = news![index];
                      return _buildNewsCard(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildNewsCard(FairNews newsItem) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isEvent = newsItem.eventDate != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isEvent
            ? const BorderSide(color: Colors.amber, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(news: newsItem),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  newsItem.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: Center(
                      child:
                          Icon(Icons.image, size: 50, color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etichetta evento se applicabile
                  if (isEvent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'EVENTO',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Titolo
                  Text(
                    newsItem.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Data pubblicazione
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Pubblicato il ${dateFormat.format(newsItem.publishDate)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Data evento se applicabile
                  if (isEvent) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.event, size: 16, color: Colors.amber[800]),
                        const SizedBox(width: 4),
                        Text(
                          'Data evento: ${dateFormat.format(newsItem.eventDate!)}',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Location se applicabile
                  if (newsItem.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          newsItem.location!,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Anteprima contenuto
                  Text(
                    _truncateText(newsItem.content, 100),
                    style: const TextStyle(fontSize: 14),
                  ),

                  // Pulsante "Leggi di più"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: const Text('Leggi di più'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NewsDetailScreen(news: newsItem),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}

class NewsDetailScreen extends StatelessWidget {
  final FairNews news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isEvent = news.eventDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio Notizia'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                news.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etichetta evento se applicabile
                  if (isEvent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'EVENTO',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Titolo
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Data pubblicazione
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Pubblicato il ${dateFormat.format(news.publishDate)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Data evento se applicabile
                  if (isEvent) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event, size: 18, color: Colors.amber[800]),
                        const SizedBox(width: 4),
                        Text(
                          'Data evento: ${dateFormat.format(news.eventDate!)}',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Location se applicabile
                  if (news.location != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          news.location!,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Contenuto completo
                  Text(
                    news.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  // Pulsante per aggiungere al calendario se è un evento
                  if (isEvent) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Aggiungi al calendario'),
                      onPressed: () {
                        // TODO: Implementare l'aggiunta al calendario
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Evento aggiunto al calendario'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
