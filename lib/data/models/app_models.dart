class DataFinansialModel {
  final String id;
  final String mahasiswaId;
  final double pendapatanOrangTua;
  final double uktAwal;
  final int jumlahTanggungan;
  final double pengeluaranBulanan;
  final double uangSaku;
  final int literasiKeuangan;
  final int gayaHidup;
  final String createdAt;
  final String updatedAt;
  final String? mahasiswaNama;
  final String? mahasiswaNim;

  DataFinansialModel({
    required this.id,
    required this.mahasiswaId,
    required this.pendapatanOrangTua,
    required this.uktAwal,
    required this.jumlahTanggungan,
    required this.pengeluaranBulanan,
    required this.uangSaku,
    required this.literasiKeuangan,
    required this.gayaHidup,
    required this.createdAt,
    required this.updatedAt,
    this.mahasiswaNama,
    this.mahasiswaNim,
  });

  factory DataFinansialModel.fromJson(Map<String, dynamic> json) =>
      DataFinansialModel(
        id: json['id'] ?? '',
        mahasiswaId: json['mahasiswa_id'] ?? '',
        pendapatanOrangTua:
            (json['pendapatan_orang_tua'] as num?)?.toDouble() ?? 0,
        uktAwal: (json['ukt_awal'] as num?)?.toDouble() ?? 0,
        jumlahTanggungan: json['jumlah_tanggungan'] ?? 0,
        pengeluaranBulanan:
            (json['pengeluaran_bulanan'] as num?)?.toDouble() ?? 0,
        uangSaku: (json['uang_saku'] as num?)?.toDouble() ?? 0,
        literasiKeuangan: json['literasi_keuangan'] ?? 5,
        gayaHidup: json['gaya_hidup'] ?? 5,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        mahasiswaNama: json['mahasiswa_nama'],
        mahasiswaNim: json['mahasiswa_nim'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mahasiswa_id': mahasiswaId,
        'pendapatan_orang_tua': pendapatanOrangTua,
        'jumlah_tanggungan': jumlahTanggungan,
        'pengeluaran_bulanan': pengeluaranBulanan,
        'uang_saku': uangSaku,
        'literasi_keuangan': literasiKeuangan,
        'gaya_hidup': gayaHidup,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}


class BantuanModel {
  final String id;
  final String nama;
  final String deskripsi;
  final int kuota;
  final double jumlahDana;
  final String persyaratan;
  final String status;
  final String createdAt;

  BantuanModel({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.kuota,
    required this.jumlahDana,
    required this.persyaratan,
    required this.status,
    required this.createdAt,
  });

  factory BantuanModel.fromJson(Map<String, dynamic> json) => BantuanModel(
        id: json['id'] ?? '',
        nama: json['nama'] ?? '',
        deskripsi: json['deskripsi'] ?? '',
        kuota: json['kuota'] ?? 0,
        jumlahDana: (json['jumlah_dana'] as num?)?.toDouble() ?? 0,
        persyaratan: json['persyaratan'] ?? '',
        status: json['status'] ?? 'AKTIF',
        createdAt: json['created_at'] ?? '',
      );

  bool get isAktif => status == 'AKTIF';
}


class PengajuanModel {
  final String id;
  final String mahasiswaId;
  final String bantuanId;
  final String status;
  final String? catatan;
  final List<String> dokumenPaths;
  final String createdAt;
  final String updatedAt;
  final String? bantuanNama;
  final String? mahasiswaNama;
  final String? mahasiswaNim;
  final double? uktAwal;
  final double? uktAkhir;

  PengajuanModel({
    required this.id,
    required this.mahasiswaId,
    required this.bantuanId,
    required this.status,
    this.catatan,
    required this.dokumenPaths,
    required this.createdAt,
    required this.updatedAt,
    this.bantuanNama,
    this.mahasiswaNama,
    this.mahasiswaNim,
    this.uktAwal,
    this.uktAkhir,
  });

  factory PengajuanModel.fromJson(Map<String, dynamic> json) => PengajuanModel(
        id: json['id'] ?? '',
        mahasiswaId: json['mahasiswa_id'] ?? '',
        bantuanId: json['bantuan_id'] ?? '',
        status: json['status'] ?? 'MENUNGGU',
        catatan: json['catatan'],
        dokumenPaths: List<String>.from(json['dokumen_paths'] ?? []),
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        bantuanNama: json['bantuan_nama'],
        mahasiswaNama: json['mahasiswa_nama'],
        mahasiswaNim: json['mahasiswa_nim'],
        uktAwal: json['ukt_awal'] != null ? (json['ukt_awal'] as num).toDouble() : null,
        uktAkhir: json['ukt_akhir'] != null ? (json['ukt_akhir'] as num).toDouble() : null,
      );

  bool get canUpload =>
      status == 'MENUNGGU' || status == 'REVISI';

  String get statusLabel {
    switch (status) {
      case 'MENUNGGU': return 'Menunggu Verifikasi';
      case 'REVISI': return 'Perlu Revisi';
      case 'DITOLAK': return 'Ditolak';
      case 'TERVERIFIKASI': return 'Terverifikasi';
      case 'SELEKSI': return 'Dalam Seleksi';
      case 'DITERIMA': return 'Diterima ✓';
      case 'TIDAK_DITERIMA': return 'Tidak Diterima';
      default: return status;
    }
  }
}


class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        type: json['type'] ?? 'GENERAL',
        referenceId: json['reference_id'],
        isRead: json['is_read'] ?? false,
        createdAt: json['created_at'] ?? '',
      );
}


