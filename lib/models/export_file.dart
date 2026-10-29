class ExportFile {
  ExportFile({
    required this.name,
    required this.mimeType,
    required List<int> bytes,
  }) : bytes = List.unmodifiable(bytes);
  final String name, mimeType;
  final List<int> bytes;
}

enum FileShareOutcome { shared, cancelled, unknown }
