-- Procedure untuk Load Dimensi Auditor (SCD Type 2)
CREATE OR ALTER PROCEDURE dbo.usp_Load_Dimensi_Auditor
AS
BEGIN
    SET NOCOUNT ON;

    -- A. UPDATE (Expire) Record Lama jika ada perubahan data
    UPDATE d
    SET 
        ExpiryDate = GETDATE(),
        IsCurrent = 0,
        ModifiedDate = GETDATE()
    FROM dbo.Dimensi_Auditor d
    INNER JOIN stg.Auditor_Import s ON d.ID_Sistem_Sumber = s.ID_Sistem_Sumber
    WHERE d.IsCurrent = 1
    AND (
        d.Jabatan <> s.Jabatan OR
        d.Tim_Audit <> s.Tim_Audit OR
        d.Status_Keanggotaan <> s.Status_Keanggotaan
    );

    -- B. INSERT Record Baru (Auditor Baru atau Perubahan Jabatan)
    INSERT INTO dbo.Dimensi_Auditor (
        ID_Sistem_Sumber, Nama_Auditor, Bidang_Keahlian, 
        Jabatan, Status_Keanggotaan, Tim_Audit, 
        EffectiveDate, IsCurrent, CreatedDate, ModifiedDate
    )
    SELECT 
        s.ID_Sistem_Sumber,
        s.Nama_Auditor,
        s.Bidang_Keahlian,
        s.Jabatan,
        s.Status_Keanggotaan,
        s.Tim_Audit,
        GETDATE(), -- Effective Date baru
        1,         -- IsCurrent Aktif
        GETDATE(),
        GETDATE()
    FROM stg.Auditor_Import s
    LEFT JOIN dbo.Dimensi_Auditor d 
        ON s.ID_Sistem_Sumber = d.ID_Sistem_Sumber AND d.IsCurrent = 1
    WHERE d.ID_Sistem_Sumber IS NULL; -- Hanya insert yang belum aktif

    PRINT 'ETL Dimensi Auditor Selesai.';
END;
GO


-- Procedure untuk Load Fakta (Lookup & Partition Logic)
CREATE OR ALTER PROCEDURE dbo.usp_Load_Fakta_Temuan_Rekomendasi
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Fakta_Temuan_Rekomendasi (
        Waktu_SK, Unit_Kerja_SK, Auditor_SK, Siklus_Audit_SK, 
        Temuan_SK, Rekomendasi_SK,
        Jumlah_Temuan, Skor_Risiko_Temuan, Potensi_Kerugian_IDR, Usia_Rekomendasi_Hari,
        Tahun_Audit, -- Wajib diisi untuk Partisi!
        LoadDate
    )
    SELECT 
        s.Waktu_ID, -- Pastikan formatnya sama dengan Waktu_SK di Dimensi_Waktu
        u.Unit_Kerja_SK,
        a.Auditor_SK,
        sa.Siklus_Audit_SK,
        t.Temuan_SK,
        r.Rekomendasi_SK,
        
        -- Measures
        ISNULL(s.Jumlah_Temuan, 1),
        s.Skor_Risiko,
        s.Potensi_Kerugian_IDR,
        DATEDIFF(DAY, GETDATE(), s.Tanggal_Target_Selesai), -- Contoh logika hitung usia
        
        -- LOGIC PARTISI: Ambil Tahun dari Dimensi Waktu
        dw.Tahun, 
        
        GETDATE()
    FROM stg.Fakta_Import s
    -- Lookup Waktu & Tahun (PENTING untuk Partisi)
    INNER JOIN dbo.Dimensi_Waktu dw ON s.Waktu_ID = dw.Waktu_SK
    -- Lookup Dimensi Lain (Hanya ambil yang Aktif / IsCurrent=1)
    LEFT JOIN dbo.Dimensi_Unit_Kerja u ON s.Kode_Unit = u.Kode_Unit AND u.IsCurrent = 1
    LEFT JOIN dbo.Dimensi_Auditor a ON s.NIP_Auditor = a.ID_Sistem_Sumber AND a.IsCurrent = 1
    LEFT JOIN dbo.Dimensi_Siklus_Audit sa ON s.ID_Siklus = sa.ID_Sistem_Sumber
    LEFT JOIN dbo.Dimensi_Temuan t ON s.ID_Temuan = t.ID_Sistem_Sumber AND t.IsCurrent = 1
    LEFT JOIN dbo.Dimensi_Rekomendasi r ON s.ID_Rekomendasi = r.ID_Sistem_Sumber AND r.IsCurrent = 1
    
    -- Cek agar tidak insert data ganda (Idempotency)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Fakta_Temuan_Rekomendasi f
        WHERE f.Temuan_SK = t.Temuan_SK AND f.Rekomendasi_SK = r.Rekomendasi_SK
    );

    PRINT 'ETL Fakta Selesai.';
END;
GO



-- Master ETL
CREATE OR ALTER PROCEDURE dbo.usp_Master_ETL_Load
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Load Semua Dimensi
        -- (Anda bisa buat SP untuk dimensi lain dengan pola yang sama seperti Auditor)
        EXEC dbo.usp_Load_Dimensi_Auditor;
        
        -- 2. Load Fakta
        EXEC dbo.usp_Load_Fakta_Temuan_Rekomendasi;

        -- 3. Maintenance (Update Statistik agar Query cepat)
        UPDATE STATISTICS dbo.Dimensi_Auditor;
        UPDATE STATISTICS dbo.Fakta_Temuan_Rekomendasi;

        COMMIT TRANSACTION;
        PRINT '=== MASTER ETL BERHASIL DIJALANKAN ===';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
