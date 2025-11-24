-- 1.)  Data Quality Checks
USE DM_SPI_DW;
GO

-- CHECK 1: Completeness (Kelengkapan Data)
-- Memastikan Auditor yang aktif memiliki NIP, Nama, dan Jabatan
SELECT
    'Dimensi_Auditor' AS TableName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN ID_Sistem_Sumber IS NULL THEN 1 ELSE 0 END) AS NullNIP,
    SUM(CASE WHEN Nama_Auditor IS NULL THEN 1 ELSE 0 END) AS NullName,
    SUM(CASE WHEN Jabatan IS NULL THEN 1 ELSE 0 END) AS NullJabatan
FROM dbo.Dimensi_Auditor
WHERE IsCurrent = 1;
GO

-- CHECK 2: Consistency (Referential Integrity)
-- Memastikan tidak ada data di Tabel Fakta yang Auditor-nya tidak dikenal
SELECT
    'Fakta_Temuan_Rekomendasi' AS TableName,
    COUNT(*) AS OrphanRecords -- Harusnya 0
FROM dbo.Fakta_Temuan_Rekomendasi f
LEFT JOIN dbo.Dimensi_Auditor a ON f.Auditor_SK = a.Auditor_SK
WHERE a.Auditor_SK IS NULL;
GO

-- CHECK 3: Accuracy (Valid Ranges)
-- Memastikan Skor Risiko masuk akal (Misal: 1.00 s.d 5.00)
-- Dan Potensi Kerugian tidak boleh minus
SELECT
    COUNT(*) AS InvalidRiskScores,
    SUM(CASE WHEN Potensi_Kerugian_IDR < 0 THEN 1 ELSE 0 END) AS NegativeLossValues
FROM dbo.Fakta_Temuan_Rekomendasi
WHERE Skor_Risiko_Temuan < 1.00 OR Skor_Risiko_Temuan > 5.00;
GO

-- CHECK 4: Duplicates
-- Memastikan tidak ada Temuan & Rekomendasi yang sama masuk 2 kali
SELECT
    Temuan_SK,
    Rekomendasi_SK,
    COUNT(*) AS DuplicateCount
FROM dbo.Fakta_Temuan_Rekomendasi
GROUP BY Temuan_SK, Rekomendasi_SK
HAVING COUNT(*) > 1;
GO

-- CHECK 5: Reconciliation (Jumlah Data)
-- Membandingkan jumlah data di Staging (Awal) vs Fakta (Akhir)
SELECT
    'Source (Staging)' AS DataSource,
    COUNT(*) AS RecordCount
FROM stg.Fakta_Import -- Pastikan nama tabel staging sesuai Step 4
UNION ALL
SELECT
    'Warehouse (Fact)' AS DataSource,
    COUNT(*) AS RecordCount
FROM dbo.Fakta_Temuan_Rekomendasi;
GO


-- 2.) Create Data Quality Dashboard
USE DM_SPI_DW;
GO

-- 1. Tabel Log untuk menyimpan hasil pengecekan kualitas data
IF OBJECT_ID('dbo.DQ_Audit_Log', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DQ_Audit_Log (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        CheckName VARCHAR(100),
        CheckDescription VARCHAR(255),
        ExecutionDate DATETIME DEFAULT GETDATE(),
        Status VARCHAR(20), -- 'PASS' / 'FAIL'
        ValueFound INT,
        Threshold INT,
        Message VARCHAR(MAX)
    );
END
GO

-- 2. Stored Procedure Otomatis (DQ Engine)
CREATE OR ALTER PROCEDURE dbo.usp_Run_DQ_Checks
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FailCount INT = 0;
    DECLARE @Count INT;

    -- TEST A: Cek Skor Risiko (Accuracy)
    SELECT @Count = COUNT(*) FROM dbo.Fakta_Temuan_Rekomendasi
    WHERE Skor_Risiko_Temuan < 1.00 OR Skor_Risiko_Temuan > 5.00;

    INSERT INTO dbo.DQ_Audit_Log (CheckName, CheckDescription, Status, ValueFound, Threshold, Message)
    VALUES (
        'Accuracy - Risk Score',
        'Memastikan Skor Risiko ada di rentang 1 - 5',
        CASE WHEN @Count = 0 THEN 'PASS' ELSE 'FAIL' END,
        @Count,
        0, -- Threshold (Batas toleransi kesalahan) adalah 0
        CASE WHEN @Count > 0 THEN 'Ditemukan skor risiko tidak valid!' ELSE 'OK' END
    );

    -- TEST B: Cek Data Yatim/Orphan (Consistency)
    SELECT @Count = COUNT(*) FROM dbo.Fakta_Temuan_Rekomendasi f
    LEFT JOIN dbo.Dimensi_Auditor a ON f.Auditor_SK = a.Auditor_SK
    WHERE a.Auditor_SK IS NULL;

    INSERT INTO dbo.DQ_Audit_Log (CheckName, CheckDescription, Status, ValueFound, Threshold, Message)
    VALUES (
        'Consistency - Orphan Auditor',
        'Cek baris Fakta tanpa Dimensi Auditor yang valid',
        CASE WHEN @Count = 0 THEN 'PASS' ELSE 'FAIL' END,
        @Count,
        0,
        CASE WHEN @Count > 0 THEN 'Ditemukan data fakta yatim (Orphan)!' ELSE 'OK' END
    );

    -- TEST C: Cek Duplikasi (Uniqueness)
    SELECT @Count = COUNT(*) FROM (
        SELECT Temuan_SK, Rekomendasi_SK
        FROM dbo.Fakta_Temuan_Rekomendasi
        GROUP BY Temuan_SK, Rekomendasi_SK
        HAVING COUNT(*) > 1
    ) AS Duplicates;

    INSERT INTO dbo.DQ_Audit_Log (CheckName, CheckDescription, Status, ValueFound, Threshold, Message)
    VALUES (
        'Uniqueness - Duplicate Facts',
        'Cek apakah ada data ganda pada Temuan & Rekomendasi',
        CASE WHEN @Count = 0 THEN 'PASS' ELSE 'FAIL' END,
        @Count,
        0,
        CASE WHEN @Count > 0 THEN 'Ditemukan data duplikat!' ELSE 'OK' END
    );


    -- Alerting (Contoh Sederhana)
    SELECT @FailCount = COUNT(*) FROM dbo.DQ_Audit_Log
    WHERE ExecutionDate > CAST(GETDATE() AS DATE) AND Status = 'FAIL';

    IF @FailCount > 0
    BEGIN
        PRINT 'WARNING: Ditemukan Isu Kualitas Data! Cek tabel dbo.DQ_Audit_Log.';
    END
    ELSE
    BEGIN
        PRINT 'Data Quality Checks Selesai. Semua data AMAN (Pass).';
    END
    
    -- Tampilkan hasil ke layar
    SELECT * FROM dbo.DQ_Audit_Log WHERE ExecutionDate > DATEADD(MINUTE, -1, GETDATE());
END
GO
