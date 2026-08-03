import 'package:flutter/foundation.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class HelplineService {
  static Future<void> call(String number) async {
    if (kIsWeb) {
      ToastHelper.showError('Calling is not available on web.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: number);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      ToastHelper.showError('Could not open dial pad for $number.');
    }
  }
}
