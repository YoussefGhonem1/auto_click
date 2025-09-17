import '../../domain/models/tiktok_link.dart';
import '../data_sources/tiktok_links_firestore_datasource.dart';

abstract class TikTokLinksRepository {
  Future<void> addTikTokLink(TikTokLink link);
  Future<List<TikTokLink>> getTikTokLinks();
  Future<TikTokLink?> getTikTokLink(String linkId);
  Future<void> updateTikTokLink(TikTokLink link);
  Future<void> deleteTikTokLink(String linkId);
  Future<void> addMultipleTikTokLinks(List<TikTokLink> links);
  Stream<List<TikTokLink>> getTikTokLinksStream();
  Future<List<TikTokLink>> searchTikTokLinks(String query);
  Future<int> getTikTokLinksCount();
}

class TikTokLinksRepositoryImpl implements TikTokLinksRepository {
  final TikTokLinksFirestoreDataSource _firestoreDataSource;

  TikTokLinksRepositoryImpl(this._firestoreDataSource);

  @override
  Future<void> addTikTokLink(TikTokLink link) async {
    await _firestoreDataSource.addTikTokLink(link);
  }

  @override
  Future<List<TikTokLink>> getTikTokLinks() async {
    return await _firestoreDataSource.getTikTokLinks();
  }

  @override
  Future<TikTokLink?> getTikTokLink(String linkId) async {
    return await _firestoreDataSource.getTikTokLink(linkId);
  }

  @override
  Future<void> updateTikTokLink(TikTokLink link) async {
    await _firestoreDataSource.updateTikTokLink(link);
  }

  @override
  Future<void> deleteTikTokLink(String linkId) async {
    await _firestoreDataSource.deleteTikTokLink(linkId);
  }

  @override
  Future<void> addMultipleTikTokLinks(List<TikTokLink> links) async {
    await _firestoreDataSource.addMultipleTikTokLinks(links);
  }

  @override
  Stream<List<TikTokLink>> getTikTokLinksStream() {
    return _firestoreDataSource.getTikTokLinksStream();
  }

  @override
  Future<List<TikTokLink>> searchTikTokLinks(String query) async {
    return await _firestoreDataSource.searchTikTokLinks(query);
  }

  @override
  Future<int> getTikTokLinksCount() async {
    return await _firestoreDataSource.getTikTokLinksCount();
  }
}
