USE [DM_SPI_DW];
GO

-----------------------------------------------------------
-- STEP 3.1: CREATE USER ROLES DAN GRANT PERMISSIONS
-----------------------------------------------------------

-- 1. Create Database Roles 
CREATE ROLE db_kepala_spi; 
CREATE ROLE db_analis_audit;
CREATE ROLE db_viewer;
CREATE ROLE db_etl_operator;
GO

-- 2. Grant Permissions (Diperbarui dengan Views Analitik Anda)

-- Peran Kepala SPI
GRANT SELECT ON SCHEMA :: dbo TO db_kepala_spi;
GRANT EXECUTE ON SCHEMA :: dbo TO db_kepala_spi;

-- Peran Analis Audit
GRANT SELECT ON SCHEMA :: dbo TO db_analis_audit; 
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: stg TO db_analis_audit;

-- Peran Viewer (Hanya akses baca ke views analitik dan Dimensi Waktu)
GRANT SELECT ON dbo.vw_Risk_Profile_Unit TO db_viewer;
GRANT SELECT ON dbo.vw_Audit_Performance_Trend TO db_viewer; 
GRANT SELECT ON dbo.Dim_Waktu TO db_viewer;

-- Peran ETL Operator
GRANT EXECUTE ON dbo.usp_Master_ETL_Load TO db_etl_operator; -- Mengasumsikan nama SP ETL Master 
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: stg TO db_etl_operator;
GRANT INSERT, UPDATE ON SCHEMA :: dbo TO db_etl_operator; 
GO

-----------------------------------------------------------
-- STEP 3.2: CREATE USERS DAN ASSIGN ROLES
-----------------------------------------------------------

-- 1. Create SQL Logins (Ganti dengan password yang kuat!)
CREATE LOGIN kepala_spi WITH PASSWORD = 'StrongP@ssw0rd!';
CREATE LOGIN analis_user WITH PASSWORD = 'StrongP@ssw0rd!';
CREATE LOGIN viewer_user WITH PASSWORD = 'StrongP@ssw0rd!';
CREATE LOGIN etl_service WITH PASSWORD = 'StrongP@ssw0rd!';
GO

-- 2. Create Database Users
CREATE USER kepala_spi FOR LOGIN kepala_spi;
CREATE USER analis_user FOR LOGIN analis_user;
CREATE USER viewer_user FOR LOGIN viewer_user;
CREATE USER etl_service FOR LOGIN etl_service;
GO

-- 3. Assign Users to Roles
ALTER ROLE db_kepala_spi ADD MEMBER kepala_spi;
ALTER ROLE db_analis_audit ADD MEMBER analis_user;
ALTER ROLE db_viewer ADD MEMBER viewer_user;
ALTER ROLE db_etl_operator ADD MEMBER etl_service;
GO

-----------------------------------------------------------
-- STEP 3.3: IMPLEMENT DATA MASKING
-----------------------------------------------------------

-- Data Masking untuk kolom ID Auditor (Natural Key)
ALTER TABLE dbo.Dim_Auditor
    ALTER COLUMN ID_Sistem_Sumber ADD MASKED WITH (FUNCTION = 'partial(0, "XX-XXX-", 4)');

-- Data Masking untuk nama Penanggung Jawab di Dimensi Rekomendasi
ALTER TABLE dbo.Dim_Rekomendasi
    ALTER COLUMN Penanggung_Jawab ADD MASKED WITH (FUNCTION = 'default()');

-- Memberikan izin UNMASK hanya kepada Kepala SPI dan Analis
GRANT UNMASK TO db_kepala_spi;
GRANT UNMASK TO db_analis_audit;
GO

-----------------------------------------------------------
-- STEP 3.4: IMPLEMENT AUDIT TRAIL
-----------------------------------------------------------

-- 1. Create Audit Table 
CREATE TABLE dbo.AuditLog (
    AuditID BIGINT IDENTITY (1 ,1) PRIMARY KEY ,
    EventTime DATETIME2 DEFAULT SYSDATETIME (),
    UserName NVARCHAR (128) DEFAULT SUSER_SNAME (),
    EventType NVARCHAR (50) , 
    SchemaName NVARCHAR (128) ,
    ObjectName NVARCHAR (128) ,
    SQLStatement NVARCHAR (MAX),
    RowsAffected INT ,
    IPAddress VARCHAR (50) ,
    ApplicationName NVARCHAR (128) DEFAULT APP_NAME ()
);
GO

-- 2. Create Audit Trigger (Merekam perubahan pada Dimensi Rekomendasi)
CREATE TRIGGER trg_Audit_Dim_Rekomendasi
ON dbo.Dim_Rekomendasi
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventType NVARCHAR (50);
    DECLARE @RowsAffected INT;

    IF EXISTS (SELECT * FROM inserted ) AND EXISTS (SELECT * FROM deleted )
        SET @EventType = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted )
        SET @EventType = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted )
        SET @EventType = 'DELETE';

    SET @RowsAffected = @@ROWCOUNT;

    INSERT INTO dbo.AuditLog (EventType , SchemaName , ObjectName , RowsAffected)
    VALUES (@EventType , 'dbo', 'Dim_Rekomendasi', @RowsAffected);
END;
GO

-- 3. Enable SQL Server Audit (Server-level)
CREATE SERVER AUDIT DataWarehouse_Audit
TO FILE
( FILEPATH = N'D:\Audit\', 
  MAXSIZE = 100 MB ,
  MAX_ROLLOVER_FILES = 10
)
WITH ( ON_FAILURE = CONTINUE );
GO

ALTER SERVER AUDIT DataWarehouse_Audit WITH (STATE = ON);
GO

-- 4. Create Database Audit Specification (Melacak aksi DML dan SELECT)
CREATE DATABASE AUDIT SPECIFICATION DataWarehouse_DB_Audit
FOR SERVER AUDIT DataWarehouse_Audit
ADD (SELECT , INSERT , UPDATE , DELETE ON SCHEMA :: dbo BY public);
GO

ALTER DATABASE AUDIT SPECIFICATION DataWarehouse_DB_Audit WITH (STATE = ON);
GO
