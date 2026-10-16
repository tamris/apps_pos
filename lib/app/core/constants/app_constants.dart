class AppConstants {
  static const String appName = 'Noli POS';
  static const String appVersion = '1.1.2';
  static const String appBuild = '7';
  static const String appReleaseType = 'Stabil';

  static String get fullVersion => 'v$appVersion+$appBuild';
  static String get versionTag => 'v$appVersion ($appReleaseType)';
  static String get displayVersion => '$appName v$appVersion ($appReleaseType)';
}
