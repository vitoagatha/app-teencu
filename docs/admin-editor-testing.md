# Editor draft pertanyaan (tahap kelima)

Dashboard kini dapat membuat draft baru dan mengedit draft yang sudah disimpan.
Pada detail paket draft pilih **Edit pertanyaan**. Paket published tetap terkunci;
gunakan Salin menjadi draft baru untuk membuat versi berikutnya.
Tombol **Simpan salinan draft** menyimpan salinan lalu membuka detail draft baru.
Gunakan **Edit pertanyaan** di atas untuk mengeditnya. Jika penyalinan gagal,
form tetap terbuka dengan pesan error.

## Perilaku

- ID paket baru diisi saat membuat draft; ID paket tersimpan tidak dapat diubah.
- Judul dan label versi dapat diubah pada draft. Algoritma tetap `teencu-centered-v1`.
- Pertanyaan dapat ditambah, dihapus, dan dipindah Naik/Turun. ID pertanyaan tetap
  saat diurutkan/diedit; pertanyaan baru mendapat ID unik. Arah dipilih dari dropdown.
- Draft baru dimulai dengan empat pertanyaan kosong (E/S/T/J) di memori browser.
  Wajib mengisi teks dan metadata sebelum Simpan aktif. Jumlah 4–80 pertanyaan dan
  semua dimensi harus terwakili. `questionIds` selalu dihasilkan dari urutan soal.
- Simpan memakai transaksi. Draft dari tab lain yang sudah berubah menyebabkan
  konflik; tidak otomatis ditimpa. Baseline tetap sama pada retry transaksi.
- Muat ulang dari server membuang perubahan lokal setelah konfirmasi. Gunakan ini
  untuk meninjau perubahan admin lain sebelum mencoba mengedit lagi.
- Berpindah ke daftar/detail atau logout dari editor dengan perubahan lokal meminta
  konfirmasi. Refresh/tutup tab menggunakan peringatan browser jika didukung.
- Selama simpan, form dan navigasi internal dikunci. Kegagalan menyimpan mempertahankan
  isian. Jika hasil operasi tidak pasti, muat ulang untuk memeriksa keadaan server.
- Draft yang belum disimpan tidak dipulihkan setelah reload. Pencabutan izin tetap
  menutup workspace, walaupun editor memiliki perubahan lokal.
- Penyimpanan draft tidak mengubah versi aktif, hasil lama, profil, atau riwayat.

Belum mencakup pratinjau scoring, publish, atau aktivasi dari dashboard.
Tidak ada perubahan rules yang diperlukan di luar rules tahap keempat.

## Uji manual

1. Jalankan emulator dan seed sesuai [panduan bank](admin-bank-testing.md).
2. Login admin. Buka `demo-mbti-v2-draft` > Edit pertanyaan.
3. Ubah judul, teks, arah. Pindahkan soal pertama ke bawah. Simpan, lalu muat ulang:
   urutan, ID, dan isi tetap sesuai; tanggal pembuatan tidak berubah.
4. Tambah pertanyaan: teks kosong menonaktifkan Simpan. Isi teks, pilih arah, simpan.
   Hapus pertanyaan itu lalu simpan kembali. Jangan menghapus paket published.
5. Hapus hingga di bawah empat pertanyaan, atau hilangkan seluruh soal satu dimensi:
   ada pesan validasi dan Simpan nonaktif. Muat ulang untuk mengembalikan data server.
6. Ubah teks, klik Kembali/sidebar/logout: konfirmasi muncul. Batal mempertahankan
   editor; Setuju meninggalkan perubahan lokal. Uji refresh juga.
7. Buka draft yang sama di dua tab. Simpan perubahan di tab A, lalu simpan tab B:
   tab B mendapat pesan konflik dan tetap mempertahankan isian. Muat ulang di tab B
   untuk mengambil perubahan A. Jangan mengharapkan penggabungan otomatis.
8. Buka detail published: tidak ada tombol Edit pertanyaan, hanya pilihan salin.
9. Dari daftar, pilih Buat draft baru, isi ID unik/judul/versi dan empat teks soal.
   Simpan: kembali ke detail draft baru. ID duplikat ditolak tanpa overwrite.
10. Uji putus koneksi dan role dicabut seperti [panduan auth](admin-auth-testing.md).

## Tes otomatis

Dari `admin/`: `npm test` dan `npm run build`.

Tes SDK/rules memakai konfigurasi emulator terpisah, dari root dengan Java 21:

```powershell
firebase emulators:exec --config firebase.admin-test.json --only auth,firestore --project demo-teencu "node --test --test-concurrency=1 --test-skip-pattern=PowerShell test/firestore/*.test.mjs admin/tests/mbtiRepository.emulator.test.mjs"
```

Tes domain memeriksa snapshot isian, urutan/ID, fingerprint, dan validasi.
Tes SDK memeriksa simpan baru/update, konflik baseline lama, timestamp pembuatan,
published terkunci, ID bentrok, serta izin dicabut. Tes publisher PowerShell tetap
dilewati dalam konfigurasi port terpisah seperti dijelaskan pada panduan bank.
