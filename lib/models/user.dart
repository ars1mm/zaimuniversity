class User {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String role;
  final String department;
  final String profileImageUrl;
  final int enrollmentYear;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.role,
    required this.department,
    this.profileImageUrl = '',
    required this.enrollmentYear,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      studentId: json['student_id'],
      role: json['role'],
      department: json['department'],
      profileImageUrl: json['profile_image_url'] ?? '',
      enrollmentYear: json['enrollment_year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'student_id': studentId,
      'role': role,
      'department': department,
      'profile_image_url': profileImageUrl,
      'enrollment_year': enrollmentYear,
    };
  }
}
