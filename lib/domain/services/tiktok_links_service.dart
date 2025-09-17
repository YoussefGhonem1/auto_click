import 'dart:math';
import '../models/tiktok_link.dart';
import '../../data/repositories/tiktok_links_repository.dart';
import '../../data/data_sources/tiktok_links_firestore_datasource.dart';

class TikTokLinksService {
  static TikTokLinksService? _instance;
  static TikTokLinksService get instance =>
      _instance ??= TikTokLinksService._internal();

  TikTokLinksService._internal();

  final TikTokLinksRepository _repository = TikTokLinksRepositoryImpl(
    TikTokLinksFirestoreDataSource(),
  );

  List<TikTokLink> _cachedLinks = [];
  bool _isLoaded = false;

  /// Initialize the service and fetch TikTok links (global)
  Future<void> initialize() async {
    try {
      await _fetchTikTokLinks();
      print(
        'Initialized TikTok links service with ${_cachedLinks.length} global links',
      );
    } catch (e) {
      print('Error initializing TikTok links service: $e');
    }
  }

  /// Fetch all TikTok links from Firestore (global)
  Future<void> _fetchTikTokLinks() async {
    try {
      final links = await _repository.getTikTokLinks();
      _cachedLinks = links;
      _isLoaded = true;
      print('Fetched ${links.length} global TikTok links');
    } catch (e) {
      print('Error fetching TikTok links: $e');
      _cachedLinks = [];
      _isLoaded = false;
    }
  }

  /// Fetch TikTok links from Firestore (legacy method for backward compatibility)
  Future<void> fetchTikTokLinks() async {
    await _fetchTikTokLinks();
  }

  /// Get a random TikTok URL from the cached links
  String? getRandomTikTokUrl() {
    if (_cachedLinks.isEmpty) {
      return null;
    }

    final random = Random();
    final randomIndex = random.nextInt(_cachedLinks.length);
    return _cachedLinks[randomIndex].url;
  }

  /// Get all cached TikTok links
  List<TikTokLink> getAllLinks() {
    return _cachedLinks;
  }

  /// Get links created by a specific user
  List<TikTokLink> getLinksForUser(String userId) {
    return _cachedLinks.where((link) => link.userId == userId).toList();
  }

  /// Get links created by a specific user (count)
  int getLinksCountForUser(String userId) {
    return _cachedLinks.where((link) => link.userId == userId).length;
  }

  /// Check if links are loaded
  bool get isLoaded => _isLoaded;

  /// Get the count of cached links
  int get linksCount => _cachedLinks.length;

  /// Add a new TikTok link
  Future<void> addTikTokLink(TikTokLink link) async {
    try {
      await _repository.addTikTokLink(link);
      _cachedLinks.add(link);
      print('Added TikTok link: ${link.title}');
    } catch (e) {
      print('Error adding TikTok link: $e');
      rethrow;
    }
  }

  /// Update a TikTok link
  Future<void> updateTikTokLink(TikTokLink link) async {
    try {
      await _repository.updateTikTokLink(link);
      final index = _cachedLinks.indexWhere((l) => l.id == link.id);
      if (index != -1) {
        _cachedLinks[index] = link;
      }
      print('Updated TikTok link: ${link.title}');
    } catch (e) {
      print('Error updating TikTok link: $e');
      rethrow;
    }
  }

  /// Delete a TikTok link
  Future<void> deleteTikTokLink(String linkId) async {
    try {
      await _repository.deleteTikTokLink(linkId);
      _cachedLinks.removeWhere((link) => link.id == linkId);
      print('Deleted TikTok link: $linkId');
    } catch (e) {
      print('Error deleting TikTok link: $e');
      rethrow;
    }
  }

  /// Add multiple TikTok links at once
  Future<void> addMultipleTikTokLinks(List<TikTokLink> links) async {
    try {
      await _repository.addMultipleTikTokLinks(links);
      _cachedLinks.addAll(links);
      print('Added ${links.length} TikTok links');
    } catch (e) {
      print('Error adding multiple TikTok links: $e');
      rethrow;
    }
  }

  /// Refresh cached links
  Future<void> refreshLinks() async {
    await _fetchTikTokLinks();
  }

  /// Get TikTok links stream for real-time updates
  Stream<List<TikTokLink>> getTikTokLinksStream() {
    return _repository.getTikTokLinksStream();
  }

  /// Search TikTok links
  Future<List<TikTokLink>> searchTikTokLinks(String query) async {
    try {
      if (query.isEmpty) {
        return _cachedLinks;
      }

      // Search in cached links first for better performance
      final cachedResults = _cachedLinks
          .where(
            (link) =>
                link.title.toLowerCase().contains(query.toLowerCase()) ||
                link.url.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      // If we have cached results, return them
      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }

      // Otherwise, search in Firestore
      return await _repository.searchTikTokLinks(query);
    } catch (e) {
      print('Error searching TikTok links: $e');
      return [];
    }
  }

  /// Get statistics about TikTok links
  Map<String, dynamic> getStatistics() {
    final linksByUser = <String, int>{};
    for (final link in _cachedLinks) {
      linksByUser[link.userId] = (linksByUser[link.userId] ?? 0) + 1;
    }

    return {
      'total_links': _cachedLinks.length,
      'active_links': _cachedLinks.where((link) => link.isActive).length,
      'inactive_links': _cachedLinks.where((link) => !link.isActive).length,
      'is_loaded': _isLoaded,
      'links_by_user': linksByUser,
      'unique_users': linksByUser.keys.length,
      'is_global': true,
    };
  }

  /// Get total count of TikTok links
  Future<int> getTotalLinksCount() async {
    try {
      return await _repository.getTikTokLinksCount();
    } catch (e) {
      print('Error getting total links count: $e');
      rethrow;
    }
  }

  /// Clear cached links
  void clearCache() {
    _cachedLinks.clear();
    _isLoaded = false;
  }

  /// Validate TikTok URL
  bool isValidTikTokUrl(String url) {
    final tiktokRegex = RegExp(
      r'^https?:\/\/(www\.)?(tiktok\.com|vm\.tiktok\.com|vt\.tiktok\.com)\/.*',
      caseSensitive: false,
    );
    return tiktokRegex.hasMatch(url);
  }

  /// Get random TikTok URL with fallback logic
  String getRandomTikTokUrlWithFallback() {
    String? randomUrl = getRandomTikTokUrl();

    // Fallback to default TikTok URL if no links are available
    return randomUrl ?? "https://vt.tiktok.com/ZSBbKtJLv/";
  }

  /// Get all unique users who have created TikTok links
  List<String> getUniqueUsers() {
    return _cachedLinks.map((link) => link.userId).toSet().toList();
  }

  /// Get most recent links (limited count)
  List<TikTokLink> getRecentLinks({int limit = 10}) {
    final sortedLinks = List<TikTokLink>.from(_cachedLinks);
    sortedLinks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedLinks.take(limit).toList();
  }
}
