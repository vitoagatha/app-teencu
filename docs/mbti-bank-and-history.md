# Bank soal berversi dan riwayat tes

Implementasi ini memakai Firebase Spark (Auth email/password dan Firestore).
Tidak menambahkan Cloud Functions, Storage, billing, atau dependency aplikasi.
Semua langkah cloud di bawah dijalankan pemilik project; perubahan lokal belum
mengisi database atau mengubah rules cloud secara otomatis.

## Model data

```text
content_admins/{uid}
  enabled: true                         # hanya Console / trusted Admin SDK
mbti_config/active
  testId, updatedAt
mbti_tests/{testId}
  title, version, scoringVersion, status, createdAt, publishedAt,
  questionIds: [q01, q02, ...],
  questions: [{id, text, agreeWith}, ...]
users/{uid}/mbti_results/{sessionId}
  testId, testVersion, scoringVersion, answers,
  dimensionScores, resultType, completedAt
users/{uid}
  ...profil sebelumnya, lastMbti, lastMbtiDate, lastMbtiResultId
```

Satu dokumen menyimpan satu paket soal (4-80 soal, seluruh dimensi harus ada).
Pembatasan ukuran ini membuat paket kecil dan cukup dibaca satu kali. Urutan array
adalah urutan tampilan. Arah memakai E/I/S/N/T/F/J/P. Semua soal mempunyai bobot
sama dan memakai algoritma `teencu-centered-v1`.

Dokumen draft boleh disunting oleh content admin. Setelah published, dokumen tidak
boleh diubah maupun dihapus melalui client, termasuk oleh content admin. Perubahan
isi berarti menerbitkan TestId baru. Pointer aktif dapat berpindah ke versi baru
atau kembali ke versi published lama. Versi lama tetap tersedia untuk riwayat dan
sesi yang sudah dimulai.

Izin content admin sengaja dipisahkan dari profil yang dapat dibuat oleh pengguna.
Aplikasi dan skrip tidak bisa membuat/mengubah dokumen content_admins. Pemilik
project menetapkan atau mencabutnya langsung di Console. Admin konten tidak dapat
membaca riwayat pribadi pengguna lain. Ini mekanisme admin konten; dashboard
admin React tersedia untuk pengelolaan paket. Role moderator, statistik, dan
audit aktivitas admin belum termasuk implementasi saat ini.

## Mengisi bank awal melalui skrip

Untuk pengelolaan harian, gunakan dashboard sesuai [panduan admin](admin-setup.md).
Skrip berikut tersedia untuk menyiapkan paket awal atau mengelola seed dari terminal.

1. Deploy rules terbaru:

   ```powershell
   firebase deploy --only firestore:rules --project teencu-dev
   ```

2. Pilih akun email/password yang sudah kamu daftarkan di Teencu. Salin UID dari
   Firebase Console > Authentication > Users.
3. Di Firestore Console, buat koleksi `content_admins`, Document ID = UID tersebut.
   Tambahkan field `enabled`, tipe **boolean**, nilai **true**. Gunakan Console
   yang diakses dengan akun pemilik project; field role pada users tidak dipakai.
4. Validasi seed tanpa login atau mengubah cloud:

   ```powershell
   ./tools/Publish-MbtiBank.ps1 -ValidateOnly
   ```

5. Publikasikan dan aktifkan bank soal pertama:

   ```powershell
   ./tools/Publish-MbtiBank.ps1 -ProjectId teencu-dev -TestId mbti-v1 -Email 'EMAIL_AKUN_TEENCU' -Activate
   ```

   Ganti EMAIL_AKUN_TEENCU dengan email yang UID-nya diberi izin. Dialog credential
   meminta password **akun Teencu**, bukan password Google. Password dan token tidak
   ditulis ke file atau log. Skrip login ke Firebase Auth lalu menulis melalui rules
   biasa. Tidak memerlukan service-account key. Project cloud harus sama dengan
   google-services.json; kredensial Firebase CLI tidak diambil oleh skrip.

   Skrip membuat draft, lalu menerbitkan draft dan mengubah pointer aktif secara
   atomik. Jika gagal sebelum publish, draft dapat dicoba ulang. Versi yang sudah
   published ditolak jika dicoba ditimpa. Gunakan Action Activate untuk versi itu.

6. Jalankan ulang aplikasi Android. Mulai tes dan pastikan header menampilkan
   Versi v1. Tes tidak memakai bank lokal sebagai fallback jika cloud gagal.

File `seed/mbti-v1.json` berisi 20 soal yang sudah diaudit. Sumber lokal tetap
tersedia sebagai backup. Regenerasi seed hanya bila memang ingin mengambil bank
lokal lagi: `dart --disable-analytics tools/export_mbti_seed.dart`.
Jangan menjalankan export untuk menimpa seed yang sudah kamu sunting.

## Draft dan versi berikutnya

