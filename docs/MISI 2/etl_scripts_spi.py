import pandas as pd
import numpy as np
import random
from datetime import datetime

# ============================================
# KONSTANTA DAN PARAMETER
# ============================================
MAX_FACT_ROWS = 10000
MIN_DIM_ROWS = 510 # TARGET: Minimal 510 baris untuk semua dimensi
np.random.seed(18) # Set seed untuk replikasi hasil

# TANGGAL UNTUK DIMENSI WAKTU (2020-2025)
dates = pd.date_range(start="2020-01-01", end="2025-12-31")

# ============================================
# 1. Dimensi Waktu (Alami > 510 baris)
# ============================================
dimWaktu = pd.DataFrame({
    "Waktu_SK": range(1, len(dates) + 1),
    "Tanggal_Penuh": dates.date,
    "Bulan": dates.strftime("%B"),
    "Tahun": dates.year,
    "Periode_Fiskal": dates.year.astype(str)
})
# Catatan: Dimensi Waktu memiliki 2192 baris, memenuhi > 510.

# ============================================
# 2. Dimensi Sistem Sumber (510 baris)
# ============================================
dimSistemSumber = pd.DataFrame({
    "ID_Sistem_Sumber": range(1, MIN_DIM_ROWS + 1),
    "Kode_Sumber": [f'KODE-{i:04d}' for i in range(1, MIN_DIM_ROWS + 1)],
    "Nama_Sistem": [f'Sistem Sumber {i}' for i in range(1, MIN_DIM_ROWS + 1)],
    "Deskripsi": [f"Deskripsi sistem {i}" for i in range(1, MIN_DIM_ROWS + 1)],
    "Penanggung_Jawab": [f'PJ-{i:03d}' for i in range(1, MIN_DIM_ROWS + 1)],
    "Tanggal_Mulai_Berlaku": datetime(2019, 1, 1).date()
})

# ============================================
# 3. Dimensi Unit Kerja (510 baris)
# ============================================
unit_types = ["Produksi", "Pendukung", "Akademik"] # Sesuai ERD/Domain
kepala_units = [f"Kepala-{i}" for i in range(1, 101)]

dimUnitKerja = pd.DataFrame({
    "Unit_Kerja_SK": range(1, MIN_DIM_ROWS + 1),
    "Kode_Unit": [f"UK-{i:03d}" for i in range(1, MIN_DIM_ROWS + 1)],
    "Nama_Unit": [f"Unit Kerja {i}" for i in range(1, MIN_DIM_ROWS + 1)],
    "Jenis_Unit": np.random.choice(unit_types, MIN_DIM_ROWS),
    "Kepala_Unit": np.random.choice(kepala_units, MIN_DIM_ROWS),
    "Tanggal_Berlaku_Unit_Kerja": datetime(2020, 1, 1).date()
})

# ============================================
# 4. Dimensi Siklus Audit (510 baris)
# ============================================
audit_years = [2020, 2021, 2022, 2023, 2024, 2025]
audit_types = ["Operasional", "Finansial", "Khusus"]
statuses = ["Selesai", "Ditunda", "Dalam Proses"]

dimSiklusAudit = pd.DataFrame({
    "Siklus_Audit_SK": range(1, MIN_DIM_ROWS + 1),
    "ID_Sistem_Sumber": [f'S-AUDIT-{i:04d}' for i in range(1, MIN_DIM_ROWS + 1)],
    "Jenis_Audit": np.random.choice(audit_types, MIN_DIM_ROWS),
    "Tahun_Siklus": np.random.choice(audit_years, MIN_DIM_ROWS),
    "Status_Siklus": np.random.choice(statuses, MIN_DIM_ROWS)
})

# ============================================
# 5. Dimensi Auditor (510 baris, SCD SPI Fields)
# ============================================
spi_roles = ["Ketua", "Sekretaris", "Anggota"]
spi_status = ["Dosen", "Tenaga Kependidikan"]
bidang_keahlian = ["Akuntansi/Keuangan", "Manajemen SDM", "Manajemen Aset", "Hukum", "Ketatalaksanaan"]
teams = ["Tim A", "Tim B", "Tim C", "Tim D"]

dimAuditor = pd.DataFrame({
    "Auditor_SK": range(1, MIN_DIM_ROWS + 1),
    "ID_Sistem_Sumber": [f'NIP-{i:05d}' for i in range(1, MIN_DIM_ROWS + 1)],
    "Nama_Auditor": [f"Auditor {i}" for i in range(1, MIN_DIM_ROWS + 1)],
    "Bidang_Keahlian": np.random.choice(bidang_keahlian, MIN_DIM_ROWS),
    "Jabatan": np.random.choice(spi_roles, MIN_DIM_ROWS),
    "Status_Keanggotaan": np.random.choice(spi_status, MIN_DIM_ROWS),
    "Tim_Audit": np.random.choice(teams, MIN_DIM_ROWS),
    "Tanggal_Berlaku_Auditor": datetime(2020, 1, 1).date()
})

