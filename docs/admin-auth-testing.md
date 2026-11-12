# Login dan akses admin (tahap ketiga)

## Perilaku

- Login email/password menggunakan Firebase Auth. Email di-trim, password tetap.
- Dashboard tidak menyediakan daftar akun, registrasi, atau pengubahan role.
- Hanya dokumen `content_admins/{uid}` sendiri yang dipantau; `enabled` wajib
  boolean `true`, dikonfirmasi server, sebelum konten admin ditampilkan.
- Status cache/offline tidak memberikan akses. Pemeriksaan yang tidak selesai
  dalam 15 detik menampilkan Coba lagi. Kegagalan sesi/izin berbeda dari akses ditolak.
- Listener memantau role yang diubah menjadi false atau dihapus. Hak akses dilepas
  pada perubahan tersebut. Logout/pergantian akun membersihkan listener; callback
  akun lama tidak dapat membuka dashboard akun baru.
- Sesi login baru memakai browser session persistence: refresh pada tab yang sama
  memulihkan sesi; browser menangani penyimpanan sesi sampai tab ditutup.
- Saat ini halaman admin hanya mengonfirmasi izin dan menyediakan logout. Daftar
  paket, query bank, serta editor dikerjakan pada tahap berikutnya.
- Rules yang sudah ada cukup untuk tahap ini; tidak ada deploy rules baru.

## Uji lokal

1. Dari root repo, jalankan emulator seperti panduan [setup](admin-setup.md),
   project `demo-teencu`, Auth 9099 dan Firestore 8080.
2. Terminal kedua, dari `admin/`, jalankan:

   ```sh
   npm run seed:emulator
   npm run dev
   ```

   Script seed hanya mengakses `127.0.0.1`, project demo, menggunakan bypass owner
   khusus emulator untuk membuat dua akun/role pengujian. Tidak mengakses cloud.
   Menjalankan ulang mengaktifkan kembali akun admin contoh. Jangan gunakan
   kredensial contoh untuk akun cloud.

3. Buka http://127.0.0.1:5173 dalam mode emulator (default).
4. Login `admin@teencu.example` dengan password `Teencu-local-only-123`:
   halaman menyatakan izin admin dikonfirmasi. Refresh: akses dipulihkan setelah cek.
5. Logout, login `user@teencu.example` dengan password yang sama: akses ditolak,
   tersedia Keluar / ganti akun. Password salah menampilkan pesan login gagal.
6. Untuk menguji pencabutan role, login admin, lalu jalankan dari PowerShell:

   ```powershell
   # Ganti dengan UID admin yang ditampilkan npm run seed:emulator.
   $adminUid = 'UID_ADMIN_DARI_OUTPUT_SEED'
   $body = '{"fields":{"enabled":{"booleanValue":false}}}'
   Invoke-RestMethod -Method Patch -Uri "http://127.0.0.1:8080/v1/projects/demo-teencu/databases/(default)/documents/content_admins/$adminUid" -Headers @{Authorization='Bearer owner'} -ContentType 'application/json' -Body $body
   ```

   Halaman admin berubah menjadi akses ditolak. `npm run seed:emulator` mengaktifkan
   kembali role; listener yang masih aktif dapat membuka kembali akses.
7. Matikan emulator atau gunakan DevTools Offline: akses admin tidak boleh dibuka
   hanya berdasarkan cache. Setelah status cache terdeteksi, halaman terkunci;
   pemeriksaan yang timeout menawarkan coba lagi. Bukan janji deteksi putus jaringan
   secara instan; penolakan operasi data selalu menjadi tanggung jawab rules server.
8. Logout/ganti akun berulang: tidak ada halaman admin akun lama yang tertinggal.

## Uji cloud

Isi config Web App sesuai [setup](admin-setup.md), restart Vite, gunakan akun Teencu
yang sudah ada. Pemilik project memastikan `content_admins/{UID}.enabled = true`
melalui Console. Admin tidak dapat menetapkan izin sendiri dari dashboard.
Jika memakai custom domain untuk Auth, periksa konfigurasi domain Firebase Auth.
Jangan kirim password/token ke chat atau menyimpannya dalam `.env`.

## Verifikasi otomatis

Dari `admin/`: `npm test` dan `npm run build`. Tes alur sesi mencakup server vs
cache, role aktif/nonaktif, pergantian akun, callback terlambat, retry, logout,
gagal logout, lifecycle start/stop, dan timeout. Tes ini memakai adapter palsu;
bukan pengganti pengujian tampilan browser dan koneksi Firebase di atas.

Sumber: [Firebase Auth](https://firebase.google.com/docs/auth/web/password-auth),
[listener Firestore](https://firebase.google.com/docs/firestore/query-data/listen).