1. Salin seed JSON menjadi misalnya seed/mbti-v2.json. Ubah `version` ke `v2`, lalu
   sunting teks/arah/urutan/jumlah soal. Pertahankan ID untuk pertanyaan yang sama;
   gunakan ID baru jika pertanyaannya berbeda.
2. Validasi dan buat draft:

   ```powershell
   ./tools/Publish-MbtiBank.ps1 -SeedPath seed/mbti-v2.json -ValidateOnly
   ./tools/Publish-MbtiBank.ps1 -Action Draft -TestId mbti-v2 -SeedPath seed/mbti-v2.json -Email 'EMAIL_AKUN_TEENCU'
   ```

3. Setelah meninjau seed, publish dan aktifkan:

   ```powershell
   ./tools/Publish-MbtiBank.ps1 -Action Publish -TestId mbti-v2 -SeedPath seed/mbti-v2.json -Email 'EMAIL_AKUN_TEENCU' -Activate
   ```

   Seed JSON adalah sumber isi draft untuk skrip. Action Publish menyelaraskan
   draft dengan seed itu sebelum menerbitkannya, jadi sunting seed sebelum publish.
4. Untuk memilih kembali versi yang sudah published:

   ```powershell
   ./tools/Publish-MbtiBank.ps1 -Action Activate -TestId mbti-v1 -Email 'EMAIL_AKUN_TEENCU'
   ```

Pembatasan draft/published berlaku untuk SDK/API melalui Security Rules. Pemilik
project yang memakai Console/Admin SDK tetap berwenang melewati rules; jangan
mengubah atau menghapus versi published secara manual karena riwayat merujuknya.

## Perilaku mobile dan riwayat

- Saat tes dibuka, aplikasi membaca pointer aktif dan satu versi published dari
  server. Snapshot itu tidak dimuat ulang di tengah tes.
- Jawaban Netral/seimbang tetap mengikuti aturan sebelumnya: tidak membuat hasil
  lengkap dan tidak menimpa profil.
- Submit menghitung lagi skor dari paket yang dibekukan. Jawaban disalin agar
  perubahan UI tidak mengubah payload yang sedang disimpan.
- Transaksi membuat history dan memperbarui profil bersama-sama. Rules menolak
  history tanpa profil yang sesuai, pointer tanpa history baru, atau perubahan XP.
- ID hasil mencakup ID sesi dan fingerprint jawaban. Retry jawaban yang sama memakai
  ID sama. Jika hasil sudah ada, transaksi tidak menambah hasil atau memundurkan
  profil ke hasil lama. Jawaban berbeda setelah gagal simpan memakai ID berbeda.
- Riwayat tersedia dari Profil > Riwayat tes MBTI. Daftar dibaca 20 hasil per halaman
  (query mengambil 21 untuk mendeteksi halaman berikutnya), terbaru di atas.
- Detail mengambil versi asli, lalu menampilkan jawaban, tanggal, dan skor dimensi.
- Poin tetap tidak berubah. Scoring masih di client dan bukan bukti tepercaya untuk
  reward. Rules memvalidasi struktur/versi/rentang dan tanda skor, belum menghitung
  ulang seluruh skor dari jawaban. Backend tepercaya diperlukan sebelum XP.
- Hasil sebelum tahap ini hanya memiliki lastMbti/lastMbtiDate. Jawaban individual
  tidak tersedia sehingga riwayat lama tidak dapat direkonstruksi.

Rules baru menolak penyimpanan hasil hanya ke profil dari APK lama. Gunakan build
terbaru bersama rules baru, dan isi bank soal sebelum menguji fitur tes.

## Scoring MBTI

Setiap pertanyaan menentukan `agreeWith`, sisi yang didukung ketika pengguna
setuju. Kontribusi skor adalah `(rating - 3) * direction`: direction +1 untuk
E/S/T/J dan -1 untuk I/N/F/P. Rating 1–5 menghasilkan kontribusi -2, -1, 0, +1, +2
ke sisi setuju. Jumlahkan per dimensi EI, SN, TF dan JP; nilai positif memilih
E/S/T/J, negatif memilih I/N/F/P.

Jika ada dimensi bernilai nol, tipe empat huruf belum ditentukan. Aplikasi
menampilkan dimensi seimbang dan tidak menimpa hasil profil. Scorer memvalidasi
kelengkapan jawaban, ID pertanyaan, rating dan keterwakilan empat dimensi.
Perhitungan mobile dan pratinjau admin menggunakan fixture bersama pada
`test/fixtures/mbti-scoring-cases.json`.

Scoring Dart berada di `lib/services/mbti_scoring.dart`, dan scoring dashboard di
`admin/src/domain/mbtiScoring.js`. Skor bukan persentase kepastian atau diagnosis.
Materi soal masih memerlukan peninjauan konten/psikometri: q08 menggabungkan
intuisi/perasaan, q12 mengaitkan keadilan, dan q19/q20 mengaitkan penundaan/kecepatan
dengan preferensi. Pada seed awal, soal searah EI/SN/TF berbanding 4:1 dan JP 3:2.
