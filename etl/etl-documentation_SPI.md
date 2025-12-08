# Dokumen ETL Architecture: Data Mart Satuan Pengawas Internal (SPI)

## 1. Tujuan Dokumen
Dokumen ini menjelaskan rancangan arsitektur ETL (Extract, Load, Transform) untuk Data Mart Satuan Pengawas Internal (SPI). Isinya mencakup aliran data dari sistem audit dan HRIS, proses transformasi risiko dan temuan, struktur staging, hingga mekanisme pemuatan ke skema dimensional (Star Schema) untuk mendukung analisis pengawasan.

## 2. Lingkup ETL
* Mengambil data audit mentah dari Sistem Internal Audit & GRC dan data kepegawaian dari HRIS.
* Menangani perubahan data historis (SCD Tipe 2) untuk Auditor dan Unit Kerja.
* Melakukan pembersihan dan perhitungan metrik audit (Skor Risiko, Usia Rekomendasi).
* Memuat data ke tabel dimensi (`Dim_Auditor`, `Dim_Temuan`) dan fakta (`Fact_Temuan_Rekomendasi`).
* Menjadwalkan pembaruan data harian.

## 3. Arsitektur Umum
* **Sumber Data:** Database Internal Audit (OLTP), HRIS, File Excel/CSV (untuk data manual).
* **Staging Area:** Schema `stg` sebagai tempat penyimpanan sementara data mentah.
* **Transformasi:** Lookup Surrogate Key, Logika SCD Tipe 2, Kalkulasi Aging, Data Masking.
* **Data Warehouse:** Schema `dbo` (Tabel Dimensi dan Tabel Fakta).
* [cite_start]**Tools:** SQL Server Integration Services (SSIS) atau T-SQL Stored Procedures (`usp_Master_ETL_Load`).

## 4. Desain Alur ETL (High-Level Flow)
Pendekatan yang digunakan adalah **ELT (Extract, Load, Transform)**:
1.  **Extract:** Tarik data mentah dari Source System ke tabel Staging (`stg.*`).
2.  **Load Dimensions:** Jalankan prosedur untuk memuat tabel dimensi, menangani *Slowly Changing Dimensions* (SCD).
3.  **Load Facts:** Transformasi data staging menjadi tabel fakta dengan melakukan lookup ke dimensi yang aktif.
4.  **Quality Check:** Jalankan prosedur validasi kualitas data (`usp_Run_DQ_Checks`).
5.  **Maintenance:** Update statistik database untuk optimasi performa.

## 5. Desain Extract
* Mengambil data transaksi audit (Temuan, Rekomendasi) dari sistem sumber.
* Mengambil data master (Auditor, Unit Kerja) dari sistem kepegawaian/organisasi.
* Menyimpan hasil ekstraksi ke tabel staging tanpa mengubah struktur data asli secara signifikan.

## 6. Desain Transform
Transformasi utama yang dilakukan dalam Stored Procedures:
* **SCD Type 2 Logic:** Mengecek perubahan jabatan/tim auditor. [cite_start]Jika berubah, non-aktifkan baris lama (`IsCurrent=0`) dan buat baris baru.
* **Surrogate Key Lookup:** Mengganti ID asli (NIP/Kode Unit) dengan `Auditor_SK` atau `Unit_Kerja_SK` yang sesuai tanggal transaksi.
* **Calculated Measures:** Menghitung `Usia_Rekomendasi_Hari` = `DATEDIFF` (Target Selesai, Tanggal Saat Ini).
* **Data Protection:** Penerapan *Data Masking* pada NIP Auditor dan Penanggung Jawab untuk user non-privileged.

## 7. Desain Load
* **Load Dimensi (`usp_Load_Dim_*`):**
    * Insert data baru (Auditor/Unit baru).
    * Expire data lama dan insert versi baru (SCD Type 2).
* **Load Fakta (`usp_Load_Fact_*`):**
    * Insert data transaksi temuan dan rekomendasi.
    * Mencegah duplikasi menggunakan pengecekan `WHERE NOT EXISTS` (Idempotency).
    * Mendukung *Partitioning* berdasarkan `Tahun_Audit`.

## 8. Arsitektur Tabel Staging
[cite_start]Berikut adalah tabel-tabel staging yang digunakan:
* `stg.Audit_Temuan_Rekom` (Data Transaksi Utama)
* `stg.Auditor_HRIS` (Data Master Auditor)
* `stg.Unit_Kerja_Master` (Data Master Unit Kerja)
* `stg.Siklus_Audit_Master` (Data Siklus Audit)
* `stg.Sistem_Sumber_Master` (Referensi Sistem Asal)

Semua tabel staging dibersihkan (*truncated*) sebelum proses load harian dimulai.

## 9. Mekanisme Penjadwalan ETL
* **Job Agent:** SQL Server Agent Job bernama `ETL_Daily_Load`.
* **Frekuensi:** Harian (Daily), Pukul 02:00 AM (WIB).
* **Tahapan Job:**
    1.  Execute Master ETL (`usp_Master_ETL_Load`).
    2.  Execute Data Quality Checks.
    3.  Maintenance (Update Statistics & Indexing). 

## 10. Monitoring & Logging
* **Audit Log:** Tabel `dbo.AuditLog` mencatat setiap operasi INSERT/UPDATE/DELETE pada tabel sensitif.
* **DQ Log:** Tabel `dbo.DQ_Audit_Log` mencatat hasil pengecekan kualitas data (Pass/Fail).
* **Troubleshooting:** Pengecekan *History Log* pada SQL Server Agent jika job gagal.

## 11. Diagram Arsitektur
`Sistem Internal Audit/HRIS` → `Staging Area (stg)` → `Stored Procedures (Transform)` → `Data Warehouse (dbo)` → `Power BI Dashboard`

## 12. Catatan Implementasi
* Gunakan transaksi (`BEGIN TRANSACTION`) dalam `usp_Master_ETL_Load` untuk menjaga konsistensi data (Rollback jika error).
* Pastikan tabel fakta dipartisi berdasarkan `Tahun_Audit` untuk mempercepat query laporan tahunan.
* Jalankan `usp_Run_DQ_Checks` setelah load selesai untuk memvalidasi skor risiko (1-5) dan integritas data.
