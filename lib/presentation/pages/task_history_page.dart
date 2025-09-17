import 'package:flutter/material.dart';
import '../../domain/models/task.dart';
import '../../domain/services/task_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/theme/app_theme.dart';

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({super.key});

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  final TaskService _taskService = TaskService();

  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _taskService.getAllTasks();
      setState(() {
        _allTasks = tasks;
        _filteredTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load task history');
      }
    }
  }

  void _filterTasks() {
    setState(() {
      _filteredTasks = _allTasks.where((task) {
        // Filter by search query (link)
        bool matchesSearch =
            _searchQuery.isEmpty ||
            _getTaskLink(
              task,
            ).toLowerCase().contains(_searchQuery.toLowerCase());

        // Filter by status
        bool matchesStatus =
            _selectedStatus == 'all' ||
            task.status.toLowerCase() == _selectedStatus.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  String _getTaskLink(Task task) {
    // Extract link from task data based on task type
    switch (task.type) {
      case 'comment':
      case 'watch':
      case 'share':
      case 'like':
      case 'favorite':
        return task.data['videoUrl'] ?? task.data['url'] ?? 'No link available';
      case 'direct_message':
        return task.data['usernames']?.join(', ') ?? 'No users';
      default:
        return 'Unknown task type';
    }
  }

  String _getTaskTypeText(String type) {
    switch (type) {
      case 'comment':
        return 'Comment';
      case 'watch':
        return 'Watch';
      case 'share':
        return 'Share';
      case 'like':
        return 'Like';
      case 'favorite':
        return 'Favorite';
      case 'direct_message':
        return 'Direct Message';
      default:
        return type;
    }
  }

  int _getTaskCount(Task task) {
    switch (task.type) {
      case 'comment':
        return (task.data['comments'] as List?)?.length ?? 0;
      case 'watch':
        return task.data['numberOfWatches'] ?? 0;
      case 'share':
        return task.data['numberOfShares'] ?? 0;
      case 'like':
        return task.data['numberOfLikes'] ?? 0;
      case 'favorite':
        return task.data['numberOfFavorites'] ?? 0;
      case 'direct_message':
        return task.data['numberOfAccounts'] ?? 0;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task History'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by link...',
                    hintStyle: AppTextStyles.body1.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterTasks();
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Status Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatusChip('all', 'All'),
                    const SizedBox(width: 8),
                    _buildStatusChip('pending', 'Pending'),
                    const SizedBox(width: 8),
                    _buildStatusChip('assigned', 'Assigned'),
                    const SizedBox(width: 8),
                    _buildStatusChip('in_progress', 'In Progress'),
                    const SizedBox(width: 8),
                    _buildStatusChip('completed', 'Completed'),
                    const SizedBox(width: 8),
                    _buildStatusChip('failed', 'Failed'),
                  ],
                ),
              ),
            ],
          ),
          // Tasks List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      return _buildTaskCard(task);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
        _filterTasks();
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != 'all'
                ? 'No tasks match the search'
                : 'No tasks in history',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != 'all'
                ? 'Try changing search criteria'
                : 'Tasks will appear here after creation',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final taskCount = _getTaskCount(task);
    final taskLink = _getTaskLink(task);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getStatusColor(
                      task.status,
                      context,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.getStatusColor(
                        task.status,
                        context,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getTaskTypeText(task.type),
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.getStatusColor(task.status, context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getStatusColor(
                      task.status,
                      context,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.getStatusColor(
                        task.status,
                        context,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(task.status),
                    style: TextStyle(
                      color: AppColors.getStatusColor(task.status, context),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(task.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Link
            Row(
              children: [
                const Icon(Icons.link, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    taskLink,
                    style: AppTextStyles.caption(context).copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (task.assignedTo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned to: ${task.assignedTo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Count
            Row(
              children: [
                const Icon(Icons.numbers, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Number sent: $taskCount',
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}
