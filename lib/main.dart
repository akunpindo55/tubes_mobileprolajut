import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'features/notification/presentation/providers/notification_service.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.babyBlue,
          primary: AppColors.babyBlue,
          surface: AppColors.cardSurface,
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          titleTextStyle: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: AppColors.textDark),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: AppColors.babyBlue.withValues(alpha: 0.3),
          labelStyle: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
