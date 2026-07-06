import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fyp_source_code/firebase_options.dart';
import 'package:fyp_source_code/localization/app_translations.dart';
import 'package:fyp_source_code/localization/language_capsule.dart';
import 'package:fyp_source_code/localization/locale_controller.dart';
import 'package:fyp_source_code/routing/route_paths.dart';
import 'package:fyp_source_code/routing/route_names.dart';
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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  const Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: LanguageCapsule(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
