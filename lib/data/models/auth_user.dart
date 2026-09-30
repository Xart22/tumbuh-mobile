class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'kasir', 'kds', 'owner', 'supervisor'
  final String? outletId;
  final String? shiftTitle;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.outletId,
    this.shiftTitle,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'kasir',
      outletId: json['outletId'] as String?,
      shiftTitle: json['shiftTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'outletId': outletId,
        'shiftTitle': shiftTitle,
      };
}
