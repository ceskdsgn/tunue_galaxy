// services/fair_service.dart
import '../models/fair_news.dart';

class FairService {
  // Singleton pattern
  static final FairService _instance = FairService._internal();

  factory FairService() {
    return _instance;
  }

  FairService._internal();

  // Ottieni tutte le notizie della fiera
  Future<List<FairNews>> getNews() async {
    // Simula una richiesta API con un ritardo
    await Future.delayed(const Duration(milliseconds: 800));

    // Per ora, restituisci dati di esempio
    return [
      FairNews(
        id: '1',
        title: 'Tunuè al Lucca Comics & Games 2025',
        content:
            'Siamo lieti di annunciare che saremo presenti al Lucca Comics & Games 2025 con uno stand dedicato. Vieni a trovarci per scoprire le ultime novità e partecipare a eventi esclusivi!',
        imageUrl: 'assets/images/news/lucca_comics.jpg',
        publishDate: DateTime.now().subtract(const Duration(days: 5)),
        eventDate: DateTime(2025, 10, 30),
        location: 'Lucca, Italia',
      ),
      FairNews(
        id: '2',
        title: 'Nuova collezione di carte in arrivo!',
        content:
            'A partire dal prossimo mese, sarà disponibile una nuova collezione di carte a tema fantasy. Preparati a scoprire creature mitologiche, eroi leggendari e artefatti magici!',
        imageUrl: 'assets/images/news/new_collection.jpg',
        publishDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      FairNews(
        id: '3',
        title: 'Evento di scambio carte a Milano',
        content:
            'Partecipa al nostro evento di scambio carte a Milano. Porta le tue doppie e scambiale con altri collezionisti. Saranno presenti anche alcuni membri del team Tunuè per rispondere alle tue domande.',
        imageUrl: 'assets/images/news/trading_event.jpg',
        publishDate: DateTime.now().subtract(const Duration(days: 15)),
        eventDate: DateTime.now().add(const Duration(days: 20)),
        location: 'Milano, Italia',
      ),
      FairNews(
        id: '4',
        title: 'Intervista con l\'artista delle carte',
        content:
            'Abbiamo intervistato l\'artista principale delle nostre carte. Scopri il processo creativo dietro le illustrazioni e alcuni segreti sulla prossima serie!',
        imageUrl: 'assets/images/news/artist_interview.jpg',
        publishDate: DateTime.now().subtract(const Duration(days: 20)),
      ),
      FairNews(
        id: '5',
        title: 'Torneo nazionale Tunuè Collection',
        content:
            'Il primo torneo nazionale Tunuè Collection si terrà a Roma il prossimo mese. Iscriviti ora per partecipare e avere la possibilità di vincere premi esclusivi!',
        imageUrl: 'assets/images/news/tournament.jpg',
        publishDate: DateTime.now().subtract(const Duration(days: 25)),
        eventDate: DateTime.now().add(const Duration(days: 45)),
        location: 'Roma, Italia',
      ),
    ];
  }

  // Ottieni una notizia specifica per ID
  Future<FairNews?> getNewsById(String id) async {
    final allNews = await getNews();
    try {
      return allNews.firstWhere((news) => news.id == id);
    } catch (e) {
      return null;
    }
  }

  // Ottieni solo gli eventi futuri
  Future<List<FairNews>> getUpcomingEvents() async {
    final allNews = await getNews();
    final now = DateTime.now();

    return allNews
        .where((news) => news.eventDate != null && news.eventDate!.isAfter(now))
        .toList();
  }
}
