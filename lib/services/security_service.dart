import 'package:screen_protector/screen_protector.dart';

/// Service to handle security-related window flags, such as blocking screenshots.
/// Using the modern screen_protector package for cross-platform support.
class SecurityService {
  /// Enables or disables screenshot protection (Android and iOS).
  /// 
  /// When [enable] is true, screenshots and screen recordings will be blocked.
  /// When [enable] is false, the protection is removed.
  static Future<void> setSecureMode(bool enable) async {
    try {
      if (enable) {
        // In Android it activates FLAG_SECURE
        // In iOS it activates detection and mask for recording/capture
        await ScreenProtector.preventScreenshotOn();
        // Sometimes called twice for extra reliability on some OS versions
        await ScreenProtector.preventScreenshotOn();
      } else {
        await ScreenProtector.preventScreenshotOff();
      }
    } catch (e) {
      // Log error but don't crash the app if security flag fails.
      print('SecurityService error: $e');
    }
  }
}
