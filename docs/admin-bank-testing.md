# Ringkasan dan daftar bank soal (tahap keempat)

## Fitur

- Ringkasan paket aktif beserta label versi dan jumlah soal.
- Daftar paket terbaru berdasarkan `createdAt`, lalu ID dokumen sebagai penentu
  urutan jika waktu sama. Tombol sebelumnya/berikutnya, 20 paket per halaman.
- Status draft/published, penanda aktif, dan tanggal publikasi. Ringkasan jumlah
  draft/published hanya mencakup halaman yang tampil, bukan total seluruh koleksi.
- Detail berisi metadata dan seluruh pertanyaan, ID soal, serta arah penilaiannya.
- Salin paket menjadi draft dengan ID, judul, dan versi baru. Transaksi menolak
  ID yang sudah digunakan; tidak mengubah paket asal atau pointer aktif.
- Data salah diberi penanda pada daftar dan tidak dapat disalin. Error data/izin
  dan koneksi menyediakan retry. Data dibaca dari server, tanpa fallback cache.
- Navigasi detail/kembali masih dalam workspace admin. Ketika logout, sesi berubah,
  atau izin hilang, workspace beserta hasil query-nya dilepas.

Editor, publikasi, dan aktivasi melalui dashboard dikerjakan pada tahap berikutnya.
Draft salinan dapat ditinjau sekarang, namun belum bisa mengubah soal di dashboard.

## Perubahan rules

`mbti_tests` kini mengizinkan `list` hanya untuk admin aktif, dengan limit 1–21.
Query tanpa limit atau limit lebih dari 21 ditolak, termasuk untuk admin.
Pengguna biasa tetap dapat `get` versi published, tetapi tidak dapat query daftar
atau membaca draft. Aturan immutable, privasi history, dan poin tetap berlaku.

Untuk emulator, restart setelah perubahan rules. Untuk cloud `teencu-dev`, pemilik
project perlu menerbitkan rules terbaru sebelum daftar dapat diakses:

```powershell
firebase deploy --only firestore:rules --project teencu-dev
```

Perintah tersebut belum dijalankan otomatis. Tidak diperlukan migrasi skema paket.
Dokumen tanpa `createdAt` tidak muncul dalam query berurutan; ini bukan format
paket yang valid. Dokumen valid yang dibuat lewat publisher sudah memilikinya.

## Uji manual di browser

1. Jalankan emulator dari root seperti [setup](admin-setup.md), lalu dari `admin/`:

   ```sh
   npm run seed:emulator
   npm run dev
   ```

   Seed sekarang juga menambahkan paket `demo-mbti-v1` published dan
   `demo-mbti-v2-draft`, serta pointer aktif bila belum ada. Menjalankan ulang tidak
   menimpa paket/pointer yang sudah ada, tetapi tetap mengaktifkan role admin contoh.
2. Login admin sesuai [panduan auth](admin-auth-testing.md). Pastikan ringkasan
   menunjuk paket aktif dan daftar memuat published serta draft, masing-masing 20 soal.
3. Buka Detail dan Lihat paket aktif. Periksa versi, status, urutan soal, arah,
   dan tanggal. Kembali ke daftar memuat ulang halaman pertama.
4. Dari paket published, salin sebagai `demo-mbti-v3-draft`, label `v3`.
   Detail salinan harus draft, tanggal publikasi kosong, soal tetap sama.
   Kembali: salinan muncul; paket aktif tetap versi sebelumnya.
5. Coba salin ke ID yang sudah ada: tampil pesan dan data tidak tertimpa.
6. Untuk menguji daftar panjang, buat salinan tambahan atau jalankan tes repository
   di bawah pada instance emulator khusus pengujian. Tes menambah lebih dari 20 paket.
7. Matikan koneksi: data yang belum termuat menampilkan error/retry. Muat ulang data
   setelah koneksi pulih. Jangan menganggap salinan gagal pasti tidak tersimpan;
   buka daftar/detail ID tujuan untuk memeriksa hasil sebelum mengganti ID.
8. Login akun biasa: akses dashboard tetap ditolak. Uji pencabutan role seperti
   panduan auth; workspace harus tertutup.

Daftar menggunakan pembacaan per permintaan, bukan listener realtime. Bila admin
lain mengganti versi aktif, gunakan Muat ulang data untuk memperbarui penandanya.
Untuk paket dengan tanggal publikasi kosong (draft), daftar menampilkan `—`.

## Verifikasi otomatis

Tes konfigurasi/sesi/kontrak data/pagination dan build, dari `admin/`:

```sh
npm test
npm run build
```

Tes rules lama dan repository baru melalui SDK Firebase, dari root (Java 21):

```powershell
firebase emulators:exec --config firebase.admin-test.json --only auth,firestore --project demo-teencu "node --test --test-concurrency=1 --test-skip-pattern=PowerShell test/firestore/*.test.mjs admin/tests/mbtiRepository.emulator.test.mjs"
```

Config pengujian menggunakan Auth 9199 dan Firestore 8180 agar terpisah dari sesi
manual pada 9099/8080. Tes menggunakan
project demo dan menulis fixture lokal; tidak menggunakan cloud. Urutan serial
mencegah tes terpisah berebut pointer `mbti_config/active` yang sama.
Tes SDK memeriksa query, pagination dengan timestamp sama, get paket aktif/detail,
salinan draft, ID bentrok, query tanpa batas/limit berlebih, serta pencabutan role.
Tes publisher PowerShell lama dilewati dalam konfigurasi terpisah ini karena
skripnya memakai port lokal tetap 9099/8080. Suite publisher tetap dapat dijalankan
melalui konfigurasi utama saat tidak ada sesi manual yang memakai port tersebut.
