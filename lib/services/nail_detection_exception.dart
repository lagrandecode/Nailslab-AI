class NailDetectionException implements Exception {
  NailDetectionException(this.message);
  final String message;

  @override
  String toString() => message;
}
