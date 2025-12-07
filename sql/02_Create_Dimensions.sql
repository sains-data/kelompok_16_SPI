-- 1. Dimensi Waktu (SCD Tipe 0 / Static) - Disesuaikan dengan Dim_Date standar
CREATE TABLE dbo.Dimensi_Waktu (
    Waktu_SK INT PRIMARY KEY NOT NULL, -- PK (YYYYMMDD)
    Tanggal_Penuh DATE NOT NULL,
    Bulan VARCHAR (10) NOT NULL,
    Tahun SMALLINT NOT NULL,
    Periode_Fiskal VARCHAR(10),
   
    -- Metadata
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Index pada Tahun (untuk memfilter laporan tahunan)
CREATE NONCLUSTERED INDEX IX_DimWaktu_Tahun ON dbo.Dim_Waktu (Tahun);
GO


-- 2. Dimensi Sistem Sumber (SCD Tipe 0 / Static)
CREATE TABLE dbo.Dimensi_Sistem_Sumber (
    ID_Sistem_Sumber INT PRIMARY KEY NOT NULL, -- PK
    Kode_Sumber VARCHAR(50) NOT NULL,
    Nama_Sistem VARCHAR(100),
    Deskripsi VARCHAR(255),
    Penanggung_Jawab VARCHAR(100),
    Tanggal_Mulai_Berlaku DATE,
   
    -- Metadata
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Indexing Natural Key
CREATE UNIQUE NONCLUSTERED INDEX IX_DimSistemSumber_NK ON dbo.Dim_Sistem_Sumber (Kode_Sumber);
GO


-- 3. Dimensi Unit Kerja (SCD Tipe 2) - Objek Audit
-- Pemicu SCD: Jenis_Unit, Kepala_Unit
CREATE TABLE dbo.Dimensi_Unit_Kerja (
    Unit_Kerja_SK INT IDENTITY(1,1) PRIMARY KEY NOT NULL, -- Surrogate Key
    Kode_Unit VARCHAR(50) UNIQUE NOT NULL, -- Natural Key (Source Key)
    Nama_Unit VARCHAR(100) NOT NULL,
    Jenis_Unit VARCHAR(50),
    Kepala_Unit VARCHAR(100),
    Tanggal_Berlaku_Unit_Kerja DATE,
   
    -- Kolom SCD Type 2
    EffectiveDate DATE DEFAULT GETDATE() NOT NULL,
    ExpiryDate DATE NULL,
    IsCurrent BIT DEFAULT 1 NOT NULL,
   
    -- Metadata
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Indexing untuk ETL Lookup dan SCD Tipe 2
CREATE NONCLUSTERED INDEX IX_DimUnitKerja_NK ON dbo.Dimensi_Unit_Kerja (Kode_Unit);
CREATE NONCLUSTERED INDEX IX_DimUnitKerja_Current ON dbo.Dimensi_Unit_Kerja (IsCurrent) WHERE IsCurrent = 1;
GO

  
-- 4. Dimensi Siklus Audit (SCD Tipe 1)
CREATE TABLE dbo.Dimensi_Siklus_Audit (
    Siklus_Audit_SK INT IDENTITY(1,1) PRIMARY KEY NOT NULL, -- Surrogate Key
    ID_Sistem_Sumber VARCHAR(50) UNIQUE NOT NULL, -- Source Key
    Jenis_Audit VARCHAR(50),
    Tahun_Siklus INT,
    Status_Siklus VARCHAR(50),
   
    -- Metadata
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Indexing untuk ETL Lookup (Natural Key)
CREATE UNIQUE NONCLUSTERED INDEX IX_DimSiklusAudit_NK ON dbo.Dimensi_Siklus_Audit (ID_Sistem_Sumber);
GO

  
-- 5. Dimensi Auditor (SCD Tipe 2 - Disesuaikan dengan kebutuhan SPI)
-- Pemicu SCD: Jabatan, Tim_Audit
CREATE TABLE dbo.Dimensi_Auditor (
    Auditor_SK INT IDENTITY(1,1) PRIMARY KEY NOT NULL, -- Surrogate Key
    ID_Sistem_Sumber VARCHAR(50) UNIQUE NOT NULL, -- Natural Key (NIP/ID Asli)
    Nama_Auditor VARCHAR(100) NOT NULL,
    Bidang_Keahlian VARCHAR(50), -- Tipe 1
    Jabatan VARCHAR(50), -- SCD Tipe 2
    Status_Keanggotaan VARCHAR(50), -- Tipe 1
    Tim_Audit VARCHAR(50), -- SCD Tipe 2
   
    -- Kolom SCD Type 2
    Tanggal_Berlaku_Auditor DATE DEFAULT GETDATE() NOT NULL,
    IsCurrent BIT DEFAULT 1 NOT NULL,
   
    -- Metadata
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Indexing untuk ETL Lookup dan SCD Tipe 2
CREATE NONCLUSTERED INDEX IX_DimAuditor_NK ON dbo.Dimensi_Auditor (ID_Sistem_Sumber);
CREATE NONCLUSTERED INDEX IX_DimAuditor_Current ON dbo.Dimensi_Auditor (IsCurrent) WHERE IsCurrent = 1;
GO

  
-- 6. Dimensi Temuan (SCD Tipe 2)
-- Pemicu SCD: Tingkat_Materialitas
CREATE TABLE dbo.Dimensi_Temuan (
    Temuan_SK INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    ID_Sistem_Sumber VARCHAR(50) UNIQUE NOT NULL, -- Source Key
    Kategori_Risiko VARCHAR(50),
    Tingkat_Materialitas VARCHAR(50), -- SCD Tipe 2
    Deskripsi_Temuan VARCHAR(MAX),
    Kelemahan_Kontrol VARCHAR(100),
   
    -- Kolom SCD Type 2
    EffectiveDate DATE DEFAULT GETDATE() NOT NULL,
    ExpiryDate DATE NULL,
    IsCurrent BIT DEFAULT 1 NOT NULL,
   
    -- Metadata
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Indexing untuk ETL Lookup dan SCD Tipe 2
CREATE NONCLUSTERED INDEX IX_DimTemuan_NK ON dbo.Dimensi_Temuan (ID_Sistem_Sumber);
CREATE NONCLUSTERED INDEX IX_DimTemuan_Current ON dbo.Dimensi_Temuan (IsCurrent) WHERE IsCurrent = 1;
GO

  
-- 7. Dimensi Rekomendasi (SCD Tipe 2)
-- Pemicu SCD: Penanggung_Jawab
CREATE TABLE dbo.Dimensi_Rekomendasi (
    Rekomendasi_SK INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    ID_Sistem_Sumber VARCHAR(50) UNIQUE NOT NULL, -- Source Key
    Status_Tindak_Lanjut VARCHAR(50), -- Tipe 1
    Tanggal_Target_Selesai DATE, -- Tipe 1
    Penanggung_Jawab VARCHAR(100), -- SCD Tipe 2
   
    -- Kolom SCD Type 2
    EffectiveDate DATE DEFAULT GETDATE() NOT NULL,
    ExpiryDate DATE NULL,
    IsCurrent BIT DEFAULT 1 NOT NULL,
   
    -- Metadata
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Indexing untuk ETL Lookup dan SCD Tipe 2
CREATE NONCLUSTERED INDEX IX_DimRekomendasi_NK ON dbo.Dimensi_Rekomendasi (ID_Sistem_Sumber);
CREATE NONCLUSTERED INDEX IX_DimRekomendasi_Current ON dbo.Dimensi_Rekomendasi (IsCurrent) WHERE IsCurrent = 1;
GO
