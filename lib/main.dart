import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fyp_source_code/firebase_options.dart';
import 'package:fyp_source_code/localization/app_translations.dart';
import 'package:fyp_source_code/localization/locale_controller.dart';
import 'package:fyp_source_code/routing/route_paths.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/app_update_service.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_theme.dart';
import 'package:fyp_source_code/volunteer_side/profile/presentation/controller/profile_controller.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();
  final profileCtrl = Get.put(ProfileController());
  Get.put(LocaleController());
  await Future.wait([profileCtrl.themeLoad()]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _lastPromptedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleUpdateCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleUpdateCheck();
    }
  }

  /// Re-checks for an update shortly after launch and every time the app is
  /// resumed, so logged-in users get the prompt even if the app never cold
  /// started again.
  void _scheduleUpdateCheck() {
    Future.delayed(const Duration(seconds: 4), _checkForUpdate);
  }

  Future<void> _checkForUpdate() async {
    // Don't hammer repeatedly on quick resume transitions (optional prompts
    // only). Required updates always show again.
    final now = DateTime.now();
    final isThrottled =
        _lastPromptedAt != null &&
        now.difference(_lastPromptedAt!) < const Duration(minutes: 30);

    final update = await AppUpdateService().checkForUpdate();
    if (update == null || !mounted) return;
    if (update.required || !isThrottled) {
      await AppUpdateService().promptUpdate(update, required: update.required);
      _lastPromptedAt = now;
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    final localeCtrl = Get.find<LocaleController>();

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      splitScreenMode: true,
      minTextAdapt: true,
      builder: (context, child) {
        return Obx(
          () => GetMaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                profileCtrl.isSwitching.value
                    ? ThemeMode.dark
                    : ThemeMode.light,
            translations: AppTranslations(),
            locale: localeCtrl.locale,
            fallbackLocale: const Locale('en', 'US'),
            supportedLocales: const [Locale('en', 'US'), Locale('ur', 'PK')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            debugShowCheckedModeBanner: false,
            initialRoute: RouteNames.splash,
            getPages: RoutePaths.routePath,
            builder: (context, child) {
              return child ?? const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}
