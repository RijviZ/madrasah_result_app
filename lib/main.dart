import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/app_settings_model.dart';
import 'models/mark_model.dart';
import 'models/student_model.dart';
import 'models/subject_model.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_layout.dart';
import 'utils/initial_data_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Dotenv & Initialize Supabase (Cloud Backup & Sync)
  try {
    try {
      await dotenv.load(fileName: "assets/.env");
    } catch (_) {
      try {
        await dotenv.load(fileName: ".env");
      } catch (_) {}
    }

    String url = dotenv.env['SUPABASE_URL'] ?? '';
    String key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    // Hardcoded production fallback for web deployment
    if (url.isEmpty || key.isEmpty) {
      url = 'https://tmaxzqsqgdhdxgyeftco.supabase.co';
      key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRtYXh6cXNxZ2RoZHhneWVmdGNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2OTU1MzksImV4cCI6MjEwMDI3MTUzOX0.p9-snoyHqeTMFgDZ1k4XRcdLKj7a_iTfBJpIwYE2JEM';
    }

    if (url.isNotEmpty && key.isNotEmpty) {
      // ignore: deprecated_member_use
      await Supabase.initialize(url: url, anonKey: key);
    }
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive TypeAdapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(StudentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(SubjectModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MarkModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AppSettingsModelAdapter());
  }

  // Open required Hive boxes
  await Hive.openBox<StudentModel>('students');
  await Hive.openBox<SubjectModel>('subjects');
  await Hive.openBox<MarkModel>('marks');
  await Hive.openBox<AppSettingsModel>('settings');

  // Seed initial data if empty
  await InitialDataSeeder.seedInitialData();

  runApp(
    const ProviderScope(
      child: MadrasahResultApp(),
    ),
  );
}

class MadrasahResultApp extends ConsumerWidget {
  const MadrasahResultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'হাজী আলতাফ হোসেন হরিন্দীয়া আলিম মাদ্রাসা',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('bn', 'BD'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainLayout(),
    );
  }
}
