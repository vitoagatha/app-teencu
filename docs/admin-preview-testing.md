# Pratinjau dan simulasi MBTI (tahap keenam)

## Penggunaan

- Pada detail paket draft/published, pilih **Pratinjau tes**.
- Dari editor, isi paket yang valid lalu pilih **Pratinjau tes**. Perubahan belum
  tersimpan ditandai dengan peringatan. Pratinjau mengambil salinan data editor
  saat dibuka, termasuk urutan pertanyaan dan arahnya.
- Pilih jawaban 1–5 per soal. Berikutnya aktif setelah soal dijawab, Sebelumnya
  mempertahankan jawaban. Hitung hasil aktif ketika semua soal terjawab.
- Hasil menampilkan tipe dan skor EI/SN/TF/JP. Jika ada skor nol, hasil dinyatakan
  masih seimbang, dimensi disebutkan, dan tipe empat huruf tidak dipaksakan.
- **Tinjau jawaban** kembali ke soal pertama dengan jawaban tetap. **Ulangi simulasi**
  membersihkan seluruh jawaban percobaan. **Kembali dari pratinjau** menutup simulasi
  dan mempertahankan form editor, termasuk isian yang belum disimpan.
- Jawaban simulasi dibuang ketika pratinjau ditutup. Navigasi workspace/logout
  tetap mengikuti peringatan perubahan editor. Role dicabut tetap menutup workspace.

Pratinjau tidak mengimpor repository atau SDK Firebase dan tidak menyimpan jawaban,
hasil, profil, history, XP, atau pointer aktif. Pembacaan data detail dan listener
izin admin yang sudah ada tetap berjalan sesuai alurnya. Publish/aktivasi belum
termasuk tahap ini.

## Validasi dan algoritma

Pratinjau mensyaratkan paket valid sesuai kontrak Flutter (ID, teks, metadata,
4–80 soal, empat dimensi). Editor menjelaskan alasan tombol belum aktif.
Versi scoring tetap `teencu-centered-v1`: kontribusi `(jawaban - 3) * arah`, arah
E/S/T/J positif dan I/N/F/P negatif. Semua jawaban harus bilangan bulat 1–5,
ID lengkap tanpa tambahan. Ini implementasi algoritma aplikasi, bukan klaim
validasi psikometrik atau diagnosis.

## Pengujian

`test/fixtures/mbti-scoring-cases.json` digunakan tes JavaScript dan Dart yang sama:
16 tipe, semua netral, satu dimensi seimbang, serta kelima rating pada masing-masing
delapan arah penilaian. Expected mencakup tipe, skor, dan dimensi seimbang.

```sh
# Dari admin/
npm test
npm run build
```

```sh
# Dari root Flutter
flutter test --no-pub test/mbti_scoring_test.dart test/mbti_scoring_parity_test.dart
```

Uji browser:

1. Login admin emulator dan buka draft yang valid.
2. Ubah judul/soal tanpa menyimpan, buka pratinjau. Pastikan peringatan perubahan
   lokal dan isi terbaru tampil. Keluar: perubahan editor tetap ada.
3. Pilih Netral untuk semua soal: hasil seimbang, skor empat dimensi nol.
4. Untuk seed v1, fixture ESTJ: `5,1,5,5,5, 5,5,5,5,1, 5,5,5,5,1, 5,5,1,1,5`.
   Tukar 1/5 menghasilkan INFP. Pastikan skor sesuai fixture bersama.
5. Tinjau jawaban, kembali/maju, ganti jawaban dan hitung ulang. Ulangi simulasi:
   jawaban kosong, tombol berikutnya terkunci sampai dipilih.
6. Buka pratinjau published: tetap tidak ada akses mengedit paket published.
7. Setelah simulasi, paket, pointer aktif, dan riwayat pengguna tidak berubah.
   Tidak perlu deploy rules baru untuk tahap ini.
