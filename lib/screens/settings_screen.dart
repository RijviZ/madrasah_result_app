// Stage 9 — Settings Screen (Premium UI Refresh)
// Glassmorphism header, richer grouped setting tiles, animated sync status.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_translations.dart';
import '../providers/locale_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/theme_provider.dart';
import '../services/sync_service.dart';
import '../widgets/screen_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final syncState = ref.watch(syncServiceProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final studentCount = ref.watch(totalStudentsProvider);
    final subjectCount = ref.watch(totalSubjectsProvider);
    final markCount = ref.watch(markRepositoryProvider).length;
    final isSynced = syncStatus == SyncStatus.synced;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Glassmorphism Settings Header ─────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary,
                  cs.primary.withValues(alpha: 0.8),
                  cs.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings_rounded,
                          size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'settings'.tr(lang),
                            style: tt.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lang == 'bn'
                                ? 'থিম, ভাষা, ক্লাউড সিঙ্ক ও ব্যাকআপ ব্যবস্থাপনা'
                                : 'Manage theme, language, cloud sync & backups',
                            style: tt.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Animated sync status indicator
                    Tooltip(
                      message: isSynced
                          ? 'syncedStatus'.tr(lang)
                          : 'pendingSync'.tr(lang),
                      child: PulsingDot(
                        color: isSynced
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF97316),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Mini stats row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _MiniStat(
                  icon: Icons.people_alt_rounded,
                  value: studentCount.toString(),
                  label: lang == 'bn' ? 'শিক্ষার্থী' : 'Students',
                  color: const Color(0xFF1565C0),
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  icon: Icons.menu_book_rounded,
                  value: subjectCount.toString(),
                  label: lang == 'bn' ? 'বিষয়' : 'Subjects',
                  color: const Color(0xFF6A1B9A),
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  icon: Icons.edit_rounded,
                  value: markCount.toString(),
                  label: lang == 'bn' ? 'নম্বর' : 'Marks',
                  color: const Color(0xFFE65100),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── General Settings ─────────────────────────────────────
                    _SectionHeader(
                      title: lang == 'bn' ? 'সাধারণ সেটিংস' : 'General Settings',
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: 10),

                    _SettingsCard(
                      children: [
                        // Theme Switcher
                        _SettingsTile(
                          icon: isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          iconColor: isDark
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFFF59E0B),
                          title: isDark ? 'darkMode'.tr(lang) : 'lightMode'.tr(lang),
                          subtitle: lang == 'bn'
                              ? 'অ্যাপের উজ্জ্বলতা পরিবর্তন করুন'
                              : 'Toggle application theme mode',
                          trailing: Switch(
                            value: isDark,
                            onChanged: (_) =>
                                ref.read(themeProvider.notifier).toggleTheme(),
                            activeThumbColor: cs.primary,
                          ),
                        ),

                        const Divider(height: 1, indent: 56),

                        // Language Switcher
                        _SettingsTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF0D7490),
                          title: 'language'.tr(lang),
                          subtitle: lang == 'bn'
                              ? 'বর্তমান ভাষা: বাংলা'
                              : 'Current language: English',
                          trailing: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'bn', label: Text('বাংলা')),
                              ButtonSegment(value: 'en', label: Text('English')),
                            ],
                            selected: {lang},
                            onSelectionChanged: (set) {
                              if (set.isNotEmpty && set.first != lang) {
                                ref.read(localeProvider.notifier).toggleLocale();
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Cloud Sync ────────────────────────────────────────────
                    _SectionHeader(
                      title: lang == 'bn'
                          ? 'ক্লাউড সিঙ্ক (Supabase)'
                          : 'Cloud Sync (Supabase)',
                      icon: Icons.cloud_rounded,
                    ),
                    const SizedBox(height: 10),

                    _SettingsCard(
                      children: [
                        // Sync status
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSynced
                                      ? const Color(0xFF059669).withValues(alpha: 0.12)
                                      : const Color(0xFFD97706).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSynced
                                      ? Icons.cloud_done_rounded
                                      : Icons.cloud_off_rounded,
                                  color: isSynced
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSynced
                                          ? 'syncedStatus'.tr(lang)
                                          : 'pendingSync'.tr(lang),
                                      style: tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      syncState.result?.timestamp != null
                                          ? '${lang == "bn" ? "সর্বশেষ সিঙ্ক: " : "Last synced: "}${DateFormat("dd MMM yyyy, hh:mm a").format(syncState.result!.timestamp)}'
                                          : (lang == 'bn'
                                              ? 'এখনও কোনো সিঙ্ক করা হয়নি'
                                              : 'No sync recorded yet'),
                                      style: tt.bodySmall?.copyWith(
                                          color: cs.onSurface.withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (syncState.result != null) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: syncState.result!.success
                                    ? const Color(0xFF059669).withValues(alpha: 0.08)
                                    : const Color(0xFFD97706).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: syncState.result!.success
                                      ? const Color(0xFF059669).withValues(alpha: 0.3)
                                      : const Color(0xFFD97706).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    syncState.result!.success
                                        ? Icons.info_outline_rounded
                                        : Icons.warning_amber_rounded,
                                    size: 16,
                                    color: syncState.result!.success
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      syncState.result!.message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: syncState.result!.success
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFD97706),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: syncState.isLoading
                                    ? null
                                    : () {
                                        ref
                                            .read(syncServiceProvider.notifier)
                                            .backupToSupabase(ref, context);
                                      },
                                icon: syncState.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(Icons.cloud_upload_rounded,
                                        size: 18),
                                label: Text(syncState.isLoading
                                    ? (lang == 'bn' ? 'সিঙ্ক হচ্ছে...' : 'Syncing...')
                                    : (lang == 'bn' ? 'ক্লাউড ব্যাকআপ' : 'Cloud Backup')),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: syncState.isLoading
                                    ? null
                                    : () =>
                                        _confirmRestoreDialog(context, ref, lang),
                                icon: syncState.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.cloud_download_rounded,
                                        size: 18),
                                label: Text(lang == 'bn'
                                    ? 'পুনরুদ্ধার'
                                    : 'Restore Cloud'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Database Backup ───────────────────────────────────────
                    _SectionHeader(
                      title: lang == 'bn'
                          ? 'ডাটাবেস ব্যাকআপ ও রপ্তানি'
                          : 'Database Backup & Export',
                      icon: Icons.storage_rounded,
                    ),
                    const SizedBox(height: 10),

                    _SettingsCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.storage_rounded,
                          iconColor: const Color(0xFF475569),
                          title: lang == 'bn'
                              ? 'ডাটাবেস বিবরণ'
                              : 'Database Storage Status',
                          subtitle: lang == 'bn'
                              ? '$studentCount জন শিক্ষার্থী · $subjectCount টি বিষয় · $markCount টি নম্বর'
                              : '$studentCount students · $subjectCount subjects · $markCount marks',
                          trailing: null,
                        ),
                        const Divider(height: 1, indent: 56),
                        _SettingsTile(
                          icon: Icons.file_download_rounded,
                          iconColor: const Color(0xFF059669),
                          title: lang == 'bn'
                              ? 'JSON ব্যাকআপ ডাউনলোড'
                              : 'Export JSON Backup',
                          subtitle: lang == 'bn'
                              ? 'সকল ডাটা ব্যাকআপ ফাইল হিসেবে দেখুন বা কপি করুন'
                              : 'Export all local records as formatted JSON',
                          trailing: FilledButton.tonalIcon(
                            onPressed: () =>
                                _showBackupDialog(context, ref, lang),
                            icon: const Icon(Icons.code_rounded, size: 18),
                            label: Text(
                                lang == 'bn' ? 'ব্যাকআপ দেখুন' : 'View Backup'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, WidgetRef ref, String lang) {
    final jsonStr =
        ref.read(syncServiceProvider.notifier).exportBackupJson(ref);
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            lang == 'bn' ? 'JSON ডাটাবেস ব্যাকআপ' : 'JSON Database Backup'),
        content: SizedBox(
          width: 550,
          height: 350,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                jsonStr,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'bn' ? 'বন্ধ করুন' : 'Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lang == 'bn'
                      ? 'JSON ব্যাকআপ ক্লিপবোর্ডে কপি করা হয়েছে'
                      : 'JSON Backup copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(lang == 'bn' ? 'কপি করুন' : 'Copy JSON'),
          ),
        ],
      ),
    );
  }

  void _confirmRestoreDialog(
      BuildContext context, WidgetRef ref, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang == 'bn'
            ? 'ক্লাউড ব্যাকআপ পুনরুদ্ধার'
            : 'Restore Cloud Backup'),
        content: Text(
          lang == 'bn'
              ? 'আপনি কি সুপাবেস ক্লাউড থেকে সর্বশেষ ব্যাকআপটি লোকাল ডিভাইসে রিস্টোর করতে চান?'
              : 'Do you want to restore the latest backup from Supabase Cloud to your local device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'bn' ? 'বাতিল' : 'Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(syncServiceProvider.notifier)
                  .restoreFromSupabase(ref, context);
            },
            icon: const Icon(Icons.cloud_download_rounded, size: 18),
            label:
                Text(lang == 'bn' ? 'হ্যাঁ, রিস্টোর করুন' : 'Yes, Restore'),
          ),
        ],
      ),
    );
  }
}

// ── Mini stat badge ───────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: tt.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings card wrapper ─────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(children: children),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6))),
      trailing: trailing,
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon!, size: 16, color: cs.primary),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            thickness: 1,
            color: cs.primary.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
