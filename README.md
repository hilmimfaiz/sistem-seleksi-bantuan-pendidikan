# 🎓 Sistem Seleksi Bantuan Pendidikan
### Aplikasi Mobile Pengelompokan Kemampuan Finansial Mahasiswa

> Capstone Project — Hilmi Muhammad Faiz (2311081019)

---

## 📋 Deskripsi

Sistem seleksi bantuan pendidikan berbasis aplikasi mobile yang menggunakan algoritma **K-Means** dan **DBSCAN** untuk mengelompokkan kemampuan finansial mahasiswa secara otomatis dan objektif. Sistem ini dirancang untuk membantu administrator kampus dalam menentukan penerima bantuan pendidikan berdasarkan data finansial mahasiswa, menggantikan proses seleksi manual yang rentan terhadap subjektivitas.

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────┐        REST API        ┌──────────────────┐
│  Flutter (Mobile)│ ◄──────────────────► │  FastAPI (Backend)│
│   Android / iOS  │      JWT Auth          │   Python 3.11+   │
└─────────────────┘                        └────────┬─────────┘
                                                    │
                                           ┌────────▼─────────┐
                                           │   SQLite Database │
                                           │   (SQLModel ORM)  │
                                           └──────────────────┘
```

---

## ⚙️ Tech Stack

| Layer | Teknologi |
|---|---|
| **Mobile Frontend** | Flutter 3.x (Dart) + Riverpod State Management |
| **Backend API** | FastAPI (Python) + Uvicorn |
| **Database** | SQLite 3 + SQLModel ORM |
| **Authentication** | JWT (jose) + bcrypt |
| **Machine Learning** | Scikit-learn (K-Means, DBSCAN, StandardScaler, PCA) |
| **HTTP Client** | Dio |
| **Storage** | Flutter Secure Storage |

---

## 🤖 Algoritma Machine Learning

### K-Means Clustering
- **Jumlah Klaster:** k = 3
- **Fitur Input:** `pendapatan_orang_tua`, `jumlah_tanggungan`, `pengeluaran_bulanan`, `uang_saku`, `literasi_keuangan`, `gaya_hidup`
- **Preprocessing:** StandardScaler (normalisasi Z-score)
- **Visualisasi:** PCA 2D Scatter Plot
- **Hasil:** Silhouette Score **0.3879** | Davies-Bouldin Index **0.9579**

| Klaster | Kategori | Jumlah | Persentase |
|---|---|---|---|
| 0 | Sangat Membutuhkan | 39 mhs | 39% |
| 1 | Membutuhkan | 44 mhs | 44% |
| 2 | Cukup Mampu | 17 mhs | 17% |

### DBSCAN (Outlier Detection)
- **Parameter:** eps = 0.5, min_samples = 3 (dengan auto-tuning)
- **Fungsi:** Mendeteksi mahasiswa dengan profil finansial yang sangat menyimpang
- **Hasil:** 94 data normal (94%) | **6 outlier** terdeteksi (6%)

---

## 🗂️ Struktur Proyek

```
aplikasi_finansialpendidikan/
├── lib/                          # Flutter source code
│   ├── main.dart
│   ├── core/                     # Constants, themes, routing
│   ├── features/
│   │   ├── auth/                 # Login & Register
│   │   ├── mahasiswa/            # Profil & Data Mahasiswa
│   │   ├── data_finansial/       # Input Data Finansial
│   │   ├── pengajuan/            # Pengajuan Bantuan
│   │   ├── clustering/           # Hasil Clustering ML
│   │   ├── admin/                # Dashboard Admin
│   │   └── notifikasi/           # Sistem Notifikasi
│   └── widgets/
├── backend/                      # FastAPI backend
│   ├── app/
│   │   ├── api/                  # Router endpoints
│   │   ├── ml/                   # K-Means & DBSCAN models
│   │   ├── models/               # SQLModel database models
│   │   └── services/             # Business logic layer
│   ├── seed_100_mahasiswa.py     # Seeder 100 data dummy (deterministik)
│   ├── delete_dummy.py           # Hapus data dummy
│   ├── run.py                    # Entry point server
│   └── requirements.txt
├── dataset_dummy_100.csv         # Dataset untuk analisis/training
└── pubspec.yaml
```

---

## 🚀 Cara Menjalankan

### 1. Backend (FastAPI)

```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Jalankan server
python run.py
# Server berjalan di: http://localhost:8000
# Dokumentasi API: http://localhost:8000/docs
```

### 2. Seed Data Dummy (Opsional)

```bash
# Tambahkan 100 data mahasiswa dummy (deterministik)
python seed_100_mahasiswa.py

# Hapus semua data dummy
python delete_dummy.py
```

### 3. Flutter App

```bash
# Install dependencies
flutter pub get

# Jalankan di emulator / device
flutter run
```

> **Catatan:** Pastikan backend sudah berjalan sebelum menjalankan aplikasi Flutter. Sesuaikan base URL API di `lib/core/constants/api_constants.dart`.

---

## 🔑 Akun Default

| Role | Email | Password |
|---|---|---|
| Admin | `admin@finansial.com` | `admin123` |
| Mahasiswa | *(daftar via aplikasi)* | — |

---

## 📊 Hasil Pengujian

- **Black Box Testing:** 25 skenario — **100% Berhasil** ✅
- **Silhouette Score (K-Means):** 0.3879
- **Davies-Bouldin Index (K-Means):** 0.9579
- **Outlier Terdeteksi (DBSCAN):** 6 dari 100 data (6%)

---

## 📱 Fitur Utama

**Mahasiswa:**
- Registrasi & Login
- Pengisian data profil dan data finansial
- Pengajuan bantuan pendidikan
- Pemantauan status pengajuan real-time
- Notifikasi perubahan status

**Admin:**
- Dashboard statistik sistem
- Verifikasi pengajuan mahasiswa
- Eksekusi proses clustering ML
- Visualisasi hasil K-Means dan DBSCAN
- Penetapan hasil seleksi kelayakan

---

## 👤 Developer

**Hilmi Muhammad Faiz**
NIM: 2311081019 | Program Studi D4 Teknologi Rekayasa Perangkat Lunak

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan akademik (Capstone Project).
