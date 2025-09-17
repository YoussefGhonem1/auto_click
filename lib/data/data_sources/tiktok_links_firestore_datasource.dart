import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/tiktok_link.dart';

class TikTokLinksFirestoreDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tiktok_links';

  // Add a new TikTok link
  Future<void> addTikTokLink(TikTokLink link) async {
    try {
      await _firestore.collection(_collection).doc(link.id).set(link.toMap());
    } catch (e) {
      throw Exception('Failed to add TikTok link: $e');
    }
  }

  // Get all TikTok links (global)
  Future<List<TikTokLink>> getTikTokLinks() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TikTokLink.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get TikTok links: $e');
    }
  }

  // Get a specific TikTok link by ID
  Future<TikTokLink?> getTikTokLink(String linkId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(linkId).get();

      if (doc.exists) {
        return TikTokLink.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get TikTok link: $e');
    }
  }

  // Update a TikTok link
  Future<void> updateTikTokLink(TikTokLink link) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(link.id)
          .update(link.toMap());
    } catch (e) {
      throw Exception('Failed to update TikTok link: $e');
    }
  }

  // Delete a TikTok link (soft delete by setting isActive to false)
  Future<void> deleteTikTokLink(String linkId) async {
    try {
      await _firestore.collection(_collection).doc(linkId).delete();
    } catch (e) {
      throw Exception('Failed to delete TikTok link: $e');
    }
  }

  // Permanently delete a TikTok link
  Future<void> permanentlyDeleteTikTokLink(String linkId) async {
    try {
      await _firestore.collection(_collection).doc(linkId).delete();
    } catch (e) {
      throw Exception('Failed to permanently delete TikTok link: $e');
    }
  }

  // Stream of all TikTok links for real-time updates
  Stream<List<TikTokLink>> getTikTokLinksStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TikTokLink.fromMap(doc.data()))
              .toList(),
        );
  }

  // Batch add multiple TikTok links
  Future<void> addMultipleTikTokLinks(List<TikTokLink> links) async {
    try {
      final batch = _firestore.batch();
      for (final link in links) {
        final docRef = _firestore.collection(_collection).doc(link.id);
        batch.set(docRef, link.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add multiple TikTok links: $e');
    }
  }

  // Search TikTok links by title or URL (global search)
  Future<List<TikTokLink>> searchTikTokLinks(String query) async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();

      return querySnapshot.docs
          .map((doc) => TikTokLink.fromMap(doc.data()))
          .where(
            (link) =>
                link.title.toLowerCase().contains(query.toLowerCase()) ||
                link.url.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search TikTok links: $e');
    }
  }

  // Get total TikTok links count
  Future<int> getTikTokLinksCount() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get TikTok links count: $e');
    }
  }
}
