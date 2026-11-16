# Dashboard admin Teencu

Dashboard React + JavaScript + Vite menggunakan CoreUI Free React untuk mengelola
paket pertanyaan MBTI. Fitur yang tersedia: login admin, daftar/detail paket,
salinan draft, editor, pratinjau scoring, publikasi dan aktivasi versi.
Lisensi komponen tersedia di [THIRD_PARTY_NOTICES](../admin/THIRD_PARTY_NOTICES.md).

## Menjalankan dashboard

Gunakan Node sesuai batas versi di [package.json](../admin/package.json).
Dari root repositori:

```sh
cd admin
npm ci
npm run dev
```

Buka http://127.0.0.1:5173. Jika port sudah digunakan, hentikan dev server sebelumnya
pada terminalnya. Restart server setelah mengganti konfigurasi environment.

## Emulator lokal

Tanpa `.env.local`, dashboard memakai project `demo-teencu`, Auth 9099 dan
Firestore 8080 di localhost. Emulator yang gagal terhubung tidak dialihkan ke cloud.

Dari root repo, jalankan pada terminal terpisah dengan Java 21:

```powershell
$env:JAVA_HOME = 'C:/Program Files/Android/Android Studio/jbr'
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
firebase emulators:start --only auth,firestore --project demo-teencu
```

Dari folder `admin/`, siapkan data contoh:

```sh
npm run seed:emulator
```

Script ini hanya mengakses emulator. Kredensial contoh dicetak oleh script dan
bukan akun cloud. Seed tidak menimpa paket/pointer yang sudah ada, tetapi
mengaktifkan kembali role akun admin contoh.

## Firebase cloud

1. Di Firebase Console project `teencu-dev`, ambil konfigurasi Web App
   `teencu-admin` yang sudah terdaftar. Gunakan App ID Web, bukan Android.
   Dashboard localhost tidak membutuhkan Firebase Hosting.
2. Dari root repo, salin `admin/.env.example` ke `admin/.env.local`. Isi config
   resmi Web App dengan struktur berikut:

   ```dotenv
   VITE_FIREBASE_TARGET=cloud
   VITE_FIREBASE_API_KEY=CONFIG_WEB_APP
   VITE_FIREBASE_AUTH_DOMAIN=teencu-dev.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=teencu-dev
   VITE_FIREBASE_APP_ID=APP_ID_WEB
   ```

3. Masuk dengan akun Email/Password yang terdaftar di Authentication
   `teencu-dev`. Akun Firebase Console dan akun contoh emulator berbeda.
4. Pemilik project menetapkan dokumen Firestore `content_admins/{UID}` dengan
   `enabled: true` bertipe boolean. UID diambil dari Authentication → Users.
   Dashboard tidak dapat menetapkan izin sendiri.
5. Dari root repo, deploy rules yang sesuai aplikasi:

   ```sh
   firebase deploy --only firestore:rules --project teencu-dev
   ```

6. Restart dashboard dan pastikan login menunjukkan **Cloud · teencu-dev**.
   Pastikan tidak ada variabel terminal `VITE_FIREBASE_TARGET=emulator` yang
   menimpa file lokal. Untuk kembali ke emulator, ganti target dan restart.

File `.env.local` diabaikan Git. Nilai `VITE_*` masuk bundle browser; simpan hanya
config client, bukan password, token atau service-account key. Hak akses tetap
diperiksa oleh Firebase Auth dan Firestore Rules.

Jika akses ditolak, periksa UID dan role. Jika login berhasil tetapi daftar gagal,
periksa koneksi serta rules cloud terbaru. Dokumen paket tanpa `createdAt`
tidak masuk query daftar. Hilangnya izin admin mengunci workspace kembali.

## Alur pengelolaan

Buat draft atau salin paket → Edit pertanyaan → Simpan → Pratinjau → Terbitkan.
Salinan yang tersimpan membuka detailnya; gunakan tombol Edit pertanyaan di sana.
Paket terbit terkunci. Aktivasi merupakan tindakan terpisah untuk tes baru.

Model data, scoring, riwayat dan aturan versi dijelaskan di
[bank soal dan riwayat](mbti-bank-and-history.md).

## Pemeriksaan sebelum perubahan dirilis

Dari `admin/`: `npm test` dan `npm run build`. Dari root: `flutter test --no-pub`.
Unit test tidak membuktikan akses cloud. Periksa juga login/izin, simpan dan muat
ulang draft, publikasi tanpa aktivasi, serta pergantian versi pada Android:
sesi lama mempertahankan versinya, tes baru mengambil versi aktif, dan riwayat
lama tetap terbaca.

Build saat ini masih memberi peringatan ukuran bundle JavaScript di atas 500 kB.
