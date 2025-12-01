USE [master];
GO

-- 1. Full Backup (Biasanya Mingguan)
BACKUP DATABASE [DM_SPI_DW]
TO DISK = N'D:\Backup\DM_SPI_DW_Full.bak'
WITH
COMPRESSION,
INIT,
NAME = N'Full Database Backup - SPI DW',
STATS = 10;
GO

-- 2. Differential Backup (Biasanya Harian)
BACKUP DATABASE [DM_SPI_DW]
TO DISK = N'D:\Backup\DM_SPI_DW_Diff.bak'
WITH
DIFFERENTIAL,
COMPRESSION,
INIT,
NAME = N'Differential Database Backup - SPI DW',
STATS = 10;
GO

-- 3. Transaction Log Backup 
BACKUP LOG [DM_SPI_DW]
TO DISK = N'D:\Backup\DM_SPI_DW_Log.trn'
WITH
COMPRESSION,
INIT,
NAME = N'Transaction Log Backup - SPI DW',
STATS = 10;
GO
