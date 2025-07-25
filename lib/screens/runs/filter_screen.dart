import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RunFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final TimeOfDay? earliestTime;
  final TimeOfDay? latestTime;
  final double minDistance;
  final double maxDistance;
  final String? minPace;
  final String? maxPace;
  final List<String> runTypes;
  final List<String> difficulties;
  final bool availableSpotsOnly;
  final String? language;
  final double radiusKm;
  final RunSortOption sortBy;

  const RunFilters({
    this.startDate,
    this.endDate,
    this.earliestTime,
    this.latestTime,
    this.minDistance = 0.0,
    this.maxDistance = 50.0,
    this.minPace,
    this.maxPace,
    this.runTypes = const [],
    this.difficulties = const [],
    this.availableSpotsOnly = false,
    this.language,
    this.radiusKm = 10.0,
    this.sortBy = RunSortOption.distance,
  });

  RunFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? earliestTime,
    TimeOfDay? latestTime,
    double? minDistance,
    double? maxDistance,
    String? minPace,
    String? maxPace,
    List<String>? runTypes,
    List<String>? difficulties,
    bool? availableSpotsOnly,
    String? language,
    double? radiusKm,
    RunSortOption? sortBy,
  }) {
    return RunFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      earliestTime: earliestTime ?? this.earliestTime,
      latestTime: latestTime ?? this.latestTime,
      minDistance: minDistance ?? this.minDistance,
      maxDistance: maxDistance ?? this.maxDistance,
      minPace: minPace ?? this.minPace,
      maxPace: maxPace ?? this.maxPace,
      runTypes: runTypes ?? this.runTypes,
      difficulties: difficulties ?? this.difficulties,
      availableSpotsOnly: availableSpotsOnly ?? this.availableSpotsOnly,
      language: language ?? this.language,
      radiusKm: radiusKm ?? this.radiusKm,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get isEmpty {
    return startDate == null &&
        endDate == null &&
        earliestTime == null &&
        latestTime == null &&
        minDistance == 0.0 &&
        maxDistance == 50.0 &&
        minPace == null &&
        maxPace == null &&
        runTypes.isEmpty &&
        difficulties.isEmpty &&
        !availableSpotsOnly &&
        language == null &&
        radiusKm == 10.0 &&
        sortBy == RunSortOption.distance;
  }

  int get activeFilterCount {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (earliestTime != null || latestTime != null) count++;
    if (minDistance > 0.0 || maxDistance < 50.0) count++;
    if (minPace != null || maxPace != null) count++;
    if (runTypes.isNotEmpty) count++;
    if (difficulties.isNotEmpty) count++;
    if (availableSpotsOnly) count++;
    if (language != null) count++;
    if (radiusKm != 10.0) count++;
    if (sortBy != RunSortOption.distance) count++;
    return count;
  }
}

enum RunSortOption {
  distance('Distance (Nearest)'),
  startTime('Start Time'),
  recentlyCreated('Recently Created'),
  mostParticipants('Most Participants');

  const RunSortOption(this.displayName);
  final String displayName;
}

