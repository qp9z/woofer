import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Keeps a download alive while the app isn't in front.
///
/// The download pipeline runs in the Dart isolate, so it only lives as long as
/// the process does. [show] starts a native foreground service that pins the
/// process at foreground priority (and survives the task being swiped away);
/// [hide] stops it. Every call is best-effort — a notification that failed to
/// appear must never fail a download, so nothing here throws.
///
/// Shares the `woofer/storage` channel rather than adding a second one; the
/// native side is a single MethodChannel handler.
class ForegroundService {
  static const MethodChannel _defaultChannel = MethodChannel('woofer/storage');

  final MethodChannel _channel;
  ForegroundService({MethodChannel? channel}) : _channel = channel ?? _defaultChannel;

  bool _askedForNotifications = false;

  /// Start or refresh the ongoing notification. [percent] < 0 shows an
  /// indeterminate bar (post-download processing has no reliable percentage).
  Future<void> show(String title, {int percent = -1}) async {
    // Android 13+ needs the grant to *display* it. The service runs either way,
    // so ask once and never block on the answer.
    if (!_askedForNotifications) {
      _askedForNotifications = true;
      try {
        await Permission.notification.request();
      } catch (_) {}
    }
    await _invoke('showDownloadNotification', {'title': title, 'percent': percent});
  }

  Future<void> hide() => _invoke('hideDownloadNotification', const <String, dynamic>{});

  Future<void> _invoke(String method, Map<String, dynamic> args) async {
    try {
      await _channel.invokeMethod<bool>(method, args);
    } on PlatformException {
      // ignored: see class doc
    } on MissingPluginException {
      // ignored: off-device (tests) there is no native side
    }
  }
}
