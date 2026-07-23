// Stage 5 & 8 & 9 — Dashboard Screen (Premium UI Refresh)
// Rich stat cards with animated counters, glassmorphism banner,
// quick action grid, animated activity log.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_translations.dart';
import '../providers/locale_provider.dart';
import '../providers/repository_providers.dart';
import '../services/sync_service.dart';
import '../widgets/screen_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final totalStudents = ref.watch(totalStudentsProvider);
    final totalSubjects = ref.watch(totalSubjectsProvider);
    final activities = ref.watch(recentActivityProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WelcomeBanner(lang: lang),
              const SizedBox(height: 24),
              _StatCardsRow(
                lang: lang,
                totalStudents: totalStudents,
                totalSubjects: totalSubjects,
              ),
              const SizedBox(height: 28),
              _QuickActionsSection(
                lang: lang,
                onNavigateTab: onNavigateTab,
              ),
              const SizedBox(height: 28),
              _ActivityLogSection(lang: lang, activities: activities),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome Banner — Glassmorphism
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatefulWidget {
  const _WelcomeBanner({required this.lang});
  final String lang;

  @override
  State<_WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<_WelcomeBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final timeStr = DateFormat('EEE, dd MMM yyyy').format(now);
    final lang = widget.lang;

    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            const Color(0xFF059669),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Row(
              children: [
                // Pulsing school icon
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: _pulse.value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school_rounded,
                        size: 38, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == 'bn'
                            ? 'institutionTitleBn'.tr(lang)
                            : 'institutionTitle'.tr(lang),
                        style: tt.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang == 'bn'
                            ? 'institutionTitle'.tr('en')
                            : 'institutionTitleBn'.tr('bn'),
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 11,
                                    color:
                                        Colors.white.withValues(alpha: 0.9)),
                                const SizedBox(width: 5),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Stat Cards Row — animated counter
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({
    required this.lang,
    required this.totalStudents,
    required this.totalSubjects,
  });

  final String lang;
  final int totalStudents;
  final int totalSubjects;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        icon: Icons.people_alt_rounded,
        titleKey: 'totalStudents',
        value: totalStudents,
        subtitleKey: 'enrolled',
        gradientColors: [const Color(0xFF006A4E), const Color(0xFF059669)],
      ),
      _StatData(
        icon: Icons.menu_book_rounded,
        titleKey: 'totalSubjects',
        value: totalSubjects,
        subtitleKey: 'configured',
        gradientColors: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      ),
      _StatData(
        icon: Icons.assignment_turned_in_rounded,
        titleKey: 'recentExam',
        value: null,
        subtitleKey: null,
        gradientColors: [const Color(0xFF6A1B9A), const Color(0xFFCE93D8)],
      ),
      _StatData(
        icon: Icons.trending_up_rounded,
        titleKey: 'passRate',
        value: null,
        subtitleKey: null,
        gradientColors: [const Color(0xFFE65100), const Color(0xFFFFCC02)],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 700;
        final crossAxisCount = isDesktop ? 4 : 2;
        final childAspectRatio = isDesktop ? 1.55 : 1.35;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) => StaggeredItem(
            index: i,
            delayMs: 80,
            child: _StatCard(data: stats[i], lang: lang),
          ),
        );
      },
    );
  }
}

class _StatData {
  final IconData icon;
  final String titleKey;
  final int? value;
  final String? subtitleKey;
  final List<Color> gradientColors;

  const _StatData({
    required this.icon,
    required this.titleKey,
    required this.value,
    required this.subtitleKey,
    required this.gradientColors,
  });
}

