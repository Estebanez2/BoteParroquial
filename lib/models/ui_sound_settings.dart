class UiSoundSettings {
  const UiSoundSettings({this.enabled = true, this.volumePercent = 75});
  final bool enabled;
  final int volumePercent;
  UiSoundSettings copyWith({bool? enabled, int? volumePercent}) =>
      UiSoundSettings(
        enabled: enabled ?? this.enabled,
        volumePercent: volumePercent ?? this.volumePercent,
      );
  Map<String, Object> toJson() => {
    'version': 1,
    'enabled': enabled,
    'volumePercent': volumePercent,
  };
  factory UiSoundSettings.fromJson(Map<String, dynamic> json) {
    final volume = json['volumePercent'];
    if (json['version'] != 1 ||
        json['enabled'] is! bool ||
        volume is! int ||
        volume < 0 ||
        volume > 100) {
      throw const FormatException('Invalid sound preferences');
    }
    return UiSoundSettings(
      enabled: json['enabled'] as bool,
      volumePercent: volume,
    );
  }
}
