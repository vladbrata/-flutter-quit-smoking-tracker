import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/health_milestone_model.dart';
import 'package:flutter_quit_smoking/pages/roadmap_page.dart';
import 'package:flutter_quit_smoking/widgets/lungs_progress_widget.dart';

class HealthProgressCard extends StatelessWidget {
  final Duration timeElapsed;
  final VoidCallback? onTap;

  const HealthProgressCard({
    super.key,
    required this.timeElapsed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double overallProgress = HealthMilestoneService.calculateOverallProgress(timeElapsed);
    final int completedCount = HealthMilestoneService.getCompletedCount(timeElapsed);
    final int totalCount = HealthMilestoneService.milestones.length;
    final HealthMilestone? nextMilestone = HealthMilestoneService.getNextMilestone(timeElapsed);
    final Duration timeRemaining = HealthMilestoneService.getTimeRemainingToNext(timeElapsed);
    final double nextMilestoneProgress = HealthMilestoneService.getNextMilestoneProgress(timeElapsed);

    final int percentInt = (overallProgress * 100).toInt();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0E2024), // nuanță discretă de cyan-teal închis
            Color(0xFF13181C), // fundal negru-cărbune
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RoadmapPage()),
                );
              },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Etichetă și Procentaj
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.air_rounded,
                            color: Color(0xFF00E5FF),
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "RECUPERARE SĂNĂTATE",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "$percentInt%",
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "($completedCount/$totalCount etape)",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Corp: Plămâni animați în stânga + Detalii etapă în dreapta
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Iconița Plămâni
                    LungsProgressWidget(
                      progress: overallProgress,
                      size: 72,
                      showPercentage: false,
                    ),
                    const SizedBox(width: 16),

                    // Informații despre progresul pe sănătate
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (nextMilestone != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Următoarea: ${nextMilestone.title}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    HealthMilestoneService.formatTimeRemaining(timeRemaining),
                                    style: const TextStyle(
                                      color: Color(0xFFFFCA28),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextMilestone.description,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Mini bară de progres spre această bornă
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: nextMilestoneProgress,
                                minHeight: 4.5,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                          ] else ...[
                            const Text(
                              "Felicitări! Toate etapele atinse!",
                              style: TextStyle(
                                color: Color(0xFF69F0AE),
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Riscul bolilor legate de fumat a revenit complet la nivelul unui nefumător.",
                              style: TextStyle(color: Colors.white70, fontSize: 11.5),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Text(
                                "Vezi traseul complet",
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: Color(0xFF00E5FF),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
