# Audit dan perbaikan scoring MBTI

Tanggal: 24 Oktober 2026. Versi algoritma: `teencu-centered-v1`.
Lingkup: 20 soal lokal yang sudah ada, arah skor, netral, skor seimbang,
validasi jawaban, dan integrasi penyelesaian tes. Konten/deskripsi tipe masih
menggunakan materi lama. Belum ada bank soal cloud atau riwayat sesi.

## Temuan audit arah soal

Huruf di tabel adalah sisi yang didukung ketika pengguna SETUJU dengan soal.
Nomor 1-20 merujuk urutan tampilan, bukan indeks kode lama yang dimulai dari 0.

| No. / ID | Inti pernyataan | Arah lama | Arah benar menurut teks | Perubahan |
|---|---|---|---|---|
| 1 / q01 | Berenergi di acara sosial | E | E | Tetap |
| 2 / q02 | Menyendiri untuk menyegarkan pikiran | E | I | Dibalik |
| 3 / q03 | Berbicara untuk memecahkan masalah | I | E | Dibalik |
| 4 / q04 | Lebih banyak berbicara | E | E | Tetap |
| 5 / q05 | Nyaman di kelompok besar | E | E | Tetap |
| 6 / q06 | Detail konkret dibanding ide abstrak | N | S | Dibalik |
| 7 / q07 | Fokus masa kini | N | S | Dibalik |
| 8 / q08 | Mengandalkan fakta | N | S | Dibalik |
| 9 / q09 | Memperhatikan detail kecil | N | S | Dibalik |
| 10 / q10 | Gambaran besar dibanding detail | N | N | Tetap |
| 11 / q11 | Keputusan berdasarkan logika/fakta | F | T | Dibalik |
| 12 / q12 | Keadilan dibanding menjaga perasaan | F | T | Dibalik |
| 13 / q13 | Konsekuensi logis | F | T | Dibalik |
| 14 / q14 | Penyelesaian dibanding dampak emosional | F | T | Dibalik |
| 15 / q15 | Mempertimbangkan perasaan semua pihak | T | F | Dibalik |
| 16 / q16 | Merencanakan sebelumnya | P | J | Dibalik |
| 17 / q17 | Nyaman dengan jadwal/struktur | P | J | Dibalik |
| 18 / q18 | Fleksibilitas dibanding jadwal kaku | J | P | Dibalik |
| 19 / q19 | Menunda hingga tenggat | P | P | Tetap |
| 20 / q20 | Cepat mengambil keputusan/menuntaskan | J | J | Tetap |

Total 14 arah terbalik diperbaiki. Kode lama juga menyamakan bobot jawaban 4
(Setuju) dan 5 (Sangat Setuju), serta memasukkan 3 (Netral) ke salah satu sisi.
Contohnya, seluruh jawaban Netral menghasilkan ISTJ pada kode lama.

## Aturan yang diterapkan

Setiap soal menyimpan ID tetap, teks, dan `agreeWith` (sisi yang didukung setuju).
Dimensi berasal dari sisi tersebut, sehingga soal tidak harus berada pada indeks
tertentu untuk dihitung dengan benar.

| Rating | Makna | Kontribusi ke sisi agreeWith |
|---|---|---|
| 1 | Sangat Tidak Setuju | -2 |
| 2 | Tidak Setuju | -1 |
| 3 | Netral | 0 |
| 4 | Setuju | +1 |
| 5 | Sangat Setuju | +2 |

Rumus: `(rating - 3) * direction`, dengan direction +1 untuk E/S/T/J dan -1
untuk I/N/F/P. Jumlahkan per dimensi EI, SN, TF, JP. Dengan lima soal per dimensi,
skor berada pada -10 sampai +10. Positif memilih E/S/T/J, negatif I/N/F/P.
Skor bukan persentase atau ukuran kepastian psikologis.

Skor 0 berarti belum ada kecenderungan pada dimensi itu. Scorer mengembalikan
`type: null` beserta daftar dimensi seimbang. Aplikasi menampilkan penjelasan,
menawarkan tinjauan mulai soal pertama di dimensi seimbang, dan tidak menulis
hasil atau menimpa profil. Pengguna tidak perlu dipaksa memilih jawaban tertentu.
Jawaban sebelumnya tetap terpilih ketika berpindah halaman.

Sebelum menghitung, scorer menolak jawaban kurang/berlebih, ID tidak dikenal,
nilai di luar 1-5, ID soal duplikat/kosong, bank kosong, dan dimensi tanpa soal.

## Struktur kode

- `lib/model/mbti_question.dart`: dimensi, sisi preferensi, dan model soal.
- `lib/data/mbti_questions.dart`: 20 soal asli dan pemetaan hasil audit.
- `lib/services/mbti_scoring.dart`: perhitungan Dart murni tanpa Flutter/Firebase.
- `lib/question_mbti.dart`: form jawaban, tinjauan dimensi seimbang, simpan dan hasil.
- `test/mbti_scoring_test.dart`: pemetaan per soal untuk seluruh rating, 16 tipe,
  netral, tie, bobot, urutan soal, serta input tidak valid.
- `test/mbti_question_test.dart`: jawaban wajib, tinjauan, gagal simpan/retry,
  dan navigasi hasil setelah penyimpanan selesai.

Penyimpanan tetap memakai lastMbti dan lastMbtiDate sesuai rules yang ada.
Label scoringVersion baru berada di kode; riwayat dan penyimpanan versi akan
memerlukan desain data pada tahap berikutnya. Hasil lama tidak dihitung ulang
karena implementasi lama tidak menyimpan jawaban individual. Untuk memakai
perhitungan baru, pengguna mengikuti tes ulang.

## Catatan materi untuk tahap konten

Audit ini menyelaraskan aturan program dengan makna soal, belum menetapkan
validitas psikometri instrumen. Dari pembacaan teks, q08 mencampurkan istilah
intuisi/perasaan, q12 memakai konsep keadilan, dan q19/q20 mengaitkan kebiasaan
menunda/kecepatan dengan preferensi. Materi itu layak ditinjau tersendiri.
Jumlah soal searah juga belum seimbang: EI, SN, TF masing-masing 4:1; JP 3:2.

## Verifikasi

Jalankan `flutter test --no-pub` untuk tes scoring, widget MBTI, dan regresi auth.
Tidak perlu deploy rules atau mengganti konfigurasi Firebase untuk perubahan ini.

Uji manual:

1. Ikuti tes dan jawab Netral untuk semua soal. Harus tampil dimensi seimbang;
   profil tidak boleh ditimpa. Pilih Tinjau jawaban dan pastikan pilihan tersimpan.
2. Sebagai fixture perhitungan ESTJ, gunakan rating:
   `5,1,5,5,5, 5,5,5,5,1, 5,5,5,5,1, 5,5,1,1,5`.
   Hasil yang ditampilkan/disimpan harus ESTJ. Ini fixture teknis, bukan arahan
   jawaban untuk pengguna sesungguhnya.
3. Lakukan tes ulang dengan kebalikan fixture (rating 1 ditukar 5); hasil INFP.
4. Uji gagal simpan/koneksi: tetap di soal terakhir, jawaban tersedia, dan tombol
   selesai bisa dicoba lagi. Profil berubah setelah penyimpanan berhasil.
