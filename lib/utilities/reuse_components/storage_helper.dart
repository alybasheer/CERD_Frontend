import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageHelper {
  GetStorage storage = GetStorage();

  static const _preservedSessionKeys = {
    'hasSeenOnboarding',
    'rememberEmail',
    'theme',
    'dark_mode',
  };

  void saveData(String key, dynamic value) {
    storage.write(key, value);
    // Add your storage helper methods here
  }

  dynamic readData(String key) {
    return storage.read(key);
  }

  void removeData(String key) {
    storage.remove(key);
  }

  void clearAllData() {
    storage.erase();
  }

  void clearSessionData() {
    // Drop the real-time socket so the server unregisters this user as
    // "online" the moment they log out (prevents stale delivery + re-login
    // identity mixups).
    if (Get.isRegistered<ChatProvider>()) {
      Get.find<ChatProvider>().disconnectSocket();
    }

    final keys = List<String>.from(
      storage.getKeys<Iterable>().map((key) => key.toString()),
    );

    for (final key in keys) {
      if (_preservedSessionKeys.contains(key)) {
        continue;
      }
      storage.remove(key);
    }

    storage.write('hasSeenOnboarding', true);
  }

  void writeData(String key, dynamic value) {
    storage.write(key, value);
  }
}
