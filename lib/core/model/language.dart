class Language {
  Language(this.name, this.nativeName);
  final String name;
  final String nativeName;

  @override
  String toString() {
    return '$name / $nativeName';
  }
}
