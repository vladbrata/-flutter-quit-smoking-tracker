import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Milestone {
  final String title;
  final String description;
  final Duration duration;

  Milestone({
    required this.title,
    required this.description,
    required this.duration,
  });
}

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  DateTime? _startTime;
  Duration _timeElapsed = Duration.zero;
  Timer? _timer;

  final List<Milestone> _milestones = [
    // Short-Term
    Milestone(
      title: "20 Minutes",
      description:
          "Health check: Heart rate and blood pressure drop to normal.",
      duration: const Duration(minutes: 20),
    ),
    Milestone(
      title: "8 Hours",
      description:
          "Carbon monoxide levels drop by half. Oxygen levels return to normal.",
      duration: const Duration(hours: 8),
    ),
    Milestone(
      title: "24 Hours",
      description:
          "Heart attack risk begins to decrease. Lungs start clearing mucus.",
      duration: const Duration(hours: 24),
    ),
    Milestone(
      title: "48 Hours",
      description: "Nicotine free! Taste and smell begin to improve.",
      duration: const Duration(hours: 48),
    ),
    Milestone(
      title: "72 Hours",
      description:
          "Breathing becomes easier. Bronchial tubes relax and energy increases.",
      duration: const Duration(hours: 72),
    ),
    // Medium-Term
    Milestone(
      title: "2 Weeks",
      description: "Circulation improves. Walking and running become easier.",
      duration: const Duration(days: 14),
    ),
    Milestone(
      title: "1 Month",
      description:
          "Lung cilia recover. Coughing and shortness of breath decrease.",
      duration: const Duration(days: 30),
    ),
    Milestone(
      title: "1 Year",
      description: "Risk of coronary heart disease is half that of a smoker.",
      duration: const Duration(days: 365),
    ),
    // Long-Term
    Milestone(
      title: "5 Years",
      description:
          "Stroke risk drops to that of a non-smoker. Mouth/throat cancer risk halved.",
      duration: const Duration(days: 365 * 5),
    ),
    Milestone(
      title: "10 Years",
      description: "Lung cancer death risk is half that of a smoker.",
      duration: const Duration(days: 365 * 10),
    ),
    Milestone(
      title: "15 Years",
      description: "Coronary heart disease risk matches a non-smoker.",
      duration: const Duration(days: 365 * 15),
    ),
    Milestone(
      title: "20 Years",
      description:
          "Risk of death from smoking-related causes matches a never-smoker.",
      duration: const Duration(days: 365 * 20),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStartTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? startStr = prefs.getString('start_time');
    if (startStr != null) {
      setState(() {
        _startTime = DateTime.parse(startStr);
        _updateElapsed();
      });
      // Update timer every minute to refresh progress
      _timer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _updateElapsed(),
      );
    }
  }

  void _updateElapsed() {
    if (_startTime != null) {
      setState(() {
        _timeElapsed = DateTime.now().difference(_startTime!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme
      appBar: AppBar(
        title: const Text(
          "Your Journey",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _startTime == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: _milestones.length,
              itemBuilder: (context, index) {
                final milestone = _milestones[index];
                final isCompleted = _timeElapsed >= milestone.duration;
                final isNext =
                    !isCompleted &&
                    (index == 0 ||
                        _timeElapsed >= _milestones[index - 1].duration);

                return _buildTimelineTile(
                  milestone,
                  isCompleted,
                  isNext,
                  index == _milestones.length - 1,
                );
              },
            ),
    );
  }

  Widget _buildTimelineTile(
    Milestone milestone,
    bool isCompleted,
    bool isNext,
    bool isLast,
  ) {
    Color statusColor = isCompleted
        ? Colors.greenAccent
        : (isNext ? Colors.orangeAccent : Colors.grey.withOpacity(0.3));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Column
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.greenAccent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                  boxShadow: isCompleted || isNext
                      ? [
                          BoxShadow(
                            color: statusColor.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : [],
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.black)
                    : (isNext
                          ? const Icon(
                              Icons.access_time_filled,
                              size: 16,
                              color: Colors.orangeAccent,
                            )
                          : null),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? Colors.greenAccent.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: TextStyle(
                      color: isCompleted || isNext
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    milestone.description,
                    style: TextStyle(
                      color: isCompleted || isNext
                          ? Colors.white70
                          : Colors.white24,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