class _StatCard extends StatefulWidget {
  const _StatCard({required this.data, required this.lang});
  final _StatData data;
  final String lang;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.96,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _controller.drive(CurveTween(curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final lang = widget.lang;
    final tt = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => _controller.reverse(),
      onExit: (_) => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: d.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: d.gradientColors.first.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(d.icon, color: Colors.white, size: 18),
                  ),
                  if (d.subtitleKey != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          d.subtitleKey!.tr(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall
                              ?.copyWith(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  d.value != null
                      ? AnimatedStatCounter(
                          value: d.value!,
                          style: tt.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        )
                      : Text(
                          'notAvailable'.tr(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                  const SizedBox(height: 1),
                  Text(
                    d.titleKey.tr(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions — Icon-first card grid
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsSection extends ConsumerWidget {
  const _QuickActionsSection({
    required this.lang,
    this.onNavigateTab,
  });

  final String lang;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final syncState = ref.watch(syncServiceProvider);

    final actions = [
      _ActionData(
        id: 'btn_marks_entry',
        icon: Icons.edit_note_rounded,
        labelKey: 'marksEntry',
        color: const Color(0xFFE65100),
        onTap: () => onNavigateTab?.call(3),
      ),
      _ActionData(
        id: 'btn_generate_marksheet',
        icon: Icons.description_rounded,
        labelKey: 'generateMarksheet',
        color: const Color(0xFF0D7490),
        onTap: () => onNavigateTab?.call(4),
      ),
      _ActionData(
        id: 'btn_add_student',
        icon: Icons.person_add_rounded,
        labelKey: 'addStudent',
        color: const Color(0xFF1565C0),
        onTap: () => onNavigateTab?.call(1),
      ),
      _ActionData(
        id: 'btn_sync',
        icon: syncState.isLoading ? Icons.hourglass_top_rounded : Icons.cloud_sync_rounded,
        labelKey: syncState.isLoading ? (lang == 'bn' ? 'সিঙ্ক হচ্ছে...' : 'Syncing...') : 'sync',
        color: const Color(0xFF006A4E),
        isLoading: syncState.isLoading,
        onTap: syncState.isLoading
            ? () {}
            : () => ref
                .read(syncServiceProvider.notifier)
                .syncToSupabase(context),
      ),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bolt_rounded,
                      color: cs.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  lang == 'bn' ? 'দ্রুত কার্যক্রম' : 'Quick Actions',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (_, c) {
              final cols = c.maxWidth > 480 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: actions.length,
                itemBuilder: (_, i) => StaggeredItem(
                  index: i,
                  delayMs: 60,
                  child: _ActionCard(data: actions[i], lang: lang),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ActionData {
  final String id;
  final IconData icon;
  final String labelKey;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionData({
    required this.id,
    required this.icon,
    required this.labelKey,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({required this.data, required this.lang});
  final _ActionData data;
  final String lang;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: ScaleTransition(
        scale: _scale,
        child: InkWell(
          onTap: d.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _hovered
                  ? d.color.withValues(alpha: 0.1)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? d.color.withValues(alpha: 0.5)
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: d.color.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: d.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: d.isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: d.color,
                          ),
                        )
                      : Icon(d.icon, color: d.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  d.labelKey.startsWith('sync') || d.labelKey.contains('...')
                      ? d.labelKey
                      : d.labelKey.tr(widget.lang),
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _hovered ? d.color : cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Log — timeline-style
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityLogSection extends StatelessWidget {
  const _ActivityLogSection(
      {required this.lang, required this.activities});
  final String lang;
  final List<RecentActivity> activities;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.history_rounded,
                      color: cs.secondary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'recentActivity'.tr(lang),
                  style:
                      tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (activities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${activities.take(5).length}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (activities.isEmpty)
              _EmptyActivity(lang: lang)
            else
              ...activities.take(5).toList().asMap().entries.map((e) =>
                  StaggeredItem(
                    index: e.key,
                    delayMs: 70,
                    child: _ActivityTile(
                        activity: e.value, lang: lang),
                  )),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded,
                  size: 36, color: cs.onSurface.withValues(alpha: 0.25)),
            ),
            const SizedBox(height: 12),
            Text(
              'noActivity'.tr(lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.lang});
  final RecentActivity activity;
  final String lang;

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 18, color: cs.primary),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'marksSavedFor'.tr(lang)} ${activity.subjectId} (${activity.examType})',
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _relativeTime(activity.timestamp),
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activity.examType,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                      ),
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
