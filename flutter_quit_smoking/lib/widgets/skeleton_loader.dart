import 'package:flutter/material.dart';

/// Furnizor de efect animat de tip Shimmer pentru scheletele din UI.
class SkeletonShimmer extends StatefulWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double value = _controller.value;
            // Glisare de la stânga la dreapta (-2.0 la 2.0)
            final double slide = (value * 3.0) - 1.0;
            return LinearGradient(
              begin: Alignment(slide - 0.7, -0.3),
              end: Alignment(slide + 0.7, 0.3),
              colors: const [
                Color(0xFF1E1E24),
                Color(0xFF32323C),
                Color(0xFF1E1E24),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Un element de bază rectangular sau rotunjit pentru schelet
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF222228),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Schelet pentru cardul de Obiectiv Financiar
class SkeletonGoalCard extends StatelessWidget {
  const SkeletonGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF151518),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 44, height: 44, borderRadius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 160, height: 14, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: 220, height: 10, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const SkeletonBox(width: 20, height: 20, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}

/// Schelet pentru cardul mare cu Cronometrul (Timp fără fumat)
class SkeletonTimerCard extends StatelessWidget {
  const SkeletonTimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF151518),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: const [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 22, height: 22, borderRadius: 11),
                SizedBox(width: 8),
                SkeletonBox(width: 140, height: 12, borderRadius: 6),
              ],
            ),
            SizedBox(height: 18),
            SkeletonBox(width: 260, height: 38, borderRadius: 10),
            SizedBox(height: 14),
            SkeletonBox(width: 180, height: 10, borderRadius: 5),
          ],
        ),
      ),
    );
  }
}

/// Schelet pentru grila cu cele 2 coloane: Economii și Țigări Evitate
class SkeletonStatsGrid extends StatelessWidget {
  const SkeletonStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Row(
        children: [
          // Coloana 1: Economii
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF151518),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      SkeletonBox(width: 22, height: 22, borderRadius: 11),
                      SizedBox(width: 8),
                      SkeletonBox(width: 65, height: 11, borderRadius: 5),
                    ],
                  ),
                  SizedBox(height: 14),
                  SkeletonBox(width: 110, height: 22, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: 75, height: 10, borderRadius: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Coloana 2: Țigări Evitate
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF151518),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      SkeletonBox(width: 22, height: 22, borderRadius: 11),
                      SizedBox(width: 8),
                      SkeletonBox(width: 65, height: 11, borderRadius: 5),
                    ],
                  ),
                  SizedBox(height: 14),
                  SkeletonBox(width: 90, height: 22, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: 80, height: 10, borderRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Schelet pentru cardul de Recuperare Sănătate cu plămâni
class SkeletonHealthCard extends StatelessWidget {
  const SkeletonHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF151518),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    SkeletonBox(width: 22, height: 22, borderRadius: 11),
                    SizedBox(width: 8),
                    SkeletonBox(width: 140, height: 11, borderRadius: 5),
                  ],
                ),
                SkeletonBox(width: 90, height: 22, borderRadius: 11),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Simulare plămâni
                const SkeletonBox(width: 72, height: 72, borderRadius: 18),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 160, height: 14, borderRadius: 6),
                      SizedBox(height: 8),
                      SkeletonBox(width: 200, height: 10, borderRadius: 4),
                      SizedBox(height: 10),
                      SkeletonBox(height: 5, borderRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Schelet pentru un ecran complet (folosit la pornirea aplicației în AuthLayout)
class SkeletonPageLoading extends StatelessWidget {
  const SkeletonPageLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  SkeletonGoalCard(),
                  SizedBox(height: 16),
                  SkeletonTimerCard(),
                  SizedBox(height: 16),
                  SkeletonStatsGrid(),
                  SizedBox(height: 16),
                  SkeletonHealthCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Schelet pentru ecranul de Roadmap (Traseu Sănătate)
class SkeletonRoadmapView extends StatelessWidget {
  const SkeletonRoadmapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const SkeletonHealthCard(),
            const SizedBox(height: 24),
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SkeletonShimmer(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(width: 26, height: 26, borderRadius: 13),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonBox(width: 120, height: 16, borderRadius: 6),
                            SizedBox(height: 8),
                            SkeletonBox(width: 240, height: 12, borderRadius: 4),
                            SizedBox(height: 6),
                            SkeletonBox(width: 180, height: 12, borderRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Schelet pentru lista de obiective (GoalsPage și Dialog Obiective)
class SkeletonGoalList extends StatelessWidget {
  final int itemCount;

  const SkeletonGoalList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonGoalCard(),
        );
      },
    );
  }
}

