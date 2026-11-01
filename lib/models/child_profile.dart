class ChildProfile {
  final String id;
  final String name;
  final String grade;
  final String? avatarUrl;
  final String? gender;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.grade,
    this.avatarUrl,
    this.gender,
  });

  ChildProfile copyWith({
    String? id,
    String? name,
    String? grade,
    String? avatarUrl,
    String? gender,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
    );
  }
}
