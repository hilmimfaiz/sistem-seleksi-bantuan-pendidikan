class MahasiswaModel {
  final String id;
  final String userId;
  final String nim;
  final String nama;
  final String programStudi;
  final String fakultas;
  final int angkatan;
  final String jenisKelamin;
  final String alamat;
  final String nomorHp;
  final String? fotoProfil;
  final double? uktAwal;
  final double? uktAkhir;
  final String createdAt;
  final String updatedAt;

  MahasiswaModel({
    required this.id,
    required this.userId,
    required this.nim,
    required this.nama,
    required this.programStudi,
    required this.fakultas,
    required this.angkatan,
    required this.jenisKelamin,
    required this.alamat,
    required this.nomorHp,
    this.fotoProfil,
    this.uktAwal,
    this.uktAkhir,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MahasiswaModel.fromJson(Map<String, dynamic> json) => MahasiswaModel(
        id: json['id'] ?? '',
        userId: json['user_id'] ?? '',
        nim: json['nim'] ?? '',
        nama: json['nama'] ?? '',
        programStudi: json['program_studi'] ?? '',
        fakultas: json['fakultas'] ?? '',
        angkatan: json['angkatan'] ?? 2021,
        jenisKelamin: json['jenis_kelamin'] ?? '',
        alamat: json['alamat'] ?? '',
        nomorHp: json['nomor_hp'] ?? '',
        fotoProfil: json['foto_profil'],
        uktAwal: json['ukt_awal'] != null ? (json['ukt_awal'] as num).toDouble() : null,
        uktAkhir: json['ukt_akhir'] != null ? (json['ukt_akhir'] as num).toDouble() : null,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'nim': nim,
        'nama': nama,
        'program_studi': programStudi,
        'fakultas': fakultas,
        'angkatan': angkatan,
        'jenis_kelamin': jenisKelamin,
        'alamat': alamat,
        'nomor_hp': nomorHp,
        'foto_profil': fotoProfil,
        'ukt_awal': uktAwal,
        'ukt_akhir': uktAkhir,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class MahasiswaRegisterRequest {
  final String email;
  final String password;
  final String nim;
  final String nama;
  final String programStudi;
  final String fakultas;
  final int angkatan;
  final String jenisKelamin;
  final String alamat;
  final String nomorHp;
  final double? uktAwal;

  MahasiswaRegisterRequest({
    required this.email,
    required this.password,
    required this.nim,
    required this.nama,
    required this.programStudi,
    required this.fakultas,
    required this.angkatan,
    required this.jenisKelamin,
    required this.alamat,
    required this.nomorHp,
    this.uktAwal,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'nim': nim,
        'nama': nama,
        'program_studi': programStudi,
        'fakultas': fakultas,
        'angkatan': angkatan,
        'jenis_kelamin': jenisKelamin,
        'alamat': alamat,
        'nomor_hp': nomorHp,
        'ukt_awal': uktAwal,
      };
}
