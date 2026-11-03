/// Raw user RGB choices. Presentation derives accessible light/dark tones.
class CustomPalette {
  const CustomPalette({
    required this.id,
    required this.name,
    required this.primaryRgb,
    required this.secondaryRgb,
    required this.tertiaryRgb,
  });
  final String id, name;
  final int primaryRgb, secondaryRgb, tertiaryRgb;
  bool get isValid =>
      RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id) &&
      name.trim().isNotEmpty &&
      name.length <= 40 &&
      [
        primaryRgb,
        secondaryRgb,
        tertiaryRgb,
      ].every((c) => c >= 0 && c <= 0xFFFFFF);
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'primaryRgb': primaryRgb,
    'secondaryRgb': secondaryRgb,
    'tertiaryRgb': tertiaryRgb,
  };
  static CustomPalette? parse(Object? value) {
    if (value is! Map ||
        value['id'] is! String ||
        value['name'] is! String ||
        value['primaryRgb'] is! int ||
        value['secondaryRgb'] is! int ||
        value['tertiaryRgb'] is! int) {
      return null;
    }
    final palette = CustomPalette(
      id: value['id'] as String,
      name: value['name'] as String,
      primaryRgb: value['primaryRgb'] as int,
      secondaryRgb: value['secondaryRgb'] as int,
      tertiaryRgb: value['tertiaryRgb'] as int,
    );
    return palette.isValid ? palette : null;
  }
}
