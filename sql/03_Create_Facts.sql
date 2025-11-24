-- Grain: Satu baris per Temuan Audit per Rekomendasi terkait.
CREATE TABLE dbo.Fact_Temuan_Rekomendasi (
    Fakta_SK BIGINT IDENTITY(1,1) NOT NULL, -- Primary Key Tunggal
   
    -- Foreign Keys
    Waktu_SK INT NOT NULL,
    Auditor_SK INT NOT NULL,
    Unit_Kerja_SK INT NOT NULL,
    Siklus_Audit_SK INT NOT NULL,
    Temuan_SK INT NOT NULL,
    Rekomendasi_SK INT NOT NULL,
    Sistem_Sumber_SK INT NOT NULL,
   
    -- Degenerate Dimension & Partitioning Key
    Tahun_Audit INT NOT NULL, -- Ditambahkan untuk mendukung Partitioning yang spesifik

    -- Measures (Sesuai Data Dictionary Fakta)
    Jumlah_Temuan INT DEFAULT 1,
    Skor_Risiko_Temuan DECIMAL(5,2),
    Potensi_Kerugian_IDR BIGINT DEFAULT 0,
    Usia_Rekomendasi_Hari INT,
   
    -- Metadata Audit
    LoadDate DATETIME DEFAULT GETDATE(),


    -- Constraints
    CONSTRAINT PK_Fact_Temuan_Rekomendasi PRIMARY KEY CLUSTERED (Fakta_SK),
   
    -- Membuat Relasi (Constraint Foreign Key)
    CONSTRAINT FK_Fact_Waktu FOREIGN KEY (Waktu_SK) REFERENCES dbo.Dim_Waktu(Waktu_SK),
    CONSTRAINT FK_Fact_Auditor FOREIGN KEY (Auditor_SK) REFERENCES dbo.Dim_Auditor(Auditor_SK),
    CONSTRAINT FK_Fact_Unit FOREIGN KEY (Unit_Kerja_SK) REFERENCES dbo.Dim_Unit_Kerja(Unit_Kerja_SK),
    CONSTRAINT FK_Fact_Siklus FOREIGN KEY (Siklus_Audit_SK) REFERENCES dbo.Dim_Siklus_Audit(Siklus_Audit_SK),
    CONSTRAINT FK_Fact_Temuan FOREIGN KEY (Temuan_SK) REFERENCES dbo.Dim_Temuan(Temuan_SK),
    CONSTRAINT FK_Fact_Rekomendasi FOREIGN KEY (Rekomendasi_SK) REFERENCES dbo.Dim_Rekomendasi(Rekomendasi_SK),
    CONSTRAINT FK_Fact_SistemSumber FOREIGN KEY (Sistem_Sumber_SK) REFERENCES dbo.Dim_Sistem_Sumber(ID_Sistem_Sumber)
)
ON PS_AuditYear (Tahun_Audit);
GO
