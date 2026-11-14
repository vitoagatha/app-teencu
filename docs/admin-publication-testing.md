# Publish dan aktivasi versi (tahap ketujuh)

## Alur dashboard

Edit draft -> Simpan -> Pratinjau -> kembali ke detail paket -> Publish -> Aktifkan.
Pratinjau adalah sarana peninjauan, bukan syarat teknis wajib untuk publish.
Publish hanya tersedia dari detail paket tersimpan; isian editor yang belum disimpan
tidak dapat dipublikasikan dari editor atau pratinjau.

- **Publish paket** membuka konfirmasi judul, ID, label versi, dan jumlah soal.
  Publikasi mengunci paket; tidak mengganti pointer versi aktif.
- **Aktifkan versi ini** tersedia untuk paket published. Dashboard membaca ulang
  target dan pointer aktif sebelum menampilkan konfirmasi versi lama dan tujuan.
- **Batal** menutup konfirmasi tanpa write. Tombol dan navigasi workspace dikunci
  saat operasi berjalan. Ketukan berulang tidak mengirim operasi ganda.
- Sukses menampilkan pesan, memuat ulang detail dan penanda aktif. Kembali ke daftar
  memuat ulang ringkasan aktif dan daftar. Tab admin lain menggunakan Muat ulang data.
- Gagal menampilkan alasan dan tidak mempertahankan dialog konfirmasi lama.
  Gunakan **Muat ulang status** setelah error atau hasil operasi tidak pasti;
  tinjau kembali sebelum mengonfirmasi ulang. Jangan menganggap jaringan gagal
  selalu berarti write belum dilakukan.
- Paket yang sudah aktif dapat dikonfirmasi lagi tanpa memperbarui pointer/tanggal.
- Versi published lama boleh diaktifkan kembali. Sesi tes yang sudah dimulai dan
  riwayat hasil pengguna tetap merujuk paket asal; pengguna lama tidak wajib tes ulang.

## Validasi, konflik, dan izin

Publish menghitung fingerprint seluruh paket tersimpan saat ditinjau. Transaksi
membaca ulang dokumen, memvalidasi isi soal dan status draft, lalu membandingkan
fingerprint sebelum menulis status published dan server timestamp `publishedAt`.
Perubahan apa pun sejak ditinjau menuntut muat ulang dan peninjauan kembali.

Aktivasi membawa snapshot target dan seluruh pointer (termasuk `updatedAt`) dari
dialog konfirmasi. Transaksi membaca keduanya kembali. Perubahan target atau pointer
ditolak, termasuk versi aktif yang berpindah A -> B -> A. Ini mencegah dialog lama
menimpa keputusan admin lain meskipun ID versi aktif kembali sama.

Semua write melalui Web SDK dan rules admin yang sudah ada. Published tetap
immutable, draft tidak bisa diaktifkan, akun biasa tidak dapat publish/aktivasi,
dan role dicabut menolak write berikutnya. Tidak mengubah profil, history, XP,
atau algoritma scoring. Validasi lengkap isi soal tetap merupakan validasi client
admin tepercaya, sesuai batasan audit awal. Console/Admin SDK dapat melewati rules.

Tidak ada perubahan rules atau deployment cloud pada tahap ini. Rules tahap
keempat tetap diperlukan untuk akses daftar bank. Hosting belum termasuk lingkup.

## Uji manual (emulator terlebih dahulu)

1. Login admin, buka paket draft contoh. Pratinjau, kembali ke detail.
2. Publish -> Batal: tetap draft. Publish -> konfirmasi: menjadi published, tanggal
   publikasi terisi, edit hilang, dan versi aktif belum berubah.
3. Aktifkan -> Batal: versi aktif tetap. Aktifkan -> konfirmasi: penanda Aktif muncul;
   daftar/ringkasan setelah kembali menunjuk paket tersebut.
4. Buka versi published lama, aktifkan kembali. Kedua paket published masih utuh.
5. Dua tab: buka detail draft di A; edit/simpan dari B; publish di A ditolak karena
   isi berubah. Muat ulang status di A dan tinjau sebelum konfirmasi ulang.
6. Dua tab: buka dialog aktivasi di A; ganti versi aktif dari B. Konfirmasi A ditolak.
   Buka dialog baru di A untuk melihat keputusan terbaru.
7. Coba offline/role dicabut ketika dialog terbuka. Tidak boleh muncul sukses palsu.
   Setelah koneksi pulih, muat ulang status untuk memastikan keadaan aktual.
8. Uji Flutter: mulai tes v1, aktifkan v2 di dashboard, selesaikan sesi v1. Tes baru
   memakai v2, sedangkan riwayat lama masih menampilkan paket v1.

## Verifikasi otomatis

Dari `admin/`: `npm test` dan `npm run build`.

Dari root dengan Java 21, emulator tes terpisah (9199/8180):

```powershell
firebase emulators:exec --config firebase.admin-test.json --only auth,firestore --project demo-teencu "node --test --test-concurrency=1 --test-skip-pattern=PowerShell test/firestore/*.test.mjs admin/tests/mbtiRepository.emulator.test.mjs"
```

Tes SDK memeriksa publish tanpa aktivasi, timestamp, draft yang berubah, larangan
edit published, draft tidak dapat diaktifkan, konflik pointer/ABA, pemilihan kembali
versi lama, no-op untuk paket aktif, serta izin dicabut. Suite rules memeriksa
privasi history dan hasil versi lama setelah pointer berubah. Tes publisher
PowerShell dilewati pada port terpisah seperti dijelaskan di panduan bank.
Uji Flutter lintas perangkat dan gangguan jaringan UI tetap merupakan uji manual.
