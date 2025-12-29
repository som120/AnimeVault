import 'package:ainme_vault/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AnimeEntryBottomSheet extends StatefulWidget {
  final Map<String, dynamic> anime;

  const AnimeEntryBottomSheet({super.key, required this.anime});

  @override
  State<AnimeEntryBottomSheet> createState() => _AnimeEntryBottomSheetState();
}

class _AnimeEntryBottomSheetState extends State<AnimeEntryBottomSheet> {
  String _status = "Save"; // Default
  int _progress = 0;
  int _score = 0;
  DateTime? _startDate;
  DateTime? _finishDate;
  late int _totalEpisodes;

  final List<String> _statuses = ["Watching", "Completed", "Save"];

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if available (mocking interaction for now)
    _totalEpisodes = widget.anime['episodes'] ?? 0;
    if (_totalEpisodes == 0) _totalEpisodes = 12; // Fallback or infinite?
  }

  @override
  Widget build(BuildContext context) {
    // Determine max episodes for slider/picker.
    // If unknown, we might need a different UI, but assuming standard for now.
    final maxEps = _totalEpisodes > 0
        ? _totalEpisodes
        : 100; // Cap at 100 if unknown for UI demo

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey,
                ),
                Text(
                  "Edit Entry",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    // TODO: Save logic
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Status
                  _buildSectionTitle("Status"),
                  const SizedBox(height: 12),
                  Row(
                    children: _statuses.map((status) {
                      final isSelected = _status == status;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _status = status;
                                if (_status == "Completed" &&
                                    _totalEpisodes > 0) {
                                  _progress = _totalEpisodes;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.transparent),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primary.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 3. Progress (Sliding Horizontal)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Episode Progress"),
                      Text(
                        "$_progress / ${_totalEpisodes > 0 ? _totalEpisodes : '?'}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: maxEps + 1,
                      controller: ScrollController(
                        initialScrollOffset:
                            _progress *
                                54.0 - // 50 (width) + 4 (horizontal margin)
                            (MediaQuery.of(context).size.width / 2) +
                            25, // Half of item width
                      ),
                      itemBuilder: (context, index) {
                        final isSelected = index == _progress;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _progress = index;
                              // Auto-update status logic
                              if (_progress == _totalEpisodes &&
                                  _totalEpisodes > 0) {
                                _status = "Completed";
                              } else if (_progress > 0) {
                                _status = "Watching";
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$index",
                              style: TextStyle(
                                fontSize: isSelected ? 20 : 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Rating (0-10)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Rating"),
                      if (_score > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$_score",
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(11, (index) {
                        final isSelected = index == _score;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _score = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.grey.shade300,
                                ),
                                boxShadow: [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "$index",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Date Selectors
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateSelector(
                          "Start Date",
                          _startDate,
                          (date) => setState(() => _startDate = date),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateSelector(
                          "Finish Date",
                          _finishDate,
                          (date) => setState(() => _finishDate = date),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 6. Remove Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // TODO: Implement remove logic
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 22),
                      label: const Text(
                        "Remove from list",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime? date,
    Function(DateTime) onSelect,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onSelect(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: date != null ? AppTheme.primary : Colors.grey.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy').format(date)
                        : "Select Date",
                    style: TextStyle(
                      color: date != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                      fontWeight: date != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
