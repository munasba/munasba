class AppSettingsModel {
  final String themeMode; // 'light' | 'dark'
  final String language; // 'ar' | 'en' | 'ku'
  final int accentColorValue;
  final String? pinHash;
  final bool lockEnabled;
  final bool biometricEnabled;
  final bool onboardingSeen;

  const AppSettingsModel({
    this.themeMode = 'dark',
    this.language = 'ar',
    this.accentColorValue = 0xFF6C5CE7,
    this.pinHash,
    this.lockEnabled = false,
    this.biometricEnabled = false,
    this.onboardingSeen = false,
  });

  AppSettingsModel copyWith({
    String? themeMode,
    String? language,
    int? accentColorValue,
    String? pinHash,
    bool? lockEnabled,
    bool? biometricEnabled,
    bool? onboardingSeen,
  }) =>
      AppSettingsModel(
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        accentColorValue: accentColorValue ?? this.accentColorValue,
        pinHash: pinHash ?? this.pinHash,
        lockEnabled: lockEnabled ?? this.lockEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      );

  Map<String, Object?> toMap() => {
        'id': 'app',
        'themeMode': themeMode,
        'language': language,
        'accentColorValue': accentColorValue,
        'pinHash': pinHash,
        'lockEnabled': lockEnabled ? 1 : 0,
        'biometricEnabled': biometricEnabled ? 1 : 0,
        'onboardingSeen': onboardingSeen ? 1 : 0,
      };

  factory AppSettingsModel.fromMap(Map<String, Object?> map) => AppSettingsModel(
        themeMode: map['themeMode'] as String? ?? 'dark',
        language: map['language'] as String? ?? 'ar',
        accentColorValue: (map['accentColorValue'] as int?) ?? 0xFF6C5CE7,
        pinHash: map['pinHash'] as String?,
        lockEnabled: (map['lockEnabled'] as int?) == 1,
        biometricEnabled: (map['biometricEnabled'] as int?) == 1,
        onboardingSeen: (map['onboardingSeen'] as int?) == 1,
      );
}
