# Pengujian auth email/password — teencu-dev

Branch kerja: `update/teencu`. Konfigurasi Firebase saat ini hanya untuk Android.
Paket Firebase Spark cukup untuk tahap ini; tidak ada Cloud Functions atau Storage.

## Persiapan cloud (dijalankan pemilik project)

1. Di Firebase Console project `teencu-dev`, aktifkan Authentication > Email/Password.
2. Buat Cloud Firestore Standard edition, database `(default)`, pilih lokasi dengan
   sengaja, dan mulai dengan Production mode. Nama project saja tidak membuat database.
3. Dari root repository, publikasikan rules yang sudah ditinjau:

   ```powershell
   firebase deploy --only firestore:rules --project teencu-dev
   ```

   Perintah ini mengubah rules database default di cloud. Konfigurasi FlutterFire di
   `firebase.json` tetap dipertahankan; project target selalu disebut eksplisit.
4. Jalankan `flutter devices`, lalu `flutter run -d <id-perangkat-android>`.
   Jika aplikasi lama masih berjalan, hentikan lalu jalankan ulang; hot reload tidak
   cukup untuk perubahan `google-services.json`.

## Alur dan batasan saat ini

- Firebase Auth menjadi sumber sesi; login yang masih berlaku dipulihkan saat startup.
- Setelah login, profil `users/{uid}` diperiksa/dibuat dalam transaksi. Profil yang
  sudah ada tidak ditimpa. Kegagalan menyediakan pilihan Coba lagi dan Logout.
- Email berasal dari Firebase Auth dan tidak disalin ke dokumen profil. Profil berisi
  username awal berbasis UID, points=0, lastMbti kosong, lastMbtiDate=null, createdAt.
- Password tidak di-trim atau diubah; hanya email yang di-trim.
- Reset password mengembalikan pesan umum, termasuk untuk email tidak terdaftar.
- Rules hanya mengizinkan get profil sendiri dan create dengan nilai awal yang tepat.
  Hasil MBTI baru harus disimpan atomik bersama riwayat. Pengguna
  tidak boleh mengubah poin, username, createdAt, atau menambahkan role.
- Perhitungan MBTI sudah diaudit pada tahap berikutnya. Hasil dari client
  belum boleh digunakan sebagai bukti reward. Chat/leaderboard masih prototype.
- Profil publik dan pertemanan belum dibuat; akses daftar semua users ditolak.
- Logout mengganti seluruh navigator sesi. Riwayat halaman privat tidak dapat
  dibuka lagi melalui tombol Back.
- Jika Firestore/rules belum siap, akun Auth mungkin sudah berhasil dibuat tetapi
  halaman menampilkan kegagalan memuat profil. Selesaikan setup lalu Coba lagi;
  tidak perlu mendaftar ulang.

## Pengujian otomatis

```powershell
flutter test --no-pub
```

Tes widget menggunakan AuthService pengganti, tanpa akun/database cloud. Mencakup
validasi, password utuh, cegah submit ganda, reset, visibilitas password, layar kecil,
pemulihan profil, sesi yang dipulihkan, dan pembersihan navigasi setelah logout.

Tes Security Rules memakai emulator lokal, Node.js >=20, Firebase CLI, dan Java 21:

```powershell
firebase emulators:exec --only auth,firestore --project demo-teencu "node --test test/firestore/*.test.mjs"
```

Script menolak alamat emulator non-lokal. Tidak memerlukan npm install tambahan.
Jika Java aktif masih 17, gunakan Java 21 yang tersedia di Android Studio untuk sesi
terminal tersebut sebelum menjalankan emulator.

## Pengujian manual Android + Firebase asli

1. Daftar dengan email yang kamu kuasai. Pastikan akun muncul di Authentication dan
   profil dengan UID yang sama muncul di Firestore. Profil tanpa tes tidak crash.
2. Tutup paksa aplikasi dan buka lagi: masuk ke beranda tanpa login ulang.
3. Buka profil, logout, tekan Back: halaman akun sebelumnya tidak boleh muncul.
4. Login kembali. Coba password salah: pesan generik tampil dan tombol dapat dipakai lagi.
5. Coba daftar dengan email yang sama, email tidak valid, password pendek, dan
   konfirmasi berbeda: tampil pesan yang sesuai; tidak ada submit berulang.
6. Masukkan email lalu pilih Lupa password (password boleh kosong). Periksa email,
   buka tautan, ubah password, lalu login dengan password baru.
7. Matikan koneksi saat login/pemuatan profil: tampil error/retry, bukan crash.
8. Periksa form saat keyboard terbuka pada layar kecil.

Test otomatis tidak membuktikan email benar-benar terkirim, konfigurasi cloud aktif,
atau persistensi proses Android. Tiga hal tersebut harus diverifikasi di perangkat.

Bank soal dan setup riwayat: lihat docs/mbti-bank-and-history.md.
