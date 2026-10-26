import 'package:flutter/material.dart';
import 'package:flutter_quit_smoking/pages/models/craving_model.dart';
import 'package:flutter_quit_smoking/pages/models/relapse_model.dart';
import 'package:flutter_quit_smoking/services/auth_services.dart';
import 'package:flutter_quit_smoking/services/database_service.dart';

class CravingRelapseHistoryDialog extends StatefulWidget {
  const CravingRelapseHistoryDialog({super.key});

  @override
  State<CravingRelapseHistoryDialog> createState() =>
      _CravingRelapseHistoryDialogState();
}

class _CravingRelapseHistoryDialogState
    extends State<CravingRelapseHistoryDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  CravingSummary? _cravingSummary;
  RelapseSummary? _relapseSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = authServices.value.currentUser;
    final cravingSummary = await databaseService.getCravingSummary(uid: user?.uid);
    final relapseSummary = await databaseService.getRelapseSummary(uid: user?.uid);

    if (!mounted) return;
    setState(() {
      _cravingSummary = cravingSummary;
      _relapseSummary = relapseSummary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = authServices.value.currentUser;

    return Dialog(
      backgroundColor: const Color(0xFF141417),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.history_edu_rounded,
                    color: Color(0xFFFB7185),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Jurnal Pofte & Recidive",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            user != null ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
                            size: 13,
                            color: user != null ? const Color(0xFF10B981) : const Color(0xFFA1A1AA),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user != null
                                ? "Salvat în Firestore (users/${user.uid.substring(0, 5)}...)"
                                : "Salvat local pe dispozitiv",
                            style: TextStyle(
                              color: user != null ? const Color(0xFF34D399) : const Color(0xFFA1A1AA),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F1D24),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFB7185),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFE11D48).withValues(alpha: 0.28),
                  border: Border.all(
                    color: const Color(0xFFFB7185).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFA1A1AA),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    text: "Pofte Înregistrate (${_cravingSummary?.totalCravings ?? 0})",
                    icon: const Icon(Icons.psychology_rounded, size: 17),
                  ),
                  Tab(
                    text: "Recidive (${_relapseSummary?.totalRelapses ?? 0})",
                    icon: const Icon(Icons.warning_amber_rounded, size: 17),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFB7185)),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCravingsTab(),
                        _buildRelapsesTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCravingsTab() {
    final cravings = _cravingSummary?.history ?? [];
    if (cravings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            const Text(
              "Nu ai înregistrat nicio poftă încă.",
              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              "Când simți o poftă, apasă pe SOS și scrie motivul pentru ca AI-ul să o anticipeze.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Peak hours summary chip
        if (_cravingSummary != null && _cravingSummary!.peakHours.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1418),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFB7185).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm_on_rounded, color: Color(0xFFFB7185), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Ore de vârf ale poftelor: ${_cravingSummary!.peakHours.map((h) => '${h.toString().padLeft(2, '0')}:00').join(', ')}",
                    style: const TextStyle(
                      color: Color(0xFFFFF1F2),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.separated(
            itemCount: cravings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = cravings[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.formattedTime,
                                style: const TextStyle(
                                  color: Color(0xFFFB7185),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c.triggerDisplayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          c.formattedDate.split(' la ').first,
                          style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                        ),
                      ],
                    ),
                    if (c.reason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141417),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: Text(
                          "\"${c.reason}\"",
                          style: const TextStyle(
                            color: Color(0xFFE4E4E7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Intensitate: ${c.intensity}/10",
                          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                        ),
                        if (c.overcame)
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                              SizedBox(width: 4),
                              Text(
                                "Depășită cu succes",
                                style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelapsesTab() {
    final relapses = _relapseSummary?.history ?? [];
    if (relapses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_rounded, size: 48, color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text(
              "Nicio recidivă înregistrată! Felicitări!",
              style: TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Continuă să fii vigilent. AI-ul îți protejează parcursul.",
              style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: relapses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = relapses[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${r.hourOfDay.toString().padLeft(2, '0')}:${r.relapsedAt.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r.triggerDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    r.formattedDate.split(' la ').first,
                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                  ),
                ],
              ),
              if (r.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141417),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "\"${r.notes}\"",
                    style: const TextStyle(
                      color: Color(0xFFE4E4E7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                "Timp rezistat: ${r.smokeFreeDurationFormatted} | Țigări: ${r.cigarettesSmoked}",
                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
