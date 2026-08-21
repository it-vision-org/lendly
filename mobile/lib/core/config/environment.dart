abstract final class Environment {
  /// Defaults to the hosted Render backend, so a plain `flutter build apk`
  /// (no dart-defines) talks to the real API. For local development against
  /// a backend running on your machine, override with e.g.
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:8080/api` (Android emulator)
  /// or `http://localhost:8080/api` (iOS simulator).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://lendly-1w5a.onrender.com/api',
  );
}
