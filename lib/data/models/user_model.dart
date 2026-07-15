class UserModel {
  final String id;
  final String email;
  final String role;
  final bool isActive;
  final String createdAt;
  final String? fotoProfil;
  final String nama;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.fotoProfil,
    required this.nama,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'MAHASISWA',
        isActive: json['is_active'] ?? true,
        createdAt: json['created_at'] ?? '',
        fotoProfil: json['foto_profil'],
        nama: json['nama'] ?? 'Administrator',
      );

  bool get isAdmin => role == 'ADMIN';
  bool get isMahasiswa => role == 'MAHASISWA';

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'is_active': isActive,
        'created_at': createdAt,
        'foto_profil': fotoProfil,
        'nama': nama,
      };

  @override
  String toString() => 'UserModel(id: $id, email: $email, role: $role)';
}

class AuthModel {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final String role;

  AuthModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.role,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) => AuthModel(
        accessToken: json['access_token'] ?? '',
        refreshToken: json['refresh_token'] ?? '',
        userId: json['user_id'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'MAHASISWA',
      );

  bool get isAdmin => role == 'ADMIN';
}
