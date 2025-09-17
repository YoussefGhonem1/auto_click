import 'package:auto_click/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../domain/models/tiktok_link.dart';
import '../../domain/services/tiktok_links_service.dart';
import '../../domain/services/auth_service.dart';

class TikTokLinksPage extends StatefulWidget {
  const TikTokLinksPage({super.key});

  @override
  State<TikTokLinksPage> createState() => _TikTokLinksPageState();
}

class _TikTokLinksPageState extends State<TikTokLinksPage> {
  final TikTokLinksService _tikTokLinksService = TikTokLinksService.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<TikTokLink> _links = [];
  List<TikTokLink> _filteredLinks = [];
  bool _isLoading = false;
  String? _currentUserId;
  String? _selectedUserFilter;

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
      }
      await _loadLinks();
    } catch (e) {
      _showErrorSnackBar('Error initializing user: $e');
    }
  }

  Future<void> _loadLinks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _tikTokLinksService.refreshLinks();
      setState(() {
        _links = _tikTokLinksService.getAllLinks();
        _filteredLinks = _links;
        _selectedUserFilter = null;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading links: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addLink() async {
    if (_currentUserId == null) {
      _showErrorSnackBar('Please log in to add links');
      return;
    }

    final url = _urlController.text.trim();
    final title = _titleController.text.trim();

    if (url.isEmpty) {
      _showErrorSnackBar('Please enter a TikTok link');
      return;
    }

    // Validate TikTok URL
    if (!_tikTokLinksService.isValidTikTokUrl(url)) {
      _showErrorSnackBar('Please enter a valid TikTok link');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newLink = TikTokLink(
        id: _generateId(),
        url: url,
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: _currentUserId!,
        isActive: true,
      );

      await _tikTokLinksService.addTikTokLink(newLink);

      setState(() {
        _links = _tikTokLinksService.getAllLinks();
        _applyFilters();
      });

      _urlController.clear();
      _titleController.clear();

      _showSuccessSnackBar('TikTok link added successfully');
    } catch (e) {
      _showErrorSnackBar('Error adding link: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLink(String linkId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _tikTokLinksService.deleteTikTokLink(linkId);

      setState(() {
        _links = _tikTokLinksService.getAllLinks();
        _applyFilters();
      });

      _showSuccessSnackBar('TikTok link deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Error deleting link: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<TikTokLink> filtered = _links;

    // Apply user filter
    if (_selectedUserFilter != null) {
      filtered = filtered
          .where((link) => link.userId == _selectedUserFilter)
          .toList();
    }

    // Apply search filter
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (link) =>
                link.title.toLowerCase().contains(searchQuery) ||
                link.url.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    setState(() {
      _filteredLinks = filtered;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public TikTok Links'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLinks),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Search links...',
                border: const OutlineInputBorder(),

                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
              ),
              onChanged: (value) => _applyFilters(),
            ),
          ),

          // Filter status
          if (_selectedUserFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Chip(
                    label: Text('Filter: User $_selectedUserFilter'),
                    onDeleted: () {
                      setState(() {
                        _selectedUserFilter = null;
                        _applyFilters();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Add link form
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: theme.colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: '(Optional) Title',
                    border: OutlineInputBorder(),
                    hintText: 'Enter a title for TikTok link',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _urlController,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: theme.colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'TikTok Link',
                    border: OutlineInputBorder(),
                    hintText: 'https://www.tiktok.com/@username/video/...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addLink,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Add Public TikTok Link',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Links list
          Expanded(
            child: _isLoading && _filteredLinks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredLinks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty ||
                                  _selectedUserFilter != null
                              ? 'No links match your filters'
                              : 'No TikTok links added yet.\nAdd your first public link above!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredLinks.length,
                    itemBuilder: (context, index) {
                      final link = _filteredLinks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.video_library,
                            color: Colors.blue,
                          ),
                          title: Text(
                            link.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            link.url,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.open_in_new,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  // Here you could open the URL in a browser or show a preview
                                  _showSuccessSnackBar('Link: ${link.url}');
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _showDeleteConfirmDialog(link),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(TikTokLink link) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Delete TikTok Link',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to delete "${link.title}"?',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteLink(link.id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