class ClusteringResultModel {
  final EvaluasiModel? kmeansEvaluasi;
  final EvaluasiModel? dbscanEvaluasi;
  final List<ClusterStats> kmeansStats;
  final List<ClusterStats> dbscanStats;
  final List<ClusterMember> members;
  final List<ClusterOutlier> outliers;

  ClusteringResultModel({
    this.kmeansEvaluasi,
    this.dbscanEvaluasi,
    required this.kmeansStats,
    required this.dbscanStats,
    required this.members,
    required this.outliers,
  });

  factory ClusteringResultModel.fromJson(Map<String, dynamic> json) =>
      ClusteringResultModel(
        kmeansEvaluasi: json['kmeans_evaluasi'] != null
            ? EvaluasiModel.fromJson(json['kmeans_evaluasi'])
            : null,
        dbscanEvaluasi: json['dbscan_evaluasi'] != null
            ? EvaluasiModel.fromJson(json['dbscan_evaluasi'])
            : null,
        kmeansStats: (json['kmeans_stats'] as List? ?? [])
            .map((e) => ClusterStats.fromJson(e))
            .toList(),
        dbscanStats: (json['dbscan_stats'] as List? ?? [])
            .map((e) => ClusterStats.fromJson(e))
            .toList(),
        members: (json['members'] as List? ?? [])
            .map((e) => ClusterMember.fromJson(e))
            .toList(),
        outliers: (json['outliers'] as List? ?? [])
            .map((e) => ClusterOutlier.fromJson(e))
            .toList(),
      );
}

class ClusterOutlier {
  final String dataFinansialId;
  final String mahasiswaId;
  final String mahasiswaNama;
  final String mahasiswaNim;

  ClusterOutlier({
    required this.dataFinansialId,
    required this.mahasiswaId,
    required this.mahasiswaNama,
    required this.mahasiswaNim,
  });

  factory ClusterOutlier.fromJson(Map<String, dynamic> json) => ClusterOutlier(
        dataFinansialId: json['data_finansial_id'] ?? '',
        mahasiswaId: json['mahasiswa_id'] ?? '',
        mahasiswaNama: json['mahasiswa_nama'] ?? '',
        mahasiswaNim: json['mahasiswa_nim'] ?? '',
      );
}

class EvaluasiModel {
  final String id;
  final String algoritma;
  final int nClusters;
  final double silhouetteScore;
  final double daviesBouldinIndex;
  final int totalData;
  final int totalOutlier;
  final String createdAt;

  EvaluasiModel({
    required this.id,
    required this.algoritma,
    required this.nClusters,
    required this.silhouetteScore,
    required this.daviesBouldinIndex,
    required this.totalData,
    required this.totalOutlier,
    required this.createdAt,
  });

  factory EvaluasiModel.fromJson(Map<String, dynamic> json) => EvaluasiModel(
        id: json['id'] ?? '',
        algoritma: json['algoritma'] ?? '',
        nClusters: json['n_clusters'] ?? 0,
        silhouetteScore: (json['silhouette_score'] as num?)?.toDouble() ?? 0,
        daviesBouldinIndex:
            (json['davies_bouldin_index'] as num?)?.toDouble() ?? 0,
        totalData: json['total_data'] ?? 0,
        totalOutlier: json['total_outlier'] ?? 0,
        createdAt: json['created_at'] ?? '',
      );
}

class ClusterStats {
  final int clusterId;
  final String kategori;
  final int total;
  final double percentage;

  ClusterStats({
    required this.clusterId,
    required this.kategori,
    required this.total,
    required this.percentage,
  });

  factory ClusterStats.fromJson(Map<String, dynamic> json) => ClusterStats(
        clusterId: json['cluster_id'] ?? 0,
        kategori: json['kategori'] ?? '',
        total: json['total'] ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      );
}

class ClusterMember {
  final String mahasiswaId;
  final String mahasiswaNama;
  final String mahasiswaNim;
  final String? pengajuanId;
  final int kmeansCluster;
  final String kmeansKategori;
  final bool isOutlier;
  final double? score;
  final double? uktAwal;
  final double? pendapatanOrangTua;
  final int? jumlahTanggungan;
  final double? pengeluaranBulanan;
  final double? uangSaku;
  final String? createdAt;

  ClusterMember({
    required this.mahasiswaId,
    required this.mahasiswaNama,
    required this.mahasiswaNim,
    this.pengajuanId,
    required this.kmeansCluster,
    required this.kmeansKategori,
    required this.isOutlier,
    this.score,
    this.uktAwal,
    this.pendapatanOrangTua,
    this.jumlahTanggungan,
    this.pengeluaranBulanan,
    this.uangSaku,
    this.createdAt,
  });

  factory ClusterMember.fromJson(Map<String, dynamic> json) => ClusterMember(
        mahasiswaId: json['mahasiswa_id'] ?? '',
        mahasiswaNama: json['mahasiswa_nama'] ?? '',
        mahasiswaNim: json['mahasiswa_nim'] ?? '',
        pengajuanId: json['pengajuan_id'],
        kmeansCluster: json['kmeans_cluster'] ?? 0,
        kmeansKategori: json['kmeans_kategori'] ?? '',
        isOutlier: json['is_outlier'] ?? false,
        score: (json['score'] as num?)?.toDouble(),
        uktAwal: (json['ukt_awal'] as num?)?.toDouble(),
        pendapatanOrangTua: (json['pendapatan_orang_tua'] as num?)?.toDouble(),
        jumlahTanggungan: json['jumlah_tanggungan'],
        pengeluaranBulanan: (json['pengeluaran_bulanan'] as num?)?.toDouble(),
        uangSaku: (json['uang_saku'] as num?)?.toDouble(),
        createdAt: json['created_at'],
      );
}
