# Data Mart - Satuan Pengawas Internal (SPI)
Tugas Besar Pergudangan Data - Kelompok 16

SD25-31007 - Pergudangan Data Tugas Besar Kelompok 16

## Team Members

| NIM | Name | Role |
| :--- | :--- | :--- |
| 123450012 | Anggi Puspita Ningrum | Ketua Tim | 
| 123450019 | Anadia Carana | Anggota | 
| 123450076 | Iqfina Haula Halika | Anggota |
| 122450124 | Muhammad Dzikra | Anggota | 

## Project Description
Implementasi Data Mart untuk unit Satuan Pengawas Internal (SPI) yang bertujuan untuk menyediakan informasi terpusat untuk analisis audit internal dan pengawasan kinerja.

## Business Domain
Satuan Pengawas Internal (SPI) bertanggung jawab untuk melakukan audit dan pengawasan internal atas seluruh kegiatan operasional dan keuangan organisasi. Data Mart ini berfokus pada pelaporan temuan audit, status tindak lanjut, dan kinerja audit.

## Architecture
* **Approach:** Kimball
* **Platform:** SQL Server on Azure VM
* **ETL:** SSIS

## Key Features
* **Fact tables:** Fact Audit, Fact Tindak Lanjut
* **Dimension tables:** Dim Waktu, Dim Auditor, Dim Unit Kerja, Dim Jenis Temuan, Dim Status Tindak Lanjut
* **KPIs:** Jumlah Temuan Audit, Persentase Tindak Lanjut Selesai, Rata-rata Waktu Penyelesaian Tindak Lanjut.

## Documentation
* [Business Requirements](docs/01-requirements/)
* [Design Documents](docs/02-design/)
* [Laporan Misi 1](https://drive.google.com/file/d/1qDsmpNN1u3PWiXys3PMfYnOXgJ8GSe0E/view?usp=sharing)

## Timeline
* Misi 1: 17 November 2025
* Misi 2: 24 November 2025
* Misi 3: 01 Desember 2025
