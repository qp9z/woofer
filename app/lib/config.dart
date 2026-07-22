/// App-wide configuration.
class AppConfig {
  /// Base URL of the woofer backend.
  ///
  /// TODO: set this to your backend.
  /// - Android emulator reaches your dev machine at `10.0.2.2`, NOT `localhost`.
  /// - A physical device needs your machine's LAN IP (e.g. http://192.168.1.20:8000).
  /// - Production: your deployed https URL.
  static const String baseUrl = 'http://10.0.2.2:8000'; // TODO: change me
}
