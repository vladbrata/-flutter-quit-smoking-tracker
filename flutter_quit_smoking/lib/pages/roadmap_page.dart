import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/health_milestone_model.dart';
import 'package:flutter_quit_smoking/widgets/lungs_progress_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Alias pentru compatibilitate
typedef Milestone = HealthMilestone;

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  DateTime? _startTime;
  Duration _timeElapsed = Duration.zero;
  Timer? _timer;

  final List<HealthMilestone> _milestones = HealthMilestoneService.milestones;

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
        const Duration(seconds: 1),
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
    final double overallProgress = HealthMilestoneService.calculateOverallProgress(_timeElapsed);
    final int completedCount = HealthMilestoneService.getCompletedCount(_timeElapsed);
    final int percentInt = (overallProgress * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme
      appBar: AppBar(
        title: const Text(
          "Traseu spre Sănătate",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _startTime == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: _milestones.length + 1, // +1 pentru cardul de rezumat/plămâni
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildHeaderCard(overallProgress, percentInt, completedCount),
                      );
                    }

                    final milestoneIndex = index - 1;
                    final milestone = _milestones[milestoneIndex];
                    final isCompleted = _timeElapsed >= milestone.duration;
                    final isNext = !isCompleted &&
                        (milestoneIndex == 0 ||
                            _timeElapsed >= _milestones[milestoneIndex - 1].duration);

                    return _buildTimelineTile(
                      milestone,
                      isCompleted,
                      isNext,
                      milestoneIndex == _milestones.length - 1,
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(double overallProgress, int percentInt, int completedCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D2429),
            Color(0xFF13181C),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          LungsProgressWidget(
            progress: overallProgress,
            size: 76,
            showPercentage: true,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "RECUPERARE PULMONARĂ",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$percentInt% Refăcut",
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$completedCount din ${_milestones.length} etape atinse",
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(
    HealthMilestone milestone,
    bool isCompleted,
    bool isNext,
    bool isLast,
  ) {
    Color statusColor = isCompleted
        ? const Color(0xFF00E676)
        : (isNext ? Colors.orangeAccent : Colors.grey.withValues(alpha: 0.3));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloană Timeline
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF00E676) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                  boxShadow: isCompleted || isNext
                      ? [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
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
                        ? const Color(0xFF00E676).withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.12),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Coloană Conținut
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        milestone.title,
                        style: TextStyle(
                          color: isCompleted || isNext
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        milestone.icon,
                        size: 15,
                        color: isCompleted
                            ? const Color(0xFF00E676)
                            : (isNext ? Colors.orangeAccent : Colors.white24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    milestone.description,
                    style: TextStyle(
                      color: isCompleted || isNext
                          ? Colors.white70
                          : Colors.white24,
                      fontSize: 13.5,
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
