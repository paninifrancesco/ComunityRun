import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/safety_service.dart';
import '../../services/user_profile_service.dart';
import '../../models/user_profile.dart';

class SafetyScreen extends ConsumerStatefulWidget {
  const SafetyScreen({super.key});

  @override
  ConsumerState<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends ConsumerState<SafetyScreen> with SingleTickerProviderStateMixin {
  late final SafetyService _safetyService;
  late final UserProfileService _userProfileService;
  
  late TabController _tabController;
  List<String> _blockedUsers = [];
  List<Report> _userReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _safetyService = ref.read(safetyServiceProvider);
    _userProfileService = ref.read(userProfileServiceProvider);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final blockedUsers = await _safetyService.getBlockedUsers(currentUser.uid);
      final reports = await _safetyService.getUserReports(currentUser.uid);
      
      setState(() {
        _blockedUsers = blockedUsers;
        _userReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading data: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & Security'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.security), text: 'Guidelines'),
            Tab(icon: Icon(Icons.block), text: 'Blocked Users'),
            Tab(icon: Icon(Icons.report), text: 'My Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGuidelinesTab(),
          _buildBlockedUsersTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildGuidelinesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Safety Guidelines',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('🏃‍♀️ Always meet in public, well-lit locations'),
                  SizedBox(height: 8),
                  Text('📱 Share your location with trusted contacts'),
                  SizedBox(height: 8),
                  Text('👥 Bring a friend if you feel uncertain'),
                  SizedBox(height: 8),
                  Text('🚨 Trust your instincts - leave if uncomfortable'),
                  SizedBox(height: 8),
                  Text('📞 Keep emergency contacts updated'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.group, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Community Guidelines',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('• Be respectful and inclusive to all runners'),
                  const SizedBox(height: 8),
                  const Text('• Communicate clearly about pace and distance'),
                  const SizedBox(height: 8),
                  const Text('• Show up on time or cancel with notice'),
                  const SizedBox(height: 8),
                  const Text('• No harassment, discrimination, or inappropriate behavior'),
                  const SizedBox(height: 8),
                  const Text('• Keep group conversations friendly and supportive'),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) => ElevatedButton.icon(
                      onPressed: () => context.push('/safety-guidelines'),
                      icon: const Icon(Icons.menu_book),
                      label: const Text('View Complete Safety Guidelines'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.report_problem, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Emergency Features',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('• SOS button available during active runs'),
                  const SizedBox(height: 8),
                  const Text('• Automatic location sharing with emergency contacts'),
                  const SizedBox(height: 8),
                  const Text('• Quick access to local emergency services'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/emergency-settings'),
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure Emergency Settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_blockedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Blocked Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Users you block will appear here.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _blockedUsers.length,
        itemBuilder: (context, index) {
          final blockedUserId = _blockedUsers[index];
          return _buildBlockedUserCard(blockedUserId);
        },
      ),
    );
  }

  Widget _buildBlockedUserCard(String userId) {
    return FutureBuilder<UserProfile?>(
      future: _userProfileService.getUserProfile(userId).first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading...'),
            ),
          );
        }

        final user = snapshot.data!;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: Text(
                user.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user.displayName),
            subtitle: Text('Blocked on ${_formatDate(DateTime.now())}'),
            trailing: TextButton(
              onPressed: () => _unblockUser(userId),
              child: const Text('Unblock'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Reports Submitted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your safety reports will appear here.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userReports.length,
        itemBuilder: (context, index) {
          final report = _userReports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    Color statusColor;
    IconData statusIcon;
    
    switch (report.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'reviewed':
        statusColor = Colors.blue;
        statusIcon = Icons.visibility;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  report.type.name.replaceAllMapped(
                    RegExp(r'([A-Z])'),
                    (match) => ' ${match.group(0)}',
                  ).trim(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    report.status.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reported: ${_formatDate(report.timestamp)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                report.description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _unblockUser(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final success = await _safetyService.unblockUser(
        blockerId: currentUser.uid,
        blockedUserId: userId,
      );

      if (success) {
        await _loadData();
        _showSnackBar('User unblocked successfully');
      } else {
        _showSnackBar('Failed to unblock user');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}