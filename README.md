# BIOTA: Aplikasi Mobile Konservasi Keanekaragaman Hayati 🌱📱

[![Build Status](https://img.shields.io/badge/Status-Complete-brightgreen)](https://github.com/NemesisID/BIOTA---Flutter-v1.0.0/)
[![Project Type](https://img.shields.io/badge/Type-Final%20Project-blue)](https://github.com/NemesisID/BIOTA---Flutter-v1.0.0/)
[![Framework](https://img.shields.io/badge/Framework-Flutter-02569B?logo=flutter)](https://flutter.dev/)
[![Language](https://img.shields.io/badge/Language-Dart-0175C2?logo=dart)](https://dart.dev/)
[![Database](https://img.shields.io/badge/Database-SQLite-003B57?logo=sqlite)](https://www.sqlite.org/index.html)
[![License](https://img.shields.io/github/license/NemesisID/BIOTA---Flutter-v1.0.0)](https://github.com/NemesisID/BIOTA---Flutter-v1.0.0/blob/main/LICENSE)

## Tentang Proyek 🌿

**BIOTA** adalah aplikasi mobile inovatif yang dirancang untuk menjadi jembatan antara teknologi digital dan upaya konservasi keanekaragaman hayati di Indonesia. Proyek ini dikembangkan sebagai **Final Project** mata kuliah Pemrograman Mobile di Universitas Pembangunan Nasional "Veteran" Jawa Timur.

[cite_start]Di tengah ancaman serius terhadap flora dan fauna endemik Indonesia akibat deforestasi, perburuan liar, dan rendahnya kesadaran masyarakat, BIOTA hadir sebagai solusi berbasis teknologi. [cite_start]Aplikasi ini bertujuan untuk meningkatkan kesadaran, memfasilitasi partisipasi aktif masyarakat, dan menyediakan akses informasi yang valid mengenai keanekaragaman hayati langsung dari genggaman pengguna.

[cite_start]Melalui BIOTA, kami berupaya mengaplikasikan konsep-konsep pemrograman mobile modern seperti perancangan UI/UX yang intuitif, pengelolaan data lokal, dan integrasi fitur perangkat keras mobile (kamera & GPS). [cite_start]Lebih dari itu, proyek ini secara langsung berkontribusi pada pencapaian **Sustainable Development Goal (SDG) 15: Life on Land**, yang berfokus pada perlindungan dan restorasi ekosistem daratan serta penghentian kehilangan keanekaragaman hayati.

## Fitur Utama ✨

BIOTA dilengkapi dengan berbagai fitur esensial untuk mendukung misi konservasi:

* [cite_start]**Autentikasi Pengguna:** Sistem registrasi, login, dan logout yang aman untuk pengguna dan admin.
* [cite_start]**Pelaporan Spesies Baru:** Pengguna dapat mengajukan data spesies yang mereka temukan, lengkap dengan nama, kategori, deskripsi, lokasi akurat (via GPS), dan foto (dari kamera atau galeri). [cite_start]Data ini akan melalui verifikasi oleh admin.
* [cite_start]**Peta Interaktif:** Visualisasi sebaran lokasi spesies yang dilaporkan pada peta interaktif, memungkinkan eksplorasi habitat.
* [cite_start]**Katalog & Pencarian Spesies:** Akses mudah ke database flora dan fauna yang telah diverifikasi, dilengkapi dengan informasi detail untuk tujuan edukasi.
* [cite_start]**Informasi Event Konservasi:** Daftar event konservasi yang akan datang atau sedang berlangsung, lengkap dengan detail lokasi, jadwal, dan tautan pendaftaran.
* [cite_start]**Riwayat Kontribusi:** Pengguna dapat melacak status laporan spesies yang mereka ajukan (menunggu review, disetujui, ditolak).
* [cite_start]**Panel Administrasi:** Dashboard khusus untuk admin mengelola data spesies (verifikasi, hapus), mengelola pengguna, dan memperbarui konten edukatif ("Fun Fact").
* [cite_start]**Manajemen Profil Pengguna:** Pengguna dapat melihat dan mengedit informasi profil mereka, termasuk foto profil dan kata sandi.

## Teknologi yang Digunakan 🛠️

Proyek BIOTA dibangun dengan fondasi teknologi yang modern dan efisien:

* [cite_start]**Framework:** [Flutter SDK](https://flutter.dev/) (Versi 3.4.4) 
* [cite_start]**Bahasa Pemrograman:** [Dart](https://dart.dev/) 
* [cite_start]**Database Lokal:** [SQLite](https://www.sqlite.org/index.html) (melalui plugin `sqflite`) untuk penyimpanan data persisten offline.
* [cite_start]**Lokasi:** [Geolocator](https://pub.dev/packages/geolocator) untuk mendapatkan koordinat GPS dan [Geocoding](https://pub.dev/packages/geocoding) untuk konversi koordinat ke alamat.
* [cite_start]**Pengambilan Gambar:** [Image Picker](https://pub.dev/packages/image_picker) untuk mengambil foto dari galeri atau kamera.
* [cite_start]**Peta Interaktif:** [flutter_map](https://pub.dev/packages/flutter_map) menggunakan [OpenStreetMap](https://www.openstreetmap.org/) sebagai penyedia tile peta.
* [cite_start]**Manajemen State/Autentikasi:** [Shared Preferences](https://pub.dev/packages/shared_preferences) untuk menyimpan status login secara persisten.
* [cite_start]**IDE:** [Visual Studio Code (VS Code)](https://code.visualstudio.com/)[cite: 133].
* [cite_start]**Arsitektur:** Mengadopsi arsitektur berbasis komponen Flutter dengan lapisan Presentation, Business Logic, dan Data.

## Instalasi & Setup 🚀

Untuk menjalankan proyek ini secara lokal:

1.  **Clone repositori:**
    ```bash
    git clone [https://github.com/NemesisID/BIOTA---Flutter-v1.0.0.git](https://github.com/NemesisID/BIOTA---Flutter-v1.0.0.git)
    cd BIOTA---Flutter-v1.0.0
    ```
2.  **Dapatkan dependensi Flutter:**
    ```bash
    flutter pub get
    ```
3.  **Jalankan aplikasi:**
    ```bash
    flutter run
    ```
    (Pastikan Anda memiliki emulator Android yang berjalan atau perangkat fisik yang terhubung dan diatur untuk debugging USB.)

## Rencana Pengembangan Lanjutan (Future Enhancements) 💡

Kami memiliki beberapa ide untuk pengembangan BIOTA di masa depan:

* **Integrasi AI untuk Identifikasi Spesies:** Menerapkan model AI untuk identifikasi otomatis spesies dari foto yang diunggah.
* **Backend & Sinkronisasi Data:** Pengembangan server backend untuk database terpusat, mendukung skalabilitas dan sinkronisasi data antar perangkat.
* **Fitur Komunitas yang Lebih Kuat:** Menambahkan forum diskusi, grup tematik, atau sistem pesan antar pengguna.
* **Notifikasi Real-time:** Notifikasi push untuk update status laporan, event baru, atau berita konservasi penting.
* **Optimasi Peta Lanjut:** Peningkatan performa pemuatan dan rendering peta untuk data yang sangat besar (misalnya dengan *marker clustering*).

## Tim Pengembang 🧑‍💻👩‍💻

Proyek ini adalah hasil kerja keras dan kolaborasi dari Kelompok 8:

* **Ragil Hidayatulloh**
* **Debita Faulirisma Garcia**
* **Annisa Indah Cahyani**

**Dosen Pengampu:**
* Bapak Iqbal Ramadhani Mukhlis, S.Kom., M.Kom. 

## Lisensi 📄

Proyek ini dilisensikan di bawah [Nama Lisensi Anda, misalnya: MIT License]. Lihat file [LICENSE](LICENSE) untuk detail lebih lanjut. ## Ucapan Terima Kasih 🙏

Kami mengucapkan terima kasih kepada:
* Universitas Pembangunan Nasional "Veteran" Jawa Timur atas fasilitas dan kesempatan yang diberikan.
* Bapak Iqbal Ramadhani Mukhlis, S.Kom., M.Kom. atas bimbingan dan arahannya selama pengembangan proyek.
* Komunitas Flutter dan Font Awesome atas sumber daya open-source yang luar biasa.

---
