import 'package:fyp_source_code/localization/en_us.dart';
import 'package:fyp_source_code/localization/ur_pk.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'ur_PK': urPK,
  };
}
