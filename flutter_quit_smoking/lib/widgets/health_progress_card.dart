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
        color: const Color(0xFF121215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.air_rounded,
                            color: Color(0xFF2DD4BF),
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "RECUPERARE SĂNĂTATE",
                          style: TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.22),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "$percentInt%",
                            style: const TextStyle(
                              color: Color(0xFF2DD4BF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "($completedCount/$totalCount)",
                            style: const TextStyle(
                              color: Color(0xFF71717A),
                              fontSize: 10,
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
                      size: 68,
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
                                      color: Color(0xFFFAFAFA),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Text(
                                    HealthMilestoneService.formatTimeRemaining(timeRemaining),
                                    style: const TextStyle(
                                      color: Color(0xFFD4D4D8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextMilestone.description,
                              style: const TextStyle(
                                color: Color(0xFFA1A1AA),
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Mini bară de progres spre această bornă
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: nextMilestoneProgress,
                                minHeight: 3.5,
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2DD4BF),
                                ),
                              ),
                            ),
                          ] else ...[
                            const Text(
                              "Toate etapele atinse",
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Riscul bolilor legate de fumat a revenit la nivelul unui nefumător.",
                              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11.5),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Text(
                                "Vezi traseul complet",
                                style: TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 9,
                                color: Color(0xFFA1A1AA),
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
