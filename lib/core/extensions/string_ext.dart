extension StringExtension on String {
  String getLanguageCode() {
    if (contains('_')) {
      return split('_').first;
    }

    return this;
  }
}
