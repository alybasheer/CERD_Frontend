import 'dart:ui';

import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get/get.dart';

class LocaleController extends GetxController {
  static const _storageKey = 'app_locale';
  final StorageHelper _storage = StorageHelper();
  final Rx<Locale> _current = const Locale('en', 'US').obs;

  Locale get locale => _current.value;
  bool get isUrdu => _current.value.languageCode == 'ur';

  @override
  void onInit() {
    super.onInit();
    final raw = _storage.readData(_storageKey)?.toString().trim();
    if (raw == 'ur_PK') {
      _set(const Locale('ur', 'PK'));
      return;
    }
    _set(const Locale('en', 'US'));
  }

  void toggleLanguage() {
    if (isUrdu) {
      _set(const Locale('en', 'US'));
      return;
    }
    _set(const Locale('ur', 'PK'));
  }

  void _set(Locale locale) {
    _current.value = locale;
    _storage.saveData(_storageKey, '${locale.languageCode}_${locale.countryCode}');
    Get.updateLocale(locale);
  }
}
