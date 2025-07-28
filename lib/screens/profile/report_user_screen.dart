import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/safety_service.dart';

class ReportUserScreen extends ConsumerStatefulWidget {
  final String reportedUserId;
  final String reportedUserName;
  final String? runId;

  const ReportUserScreen({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
    this.runId,
  });

  @override
  ConsumerState<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends ConsumerState<ReportUserScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  
  ReportType? _selectedType;
  bool _isSubmitting = false;

  final Map<ReportType, String> _reportTypeLabels = {
    ReportType.inappropriateBehavior: 'Inappropriate Behavior',
    ReportType.noShow: 'No Show / Cancelled Last Minute',
    ReportType.harassment: 'Harassment or Bullying',
    ReportType.unsafeLocation: 'Unsafe Meeting Location',
    ReportType.spam: 'Spam or Promotional Content',
    ReportType.fakeProfile: 'Fake or Misleading Profile',
    ReportType.other: 'Other',
  };

  final Map<ReportType, String> _reportTypeDescriptions = {
    ReportType.inappropriateBehavior: 'Inappropriate comments, behavior, or actions during runs',
    ReportType.noShow: 'Failed to show up or cancelled without notice',
    ReportType.harassment: 'Threatening, abusive, or discriminatory behavior',
    ReportType.unsafeLocation: 'Suggested dangerous or inappropriate meeting places',
    ReportType.spam: 'Sending unwanted promotional messages or content',
    ReportType.fakeProfile: 'Using false information or stolen photos',
    ReportType.other: 'Issue not covered by other categories',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Reporting ${widget.reportedUserName}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please select the reason for reporting this user. False reports may result in restrictions on your account.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Reason for Report',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: ListView.builder(
                itemCount: ReportType.values.length,
                itemBuilder: (context, index) {
                  final type = ReportType.values[index];
                  return _buildReportTypeCard(type);
                },
              ),
            ),
            
            if (_selectedType != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Additional Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Please provide specific details about the incident...',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeCard(ReportType type) {
    final isSelected = _selectedType == type;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<ReportType>(
                value: type,
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _reportTypeLabels[type]!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _reportTypeDescriptions[type]!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedType == null) {
      _showSnackBar('Please select a reason for the report');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showSnackBar('Please provide additional details');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('You must be logged in to report users');
        return;
      }

      final safetyService = ref.read(safetyServiceProvider);
      final success = await safetyService.reportUser(
        reporterId: currentUser.uid,
        reportedUserId: widget.reportedUserId,
        runId: widget.runId,
        type: _selectedType!,
        description: _descriptionController.text.trim(),
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted successfully. Thank you for helping keep our community safe.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showSnackBar('Failed to submit report. Please try again.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}