# ============================================
# 6. Dimensi Temuan (510 baris)
# ============================================
risks = ["Kepatuhan", "Operasional", "Finansial"]
materiality = ["Tinggi", "Sedang", "Rendah"]

dimTemuan = pd.DataFrame({
    "Temuan_SK": range(1, MIN_DIM_ROWS + 1),
    "ID_Sistem_Sumber": [f'TEMUAN-{i:05d}' for i in range(1, MIN_DIM_ROWS + 1)],
    "Kategori_Risiko": np.random.choice(risks, MIN_DIM_ROWS),
    "Tingkat_Materialitas": np.random.choice(materiality, MIN_DIM_ROWS),
    "Deskripsi_Temuan": [f"Uraian singkat temuan {i}" for i in range(1, MIN_DIM_ROWS + 1)],
    "Kelemahan_Kontrol": np.random.choice(["Segregasi Tugas", "Dokumentasi", "Akses Sistem"], MIN_DIM_ROWS)
})

# ============================================
# 7. Dimensi Rekomendasi (510 baris)
# ============================================
statuses_rekom = ["Open", "Closed", "Overdue", "Partially Closed"]
pj_list = [f"PJ-{i}" for i in range(1, 101)]

dimRekomendasi = pd.DataFrame({
    "Rekomendasi_SK": range(1, MIN_DIM_ROWS + 1),
    "ID_Sistem_Sumber": [f'REKOM-{i:05d}' for i in range(1, MIN_DIM_ROWS + 1)],
    "Status_Tindak_Lanjut": np.random.choice(statuses_rekom, MIN_DIM_ROWS),
    "Tanggal_Target_Selesai": np.random.choice(dates.date[dates.date > datetime(2023, 1, 1).date()], MIN_DIM_ROWS),
    "Penanggung_Jawab": np.random.choice(pj_list, MIN_DIM_ROWS),
})


# ============================================
# 8. Fakta Temuan Rekomendasi (10.000 baris)
# ============================================
factTemuanRekomendasi = pd.DataFrame({
    "Fakta_SK": range(1, MAX_FACT_ROWS + 1),
    "Waktu_SK": np.random.randint(1, len(dimWaktu) + 1, MAX_FACT_ROWS),
    "Unit_Kerja_SK": np.random.randint(1, len(dimUnitKerja) + 1, MAX_FACT_ROWS),
    "Auditor_SK": np.random.randint(1, len(dimAuditor) + 1, MAX_FACT_ROWS),
    "Siklus_Audit_SK": np.random.randint(1, len(dimSiklusAudit) + 1, MAX_FACT_ROWS),
    "Temuan_SK": np.random.randint(1, len(dimTemuan) + 1, MAX_FACT_ROWS),
    "Rekomendasi_SK": np.random.randint(1, len(dimRekomendasi) + 1, MAX_FACT_ROWS),
    "Jumlah_Temuan": 1,
    "Skor_Risiko_Temuan": np.random.uniform(1.0, 5.0, MAX_FACT_ROWS).round(2),
    "Potensi_Kerugian_IDR": np.random.randint(10_000_000, 5_000_000_000, MAX_FACT_ROWS),
    "Usia_Rekomendasi_Hari": np.random.randint(1, 366, MAX_FACT_ROWS)
})


# ============================================
# 9. EXPORT KE EXCEL
# ============================================

output = "data-dictionary-SPI.xlsx"

with pd.ExcelWriter(output, engine="openpyxl") as writer:
    dimWaktu.to_excel(writer, sheet_name="Dimensi_Waktu", index=False)
    dimSistemSumber.to_excel(writer, sheet_name="Dimensi_Sistem_Sumber", index=False)
    dimUnitKerja.to_excel(writer, sheet_name="Dimensi_Unit_Kerja", index=False)
    dimSiklusAudit.to_excel(writer, sheet_name="Dimensi_Siklus_Audit", index=False)
    dimAuditor.to_excel(writer, sheet_name="Dimensi_Auditor", index=False)
    dimTemuan.to_excel(writer, sheet_name="Dimensi_Temuan", index=False)
    dimRekomendasi.to_excel(writer, sheet_name="Dimensi_Rekomendasi", index=False)
    factTemuanRekomendasi.to_excel(writer, sheet_name="Fakta_Temuan_Rekomendasi", index=False)

print(f"File '{output}' berisi mock data Data Mart SPI telah berhasil dibuat.")
print(f"Semua dimensi kini memiliki minimal {MIN_DIM_ROWS} baris data unik.")
