class Pushup {
  Pushup({this.completedAt});

  factory Pushup.fromJson(Map<String, dynamic> json) => Pushup(
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );

  final DateTime? completedAt;

  Map<String, dynamic> toJson() => {
        'completedAt': completedAt?.toIso8601String(),
      };
}
