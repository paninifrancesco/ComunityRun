import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/run.dart';
import '../../services/run_service.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';

class EditRunScreen extends ConsumerStatefulWidget {
  final String runId;

  const EditRunScreen({
    super.key,
    required this.runId,
  });

  @override
  ConsumerState<EditRunScreen> createState() => _EditRunScreenState();
}

class _EditRunScreenState extends ConsumerState<EditRunScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingInstructionsController = TextEditingController();
  final _estimatedDistanceController = TextEditingController();
  final _estimatedPaceController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedDifficulty = 'moderate';
  String _selectedRunType = 'Easy Run';
  String _selectedLanguage = 'English';
  bool _allowWaitingList = true;
  bool _isLoading = false;
  bool _isUpdating = false;

  Run? _originalRun;

  static const List<String> _difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert'
  ];

  static const List<String> _runTypes = [
    'Easy Run',
    'Tempo Run',
    'Intervals',
    'Fartlek',
    'Long Run',
    'Recovery Run',
    'Hill Training',
    'Track Workout'
  ];

  static const List<String> _languages = [
    'Italian',
    'English'
  ];

  @override
  void initState() {
    super.initState();
    _loadRunData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingInstructionsController.dispose();
    _estimatedDistanceController.dispose();
    _estimatedPaceController.dispose();
    _estimatedDurationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _loadRunData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final runService = ref.read(runServiceProvider);
      final run = await runService.getRunOnce(widget.runId);

      if (run == null) {
        throw Exception('Run not found');
      }

      _originalRun = run;
      _populateFields(run);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load run: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateFields(Run run) {
    _titleController.text = run.title;
    _descriptionController.text = run.description ?? '';
    _meetingInstructionsController.text = run.meetingInstructions ?? '';
    _estimatedDistanceController.text = run.estimatedDistance?.toString() ?? '';
    _estimatedPaceController.text = run.estimatedPace ?? '';
    _estimatedDurationController.text = run.estimatedDurationMinutes?.toString() ?? '';
    _maxParticipantsController.text = run.maxParticipants.toString();

    _selectedDate = DateTime(run.dateTime.year, run.dateTime.month, run.dateTime.day);
    _selectedTime = TimeOfDay.fromDateTime(run.dateTime);
    _selectedDifficulty = run.difficulty;
    _selectedRunType = run.runType;
    _selectedLanguage = run.language;
    _allowWaitingList = run.allowWaitingList;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Run')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Run'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_hasChanges())
            TextButton(
              onPressed: _isUpdating ? null : _resetChanges,
              child: const Text('Reset'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_originalRun?.participants.isNotEmpty == true) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This run has ${_originalRun!.participants.length} participants. '
                          'Changes will notify all participants.',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              _buildRunDetailsSection(),
              const SizedBox(height: 24),
              _buildParticipantSection(),
              const SizedBox(height: 24),
              _buildAdditionalInfoSection(),
              const SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Run Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a run title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate != null
                                ? DateFormat('EEEE, MMM d, y').format(_selectedDate!)
                                : 'Select date',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Time',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTime?.format(context) ?? 'Select time',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Run Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _estimatedDistanceController,
                    decoration: const InputDecoration(
                      labelText: 'Distance (km)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final distance = double.tryParse(value);
                        if (distance == null || distance <= 0) {
                          return 'Enter a valid distance';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _estimatedPaceController,
                    decoration: const InputDecoration(
                      labelText: 'Pace (min/km)',
                      hintText: 'e.g. 5:30',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _estimatedDurationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: _difficulties.map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty.toLowerCase(),
                        child: Text(difficulty),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRunType,
                    decoration: const InputDecoration(
                      labelText: 'Run Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _runTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRunType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _languages.map((language) {
                      return DropdownMenuItem(
                        value: language,
                        child: Text(language),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxParticipantsController,
              decoration: InputDecoration(
                labelText: 'Maximum Participants',
                border: const OutlineInputBorder(),
                helperText: _originalRun != null
                    ? 'Current: ${_originalRun!.participants.length} participants'
                    : null,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter max participants';
                }
                final count = int.tryParse(value);
                if (count == null || count < 2 || count > 50) {
                  return 'Enter a number between 2 and 50';
                }
                if (_originalRun != null && count < _originalRun!.participants.length) {
                  return 'Cannot reduce below current participant count (${_originalRun!.participants.length})';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Allow Waiting List'),
              subtitle: const Text('Let people join a waiting list if the run is full'),
              value: _allowWaitingList,
              onChanged: (value) {
                setState(() {
                  _allowWaitingList = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _meetingInstructionsController,
              decoration: const InputDecoration(
                labelText: 'Meeting Instructions (Optional)',
                hintText: 'e.g. Meet at the main entrance, look for someone in a red shirt',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isUpdating || !_hasChanges() ? null : _updateRun,
          child: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Run'),
        ),
      ),
    );
  }

  bool _hasChanges() {
    if (_originalRun == null) return false;

    final currentDateTime = _selectedDate != null && _selectedTime != null
        ? DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          )
        : null;

    return _titleController.text != _originalRun!.title ||
        _descriptionController.text != (_originalRun!.description ?? '') ||
        _meetingInstructionsController.text != (_originalRun!.meetingInstructions ?? '') ||
        _estimatedDistanceController.text != (_originalRun!.estimatedDistance?.toString() ?? '') ||
        _estimatedPaceController.text != (_originalRun!.estimatedPace ?? '') ||
        _estimatedDurationController.text != (_originalRun!.estimatedDurationMinutes?.toString() ?? '') ||
        _maxParticipantsController.text != _originalRun!.maxParticipants.toString() ||
        currentDateTime != _originalRun!.dateTime ||
        _selectedDifficulty != _originalRun!.difficulty ||
        _selectedRunType != _originalRun!.runType ||
        _selectedLanguage != _originalRun!.language ||
        _allowWaitingList != _originalRun!.allowWaitingList;
  }

  void _resetChanges() {
    if (_originalRun != null) {
      _populateFields(_originalRun!);
      setState(() {});
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _updateRun() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final runService = ref.read(runServiceProvider);
      final messageService = ref.read(messageServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final updatedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final updatedRun = _originalRun!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        meetingInstructions: _meetingInstructionsController.text.trim().isEmpty 
            ? null 
            : _meetingInstructionsController.text.trim(),
        dateTime: updatedDateTime,
        estimatedDistance: _estimatedDistanceController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_estimatedDistanceController.text),
        estimatedPace: _estimatedPaceController.text.trim().isEmpty 
            ? null 
            : _estimatedPaceController.text.trim(),
        estimatedDurationMinutes: _estimatedDurationController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_estimatedDurationController.text),
        maxParticipants: int.parse(_maxParticipantsController.text),
        difficulty: _selectedDifficulty,
        runType: _selectedRunType,
        language: _selectedLanguage,
        allowWaitingList: _allowWaitingList,
        updatedAt: DateTime.now(),
      );

      await runService.updateRun(updatedRun);

      // Send system message about the update
      await messageService.sendRunUpdatedMessage(widget.runId, currentUser.displayName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Run updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update run: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}