final runFiltersProvider = StateProvider<RunFilters>((ref) => const RunFilters());

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  late RunFilters _currentFilters;

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

  static const List<String> _difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert'
  ];

  static const List<String> _languages = [
    'Italian',
    'English'
  ];

  @override
  void initState() {
    super.initState();
    _currentFilters = ref.read(runFiltersProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter Runs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text('Clear All'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateTimeSection(),
            const SizedBox(height: 24),
            _buildDistanceSection(),
            const SizedBox(height: 24),
            _buildPaceSection(),
            const SizedBox(height: 24),
            _buildRunTypeSection(),
            const SizedBox(height: 24),
            _buildDifficultySection(),
            const SizedBox(height: 24),
            _buildAvailabilitySection(),
            const SizedBox(height: 24),
            _buildLanguageSection(),
            const SizedBox(height: 24),
            _buildRadiusSection(),
            const SizedBox(height: 24),
            _buildSortingSection(),
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
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
                  child: _buildQuickDateFilter('Today', () {
                    final today = DateTime.now();
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        startDate: DateTime(today.year, today.month, today.day),
                        endDate: DateTime(today.year, today.month, today.day, 23, 59),
                      );
                    });
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickDateFilter('Tomorrow', () {
                    final tomorrow = DateTime.now().add(const Duration(days: 1));
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        startDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
                        endDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59),
                      );
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickDateFilter('This Week', () {
                    final now = DateTime.now();
                    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                    final endOfWeek = startOfWeek.add(const Duration(days: 6));
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
                        endDate: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59),
                      );
                    });
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickDateFilter('Custom Range', () async {
                    await _showCustomDatePicker();
                  }),
                ),
              ],
            ),
            if (_currentFilters.startDate != null || _currentFilters.endDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDateRange(_currentFilters.startDate, _currentFilters.endDate),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentFilters = _currentFilters.copyWith(
                            startDate: null,
                            endDate: null,
                          );
                        });
                      },
                      icon: const Icon(Icons.clear),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    'Earliest Time',
                    _currentFilters.earliestTime,
                    (time) => setState(() {
                      _currentFilters = _currentFilters.copyWith(earliestTime: time);
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    'Latest Time',
                    _currentFilters.latestTime,
                    (time) => setState(() {
                      _currentFilters = _currentFilters.copyWith(latestTime: time);
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateFilter(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? selectedTime, Function(TimeOfDay?) onChanged) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
        );
        if (time != null) {
          onChanged(time);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedTime?.format(context) ?? 'Any time',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (selectedTime != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: Icon(Icons.clear, size: 16, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distance Range',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: RangeValues(_currentFilters.minDistance, _currentFilters.maxDistance),
              min: 0.0,
              max: 50.0,
              divisions: 50,
              labels: RangeLabels(
                '${_currentFilters.minDistance.toStringAsFixed(1)}km',
                '${_currentFilters.maxDistance.toStringAsFixed(1)}km',
              ),
              onChanged: (values) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(
                    minDistance: values.start,
                    maxDistance: values.end,
                  );
                });
              },
            ),
            Text(
              '${_currentFilters.minDistance.toStringAsFixed(1)}km - ${_currentFilters.maxDistance.toStringAsFixed(1)}km',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pace Range',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPaceInput(
                    'Min Pace (min/km)',
                    _currentFilters.minPace,
                    (pace) => setState(() {
                      _currentFilters = _currentFilters.copyWith(minPace: pace);
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPaceInput(
                    'Max Pace (min/km)',
                    _currentFilters.maxPace,
                    (pace) => setState(() {
                      _currentFilters = _currentFilters.copyWith(maxPace: pace);
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaceInput(String label, String? value, Function(String?) onChanged) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'e.g. 5:30',
        border: const OutlineInputBorder(),
        suffixIcon: value != null
            ? IconButton(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
      onChanged: onChanged,
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildRunTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Run Types',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _runTypes.map((type) {
                final isSelected = _currentFilters.runTypes.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      final newTypes = List<String>.from(_currentFilters.runTypes);
                      if (selected) {
                        newTypes.add(type);
                      } else {
                        newTypes.remove(type);
                      }
                      _currentFilters = _currentFilters.copyWith(runTypes: newTypes);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty Levels',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _difficulties.map((difficulty) {
                final isSelected = _currentFilters.difficulties.contains(difficulty);
                return FilterChip(
                  label: Text(difficulty),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      final newDifficulties = List<String>.from(_currentFilters.difficulties);
                      if (selected) {
                        newDifficulties.add(difficulty);
                      } else {
                        newDifficulties.remove(difficulty);
                      }
                      _currentFilters = _currentFilters.copyWith(difficulties: newDifficulties);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Availability',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Only show runs with available spots'),
              value: _currentFilters.availableSpotsOnly,
              onChanged: (value) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(
                    availableSpotsOnly: value ?? false,
                  );
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language Preference',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currentFilters.language,
              decoration: const InputDecoration(
                labelText: 'Preferred Language',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Any Language'),
                ),
                ..._languages.map((language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(language: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Radius',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _currentFilters.radiusKm,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              label: '${_currentFilters.radiusKm.toStringAsFixed(0)}km',
              onChanged: (value) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(radiusKm: value);
                });
              },
            ),
            Text(
              '${_currentFilters.radiusKm.toStringAsFixed(0)} kilometers from your location',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...RunSortOption.values.map((option) {
              return RadioListTile<RunSortOption>(
                title: Text(option.displayName),
                value: option,
                groupValue: _currentFilters.sortBy,
                onChanged: (value) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(sortBy: value);
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear All'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: Text(
                _currentFilters.activeFilterCount > 0
                    ? 'Apply (${_currentFilters.activeFilterCount})'
                    : 'Apply Filters',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _currentFilters.startDate != null && _currentFilters.endDate != null
          ? DateTimeRange(
              start: _currentFilters.startDate!,
              end: _currentFilters.endDate!,
            )
          : null,
    );

    if (dateRange != null) {
      setState(() {
        _currentFilters = _currentFilters.copyWith(
          startDate: dateRange.start,
          endDate: dateRange.end,
        );
      });
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    final formatter = DateFormat('MMM d');
    if (start != null && end != null) {
      if (start.year == end.year && start.month == end.month && start.day == end.day) {
        return formatter.format(start);
      }
      return '${formatter.format(start)} - ${formatter.format(end)}';
    } else if (start != null) {
      return 'From ${formatter.format(start)}';
    } else if (end != null) {
      return 'Until ${formatter.format(end)}';
    }
    return '';
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters = const RunFilters();
    });
  }

  void _applyFilters() {
    ref.read(runFiltersProvider.notifier).state = _currentFilters;
    Navigator.of(context).pop();
  }
}