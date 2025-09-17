import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/tiktok_link.dart';
import '../../data/repositories/tiktok_links_repository.dart';
import '../../data/data_sources/tiktok_links_firestore_datasource.dart';

class TikTokLinksController extends ChangeNotifier {
  final TikTokLinksRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TikTokLink> _tiktokLinks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  TikTokLinksController()
    : _repository = TikTokLinksRepositoryImpl(TikTokLinksFirestoreDataSource());

  // Getters
  List<TikTokLink> get tiktokLinks => _searchQuery.isEmpty
      ? _tiktokLinks
      : _tiktokLinks
            .where(
              (link) =>
                  link.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  link.url.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get totalLinks => _tiktokLinks.length;

  String? get currentUserId => _auth.currentUser?.uid;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load TikTok links
  Future<void> loadTikTokLinks() async {
    if (currentUserId == null) {
      _setError('User not authorized');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      _tiktokLinks = await _repository.getTikTokLinks();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load TikTok links: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a single TikTok link
  Future<bool> addTikTokLink(String url, String title) async {
    if (currentUserId == null) {
      _setError('User not authorized');
      return false;
    }

    if (url.trim().isEmpty) {
      _setError('Link cannot be empty');
      return false;
    }

    _setError(null);

    try {
      final now = DateTime.now();
      final link = TikTokLink(
        id: '${currentUserId}_${now.millisecondsSinceEpoch}',
        url: url.trim(),
        title: title.trim().isEmpty ? 'TikTok Link' : title.trim(),
        createdAt: now,
        updatedAt: now,
        userId: currentUserId!,
        isActive: true,
      );

      if (!link.isValidTikTokUrl()) {
        _setError('Please enter a valid TikTok link');
        return false;
      }

      await _repository.addTikTokLink(link);
      _tiktokLinks.insert(0, link);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add TikTok link: $e');
      return false;
    }
  }

  // Add multiple TikTok links from text
  Future<int> addMultipleTikTokLinks(String text) async {
    if (currentUserId == null) {
      _setError('User not authorized');
      return 0;
    }

    _setError(null);

    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      _setError('No valid TikTok links found');
      return 0;
    }

    final links = <TikTokLink>[];
    final now = DateTime.now();
    int validCount = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Extract URL and title
      String url;
      String title;

      if (line.contains('|')) {
        final parts = line.split('|');
        url = parts[0].trim();
        title = parts.length > 1 ? parts[1].trim() : 'TikTok Link ${i + 1}';
      } else {
        url = line;
        title = 'TikTok Link ${i + 1}';
      }

      final link = TikTokLink(
        id: '${currentUserId}_${now.millisecondsSinceEpoch}_$i',
        url: url,
        title: title,
        createdAt: now.add(Duration(milliseconds: i)),
        updatedAt: now.add(Duration(milliseconds: i)),
        userId: currentUserId!,
        isActive: true,
      );

      if (link.isValidTikTokUrl()) {
        links.add(link);
        validCount++;
      }
    }

    if (links.isEmpty) {
      _setError('No valid TikTok links found');
      return 0;
    }

    try {
      await _repository.addMultipleTikTokLinks(links);
      _tiktokLinks.insertAll(0, links);
      notifyListeners();
      return validCount;
    } catch (e) {
      _setError('Failed to add TikTok links: $e');
      return 0;
    }
  }

  // Update a TikTok link
  Future<bool> updateTikTokLink(String linkId, String url, String title) async {
    _setError(null);

    try {
      final linkIndex = _tiktokLinks.indexWhere((link) => link.id == linkId);
      if (linkIndex == -1) {
        _setError('Link not found');
        return false;
      }

      final updatedLink = _tiktokLinks[linkIndex].copyWith(
        url: url.trim(),
        title: title.trim(),
        updatedAt: DateTime.now(),
      );

      if (!updatedLink.isValidTikTokUrl()) {
        _setError('Please enter a valid TikTok link');
        return false;
      }

      await _repository.updateTikTokLink(updatedLink);
      _tiktokLinks[linkIndex] = updatedLink;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update TikTok link: $e');
      return false;
    }
  }

  // Delete a TikTok link
  Future<bool> deleteTikTokLink(String linkId) async {
    _setError(null);

    try {
      await _repository.deleteTikTokLink(linkId);
      _tiktokLinks.removeWhere((link) => link.id == linkId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete TikTok link: $e');
      return false;
    }
  }

  // Search TikTok links
  void searchLinks(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Get link by ID
  TikTokLink? getLinkById(String linkId) {
    try {
      return _tiktokLinks.firstWhere((link) => link.id == linkId);
    } catch (e) {
      return null;
    }
  }

  // Validate TikTok URL
  bool isValidTikTokUrl(String url) {
    return url.contains('tiktok.com') || url.contains('vm.tiktok.com');
  }

  // Get statistics
  Map<String, int> getStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = today.subtract(const Duration(days: 7));
    final month = DateTime(now.year, now.month, 1);

    return {
      'total': _tiktokLinks.length,
      'today': _tiktokLinks
          .where((link) => link.createdAt.isAfter(today))
          .length,
      'thisWeek': _tiktokLinks
          .where((link) => link.createdAt.isAfter(week))
          .length,
      'thisMonth': _tiktokLinks
          .where((link) => link.createdAt.isAfter(month))
          .length,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
