USE DM_SPI_DW;
GO

-- 1. Create Staging Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg')
BEGIN
    EXEC('CREATE SCHEMA stg')
END
GO

-- 2. Staging Table for Transaction Data (Temuan & Rekomendasi)
-- Sumber: Sistem Internal Audit
CREATE TABLE stg.Audit_Temuan_Rekom (
    -- Source IDs
    ID_Temuan_Sumber VARCHAR(50) ,
    ID_Rekom_Sumber VARCHAR(50) ,
    ID_Siklus_Sumber VARCHAR(50) ,
    ID_Unit_Sumber VARCHAR(50) ,
    ID_Auditor_Sumber VARCHAR(50) ,
   
    -- Transaction Attributes
    Tanggal_Temuan DATE ,
    Skor_Risiko DECIMAL(5,2) ,
    Kerugian_IDR BIGINT ,
    Status_Rekomendasi VARCHAR(50) ,
    Tanggal_Target_Selesai DATE ,

    -- Dimension Attributes (Snowflaked in Source)
    Kategori_Risiko_Temuan VARCHAR(50) ,
    Tingkat_Materialitas VARCHAR(50) ,
    Deskripsi_Temuan_Lengkap VARCHAR(MAX) ,
    Kelemahan_Kontrol VARCHAR(100) ,
   
    -- Metadata
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- 3. Staging Table for Auditor Master Data
-- Sumber: HRIS (Human Resource Information System)
CREATE TABLE stg.Auditor_HRIS (
    ID_Auditor_Sumber VARCHAR(50) ,
    Nama_Lengkap VARCHAR(100) ,
    Bidang_Keahlian_HR VARCHAR(50) ,
    Jabatan_SPI VARCHAR(50) ,       -- Atribut SCD Type 2
    Status_Keanggotaan VARCHAR(50) ,
    Tim_Audit_Saat_Ini VARCHAR(50) ,-- Atribut SCD Type 2
    Update_Effective_Date DATE ,    -- Pemicu SCD
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- 4. Staging Table for Unit Kerja Master Data
-- Sumber: Sistem Organisasi/Kepegawaian
CREATE TABLE stg.Unit_Kerja_Master (
    ID_Unit_Sumber VARCHAR(50) ,
    Nama_Unit VARCHAR(100) ,
    Jenis_Unit VARCHAR(50) ,
    Kepala_Unit VARCHAR(100) ,
    Update_Effective_Date DATE ,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- 5. Staging Table for Siklus Audit Master Data
-- Sumber: Sistem Internal Audit (Modul Perencanaan)
CREATE TABLE stg.Siklus_Audit_Master (
    ID_Siklus_Sumber VARCHAR(50) ,
    Jenis_Audit VARCHAR(50) ,
    Tahun_Siklus INT ,
    Status_Siklus VARCHAR(50) ,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO
