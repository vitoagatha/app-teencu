# Verifikasi perbaikan UI/UX admin

Lingkup mengacu pada `ui-ux-audit.md`: editor (U1–U2, C2), daftar (U3, U5, C5), status dan tindakan (U4, C1, C3), fokus (U6), kontras (U7), skor dan konsistensi (C4, D1–D2). API repository, scoring, rules dan skema Firebase tidak diubah.

## Pemeriksaan otomatis

- `npm run build --prefix admin`
- `npm test --prefix admin`: 81 tes yang sudah ada untuk akses, bank dan scoring.
- `git diff --check`

Build memberi peringatan ukuran bundle yang sudah ada. Tes unit ini tidak membuktikan hasil layout atau interaksi DOM. Pemeriksaan browser untuk implementasi ini belum dilakukan; ukuran pada laporan audit merupakan bukti sebelum perbaikan.

## Pemeriksaan manual pada emulator

1. Pada desktop 1366×768, tablet 820×1180 dan ponsel 390×844, buka daftar. Pastikan paket dapat dibuka lewat judul tanpa geser tabel ke kanan. Header ponsel menyediakan identitas melalui Akun.
2. Buat draft atau buka draft contoh 20 soal. Buka soal melalui ringkasan atau Lompat ke soal; ubah soal pertama lalu terakhir. Bilah simpan/status harus terjangkau. Pada layar pendek bilah kembali ke aliran dokumen agar tidak menutupi field.
3. Kosongkan soal 17. Pesan menyebut nomor soal; Ke bagian yang perlu diperbaiki membuka soal dan memfokuskan textarea. Simpan tetap nonaktif selama data tidak valid.
4. Hapus satu soal, lalu Urungkan hapus. Isi dan posisi kembali. Hanya penghapusan terakhir yang bisa diurungkan. Setelah memuat ulang baseline server, undo lokal dibersihkan.
5. Simpan perubahan valid; buka pratinjau lalu kembali. Isi editor bertahan, breadcrumb sesuai layar, fokus kembali ke tombol pratinjau. Navigasi meninggalkan draft masih meminta konfirmasi.
6. Buka paket terbit yang aktif: tampilkan Dipakai untuk tes baru tanpa tombol aktivasi ulang. Gagalkan pembacaan status: tampilkan status belum diketahui dan muat ulang. Paket terbit yang tidak aktif tetap melalui dialog konfirmasi sebelum aktivasi.
7. Pada draft, Edit pertanyaan muncul sebelum publikasi. Publikasi tetap tidak mengubah versi aktif. Batal di dialog tidak menulis data. Salin sebagai draft mengarahkan ke form yang sama; setelah simpan tetap detail salinan lalu tombol Edit yang sudah ada.
8. Uji Tab/Shift+Tab, tautan Langsung ke konten, fokus judul, Escape dan pengembalian fokus modal. Pastikan bilah simpan tidak menutupi field/fokus pada zoom 200%.
9. Dengan lebih dari 20 paket, pindah ke halaman dua lalu Muat ulang data: halaman tetap dipertahankan. Daftar awal kosong menyediakan Buat draft baru.
10. Periksa hasil empat skor: kolom dimensi setara, tanda positif/negatif dan hasil seimbang tetap sama. Ukur ulang kontras tombol sekunder pada putih dan abu muda.
