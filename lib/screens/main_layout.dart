// Stage 5 & 8 & 9 — Main Layout (Premium UI Refresh)
// Responsive adaptive shell:
//   Desktop (>800px) : Permanent NavigationRail / collapsible sidebar
//   Mobile  (<=800px) : Modern BottomNavigationBar
//
// App header includes:
//   - Institution title (bilingual)
//   - Theme toggle (Sun / Moon)
//   - Language toggle (বাংলা / English)
//   - Sync status indicator dot

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_translations.dart';
import '../providers/locale_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/theme_provider.dart';
import '../widgets/screen_header.dart';
import 'dashboard_screen.dart';
import 'marks_entry_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'student_management_screen.dart';
import 'subject_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route index constants
// ─────────────────────────────────────────────────────────────────────────────

const int _kDashboard = 0;
const int _kStudents = 1;
const int _kSubjects = 2;
const int _kMarksEntry = 3;
const int _kResults = 4;
const int _kSettings = 5;

// ─────────────────────────────────────────────────────────────────────────────
// Navigation destination model
// ─────────────────────────────────────────────────────────────────────────────

class _NavDest {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  final Color accentColor;

  const _NavDest({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    required this.accentColor,
  });
}

const List<_NavDest> _destinations = [
  _NavDest(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    labelKey: 'dashboard',
    accentColor: Color(0xFF006A4E),
  ),
  _NavDest(
    icon: Icons.people_alt_outlined,
    activeIcon: Icons.people_alt_rounded,
    labelKey: 'students',
    accentColor: Color(0xFF1565C0),
  ),
  _NavDest(
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
    labelKey: 'subjects',
    accentColor: Color(0xFF6A1B9A),
  ),
  _NavDest(
    icon: Icons.edit_note_outlined,
    activeIcon: Icons.edit_note_rounded,
    labelKey: 'marksEntry',
    accentColor: Color(0xFFE65100),
  ),
  _NavDest(
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment_rounded,
    labelKey: 'results',
    accentColor: Color(0xFF0D7490),
  ),
  _NavDest(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    labelKey: 'settings',
    accentColor: Color(0xFF475569),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main Layout Entry
// ─────────────────────────────────────────────────────────────────────────────

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = _kDashboard;
  bool _railExtended = true;

  List<Widget> _buildScreens() {
    return [
      DashboardScreen(
        onNavigateTab: (index) => setState(() => _selectedIndex = index),
      ),
      const StudentManagementScreen(),
      const SubjectManagementScreen(),
      const MarksEntryScreen(),
      const ResultsScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final syncStatus = ref.watch(syncStatusProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;
    final screens = _buildScreens();

    return Scaffold(
      appBar: _AppHeader(
        lang: lang,
        isDark: isDark,
        syncStatus: syncStatus,
        isDesktop: isDesktop,
        railExtended: _railExtended,
        onToggleRail: () => setState(() => _railExtended = !_railExtended),
        onToggleTheme: () =>
            ref.read(themeProvider.notifier).toggleTheme(),
        onToggleLocale: () =>
            ref.read(localeProvider.notifier).toggleLocale(),
      ),
      body: isDesktop
          ? _DesktopBody(
              selectedIndex: _selectedIndex,
              extended: _railExtended,
              lang: lang,
              screens: screens,
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
            )
          : _AnimatedScreenSwitcher(
              selectedIndex: _selectedIndex,
              screens: screens,
            ),
      bottomNavigationBar: isDesktop
          ? null
          : _MobileNav(
              selectedIndex: _selectedIndex,
              lang: lang,
              onTap: (i) => setState(() => _selectedIndex = i),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated screen switcher for mobile
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedScreenSwitcher extends StatefulWidget {
  const _AnimatedScreenSwitcher({
    required this.selectedIndex,
    required this.screens,
  });

  final int selectedIndex;
  final List<Widget> screens;

  @override
  State<_AnimatedScreenSwitcher> createState() =>
      _AnimatedScreenSwitcherState();
}

class _AnimatedScreenSwitcherState extends State<_AnimatedScreenSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..value = 1.0;
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_AnimatedScreenSwitcher old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: widget.screens[widget.selectedIndex],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Header (PreferredSizeWidget)
// ─────────────────────────────────────────────────────────────────────────────

class _AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const _AppHeader({
    required this.lang,
    required this.isDark,
    required this.syncStatus,
    required this.isDesktop,
    required this.railExtended,
    required this.onToggleRail,
    required this.onToggleTheme,
    required this.onToggleLocale,
  });

  final String lang;
  final bool isDark;
  final SyncStatus syncStatus;
  final bool isDesktop;
  final bool railExtended;
  final VoidCallback onToggleRail;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLocale;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isSynced = syncStatus == SyncStatus.synced;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: cs.primaryContainer.withValues(alpha: 0.95),
      surfaceTintColor: cs.primary,
      // Hamburger on desktop to collapse rail
      leading: isDesktop
          ? IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    RotationTransition(turns: anim, child: child),
                child: Icon(
                  railExtended
                      ? Icons.menu_open_rounded
                      : Icons.menu_rounded,
                  key: ValueKey(railExtended),
                ),
              ),
              onPressed: onToggleRail,
              tooltip: railExtended ? 'Collapse sidebar' : 'Expand sidebar',
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lang == 'bn'
                ? 'institutionTitleBn'.tr(lang)
                : 'institutionTitle'.tr(lang),
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (lang == 'en')
            Text(
              'institutionTitleBn'.tr('bn'),
              style: tt.labelSmall?.copyWith(
                color: cs.onPrimaryContainer.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        // ── Sync status indicator ──────────────────────────────────────────
        Tooltip(
          message: isSynced
              ? 'syncedStatus'.tr(lang)
              : 'pendingSync'.tr(lang),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            child: PulsingDot(
              color: isSynced
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF97316),
              size: 11,
            ),
          ),
        ),

        // ── Theme toggle ──────────────────────────────────────────────────
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                RotationTransition(turns: anim, child: child),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              color: cs.onPrimaryContainer,
            ),
          ),
          tooltip: isDark
              ? 'lightMode'.tr(lang)
              : 'darkMode'.tr(lang),
          onPressed: onToggleTheme,
        ),

        // ── Language toggle ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: cs.onPrimaryContainer,
                backgroundColor: cs.onPrimaryContainer.withValues(alpha: 0.08),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.3)),
                ),
              ),
              onPressed: onToggleLocale,
              child: Text(
                lang == 'bn' ? 'English' : 'বাংলা',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Body — NavigationRail + content
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopBody extends StatefulWidget {
  const _DesktopBody({
    required this.selectedIndex,
    required this.extended,
    required this.lang,
    required this.screens,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final bool extended;
  final String lang;
  final List<Widget> screens;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<_DesktopBody> createState() => _DesktopBodyState();
}

class _DesktopBodyState extends State<_DesktopBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..value = 1.0;
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_DesktopBody old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Sidebar / Rail
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          width: widget.extended ? 220 : 80,
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              right: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: NavigationRail(
            extended: widget.extended,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            backgroundColor: cs.surface,
            indicatorColor: cs.primaryContainer,
            selectedIconTheme: IconThemeData(color: cs.primary, size: 22),
            unselectedIconTheme: IconThemeData(
              color: cs.onSurface.withValues(alpha: 0.5),
              size: 22,
            ),
            labelType: widget.extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            leading: widget.extended
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Navigation',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                  )
                : null,
            destinations: _destinations.map((d) {
              return NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: Text(
                  d.labelKey.tr(widget.lang),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                padding: const EdgeInsets.symmetric(vertical: 3),
              );
            }).toList(),
          ),
        ),
        // Main content — animated fade on switch
        Expanded(
          child: FadeTransition(
            opacity: _fade,
            child: widget.screens[widget.selectedIndex],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _MobileNav extends StatelessWidget {
  const _MobileNav({
    required this.selectedIndex,
    required this.lang,
    required this.onTap,
  });

  final int selectedIndex;
  final String lang;
  final ValueChanged<int> onTap;

  // Primary destinations for mobile bottom bar
  static const List<int> _mobileIndices = [
    _kDashboard,
    _kStudents,
    _kSubjects,
    _kMarksEntry,
    _kResults,
    _kSettings,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final mobileSelected = _mobileIndices.contains(selectedIndex)
        ? _mobileIndices.indexOf(selectedIndex)
        : 0;

    return NavigationBar(
      selectedIndex: mobileSelected,
      onDestinationSelected: (i) => onTap(_mobileIndices[i]),
      backgroundColor: cs.surface,
      indicatorColor: cs.primaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      animationDuration: const Duration(milliseconds: 300),
      destinations: _mobileIndices.map((idx) {
        final d = _destinations[idx];
        return NavigationDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.activeIcon, color: cs.primary),
          label: d.labelKey.tr(lang),
        );
      }).toList(),
    );
  }
}
