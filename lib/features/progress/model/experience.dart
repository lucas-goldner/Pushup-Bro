enum ExperienceSource {
  single,
  friend,
}

class Experience {
  Experience({
    required this.date,
    required this.value,
    required this.group,
  });

  final DateTime date;
  final int value;
  final ExperienceSource group;
}
