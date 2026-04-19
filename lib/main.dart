import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(AppConstants.settingsBox),
    Hive.openBox(AppConstants.personalBox),
    Hive.openBox(AppConstants.ingredientesBox),
    Hive.openBox(AppConstants.suministrosBox),
    Hive.openBox(AppConstants.transporteBox),
    Hive.openBox(AppConstants.ingresosBox),
    Hive.openBox(AppConstants.comensalesBox),
    Hive.openBox(AppConstants.directorioBox),
    Hive.openBox(AppConstants.asistenciasBox),
    Hive.openBox(AppConstants.usuariosBox),
    Hive.openBox(AppConstants.ventasBox),
  ]);

  await initializeDateFormatting('es', null);

  runApp(const ProviderScope(child: SantaYesseniaApp()));
}

class SantaYesseniaApp extends ConsumerWidget {
  const SantaYesseniaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'PE'),
    );
  }
}
