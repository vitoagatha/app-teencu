# Audit UI/UX dashboard admin Teencu

14 November 2026 · Cabang `update/teencu`, revisi `d507367` · Lingkup: aplikasi web di `admin/`.

## 1. Ringkasan eksekutif

Dashboard ini adalah meja kerja penyunting soal. Tiga keputusan yang perlu dimudahkan adalah **paket mana yang dipakai tes baru**, **pertanyaan mana yang harus diperbaiki**, dan **kapan sebuah draft aman dipublikasikan**. Dasar produknya sudah mendukung ketiganya: status ditulis dengan kata, simulasi terpisah dari data pengguna, dan publikasi berbeda dari aktivasi.

Hambatan terbesar justru terlihat pada pekerjaan sehari-hari. Pada draft contoh 20 soal, tombol **Simpan draft** berada sekitar 8.339 px dari atas dokumen. Pada daftar versi di ponsel, admin bisa melihat nama paket tetapi harus menggeser tabel untuk membuka detail. Pada paket yang sudah aktif, tombol utama tetap menyarankan aktivasi. Ketiganya layak didahulukan daripada mengganti tema.

**Metode.** Inspeksi sumber, komponen CoreUI, CSS, dependensi, serta browser lokal dengan akun demo dan data Firebase Emulator. Login, daftar, detail aktif, dialog aktivasi (dibatalkan), pratinjau pertanyaan, serta editor draft dibuka. Daftar yang sama dibandingkan pada tiga ukuran viewport. Tidak ada penyimpanan, publikasi, aktivasi, perubahan kode aplikasi, atau pengujian cloud. Angka posisi di bawah adalah pengukuran DOM dalam CSS px, dibulatkan, dengan tiga paket contoh; bukan estimasi waktu pengguna.

## 2. Penilaian desain saat ini

- **Arsitektur.** [Paket admin](../admin/package.json) memakai React/JSX, Vite, CoreUI React 5, ikon CoreUI dan Firebase Web. [Entry point](../admin/src/main.jsx) memuat stylesheet CoreUI lalu override Teencu. [App](../admin/src/App.jsx) dan [RequireAdmin](../admin/src/auth/RequireAdmin.jsx) mengatur akses; [BankWorkspace](../admin/src/components/BankWorkspace.jsx) memilih layar menggunakan state React. Rekomendasi tidak bergantung pada penggantian router, library, skema data, atau rules.
- **Bahasa visual.** Sidebar gelap, aksen plum Teencu, latar abu muda, panel putih, sans-serif bawaan, judul tebal, serta tombol primer isi dan sekunder garis. Gradien halus terlokalisasi pada login. Ikon menu/keluar punya fungsi; status Draft, Published, dan Aktif juga terbaca tanpa mengandalkan warna.
- **Alur inti.** Admin masuk → memilih paket atau membuat draft → menyunting → mencoba simulasi → memublikasikan → memilih versi untuk tes baru. Untuk merevisi paket terkunci, salin menjadi draft → lihat detail salinan → pilih tombol **Edit pertanyaan** yang sudah ada. Pertahankan alur ini. Tidak ada alasan menambah tombol edit kedua.
- **Penyajian data.** Tabel tepat untuk membandingkan versi; daftar berurutan tepat untuk soal; empat skor bertanda dan penjelasan hasil seimbang lebih berguna daripada grafik tambahan. Tidak ditemukan deretan KPI buatan, grafik dekoratif, glassmorphism, atau animasi dekoratif yang perlu dihapus dari alur yang ditinjau.

## 3. Indikator tampilan generik

Istilah ini menilai kegunaan pola, bukan menyimpulkan siapa yang membuat desain. Bukti, tingkat, solusi dan dampak dijabarkan pada ID terkait di bawah.

| Pola yang terlihat | Mengapa terasa generik di Teencu | Keputusan |
|---|---|---|
| Label pengelolaan di sidebar, header dan pengantar sebelum H1 (U3) | Mengulang lokasi, sementara pengguna belum melihat satu pun paket. | Pertahankan judul dan navigasi; beri ruang layar pertama kepada data. |
| Setiap pertanyaan menjadi kartu lengkap (U1) | Pemisah soal berguna, tetapi 20 kartu terbuka membuat sunting satu kalimat menjadi perjalanan panjang ke tombol simpan. | Pertahankan nomor dan pengelompokan; ringkas soal yang tidak sedang diedit. |
| Blok publikasi dan tombol primer seragam pada detail (U4) | Tata letak tampak lengkap, tetapi tindakan paling menonjol bahkan ditawarkan saat tujuan sudah tercapai. | Tentukan tindakan dari status paket dan pekerjaan berikutnya. |
| Kartu aktif, dialog konfirmasi, badge lingkungan | Masing-masing menjawab pertanyaan nyata: versi mana, apa akibatnya, di mana saya bekerja? | Pertahankan; sesuaikan kepadatan dan teks. Menghapus semua kartu atau warna justru mengurangi informasi. |

## 4. Temuan UI/UX

**Severity:** High = menghambat pekerjaan inti atau akses berulang; Medium = konteks, efisiensi, atau keterbacaan berkurang tetapi tersedia jalan lain; Low = inkonsistensi lokal. Tidak ditemukan Critical dalam ruang lingkup yang diperiksa. **Browser** = diamati saat sesi audit; **kode** = disimpulkan dari implementasi, tidak direproduksi kecuali dinyatakan.

| ID / tingkat | Komponen dan bukti | Masalah dan akibat | Perubahan yang disarankan → dampak |
|---|---|---|---|
| U1 · High | **Browser + kode.** [BankEditorPage](../admin/src/pages/BankEditorPage.jsx), sekitar baris 79, 89, 100–104. Draft 20 soal: 20 textarea, tinggi dokumen 8.466 px, Simpan pada y≈8.339 di desktop. | Edit soal pertama tetap memerlukan gulir ke akhir. Status perubahan dan pratinjau di atas, simpan dan hasil simpan di bawah. | Pindahkan satu bilah simpan/status ke lokasi yang tetap terjangkau. Ringkas soal lain menjadi nomor, cuplikan teks dan arah skor; sediakan buka/tutup dan lompat ke soal. Uji satu perubahan pada soal pertama dan terakhir tanpa kehilangan posisi. |
| U2 · High | **Kode.** [BankEditorPage](../admin/src/pages/BankEditorPage.jsx) 26–27, 79, 101–104; [validateBank](../admin/src/domain/mbtiBank.js) memunculkan kesalahan pertama, misalnya teks kosong tanpa nomor soal. | Simpan dan pratinjau nonaktif; pesan global tidak menunjukkan textarea mana di antara puluhan soal yang harus diisi. | Tautkan pesan ke field atau nomor soal, tampilkan pesan setempat saat relevan, sertakan aksi “Ke soal yang perlu diperbaiki”. Hubungkan pesan ke input untuk pembaca layar. Admin dapat memperbaiki kesalahan tanpa menelusuri semua kartu. Pertahankan validasi domain sebagai syarat simpan. |
| U3 · Medium | **Browser + kode.** [OverviewPage](../admin/src/pages/OverviewPage.jsx) 17–27, [BankListPage](../admin/src/pages/BankListPage.jsx) 18–22, [styles.css](../admin/src/styles.css) 37–48. Di desktop 1366×768, baris data pertama mulai y≈779. | Pengantar, blok versi aktif, tombol muat ulang tersendiri dan dua penjelasan daftar memakai layar pertama. Admin harus menggulir untuk menemukan draft. | Gabungkan judul + Buat draft; ringkas versi aktif menjadi ringkasan yang tetap dapat dibuka. Letakkan muat ulang bersama kontrol daftar dan gunakan “Halaman 1 · 3 paket” untuk hitungan lokal. Target: satu baris paket terlihat tanpa gulir di desktop uji. |
| U4 · Medium | **Browser + kode.** [BankDetailPage](../admin/src/pages/BankDetailPage.jsx) 23, 58–65; [PublicationActions](../admin/src/components/PublicationActions.jsx) 42–56. Badge “Aktif” dan tombol “Aktifkan versi ini” terlihat bersamaan; dialog menjelaskan tidak ada perubahan. Jika pembacaan status gagal, detail mengisi `null` tanpa pesan. | UI menyarankan tindakan tanpa manfaat; tidak adanya badge juga belum membedakan “tidak aktif” dari “belum diketahui”. Pada draft, publikasi lebih dahulu muncul daripada edit. | Bedakan sedang diperiksa, aktif, tidak aktif dan gagal diperiksa. Aktif terkonfirmasi → “Dipakai untuk tes baru”; gagal → “Status aktif belum diketahui · Coba lagi”. Tonjolkan Edit pada draft; tawarkan Aktivasi pada versi terbit yang belum aktif. Pertahankan pembacaan ulang dan konfirmasi transaksi. |
| U5 · High | **Browser + kode.** [BankListPage](../admin/src/pages/BankListPage.jsx) 22–28; [styles.css](../admin/src/styles.css) 46–48. Pada 390 px, tabel ≈578 px di area ≈310 px; tombol Detail pertama mulai x≈517. | Nama paket terlihat tetapi aksi utamanya tersembunyi di ujung kanan. Halaman tidak meluber; hambatan terdapat di dalam tabel. | Jadikan judul paket kontrol pembuka detail yang dapat difokuskan, atau tampilkan baris ringkas judul–versi–status pada lebar sempit. Taruh tanggal lengkap di detail. Hilangkan aksi duplikat jika judul sudah dapat dibuka. Admin bisa memilih paket tanpa menggeser ke samping. |
| U6 · Medium | **Browser + kode.** [BankWorkspace](../admin/src/components/BankWorkspace.jsx) 15–23, 40–44; [BankPreviewPage](../admin/src/pages/BankPreviewPage.jsx) 18–23. Breadcrumb tetap “Detail paket” saat judulnya “Pratinjau tes MBTI”. Setelah membuka editor dari detail, fokus yang terukur adalah `BODY`. | Pengguna keyboard atau pembaca layar kehilangan penanda perpindahan. Main sudah punya ID tetapi tidak ada tautan lewati navigasi. | Sinkronkan breadcrumb saat pratinjau; fokuskan judul layar saat berpindah, kembalikan fokus ke pemicu saat kembali, tambahkan “Langsung ke konten”. Tetap gunakan penjaga perubahan draft. |
| U7 · Medium | **Browser + perhitungan.** Tombol Kembali dan Pratinjau tes di editor memakai teks efektif `#6b7785` pada latar workspace `#f3f4f7`, latar tombol transparan: ≈4,15:1. Pada permukaan putih pasangan teks yang sama ≈4,56:1. Lihat [styles.css](../admin/src/styles.css) 2, 22, 35. | Tombol sekunder aktif di workspace di bawah target audit 4,5:1 untuk teks biasa dan tampak redup. Menguji komponen di kartu putih saja melewatkan masalah. | Gelapkan teks outline sekunder atau beri latar solid yang sesuai. Verifikasi normal, hover dan fokus pada kedua permukaan; ukur tombol **aktif** terpisah dari disabled. |

## 5. Masalah pada tingkat komponen

| ID / tingkat | Komponen dan bukti | Masalah | Rekomendasi dan dampak |
|---|---|---|---|
| C1 · Medium | **Browser + kode.** [BankDetailPage](../admin/src/pages/BankDetailPage.jsx) 60–71: keterangan paket terkunci dekat atas, form salin setelah seluruh daftar soal. | Untuk membuat revisi dari paket terbit, admin membaca instruksi di atas tetapi baru menemukan form setelah 20 soal pada contoh. | Beri satu aksi “Salin sebagai draft” di dekat status terkunci yang membuka atau memfokuskan form yang sama. Setelah simpan tetap menuju detail salinan, dengan satu tombol Edit. |
| C2 · Medium | **Kode.** [BankEditorPage](../admin/src/pages/BankEditorPage.jsx) 94–97: Hapus memfilter pertanyaan seketika, bersebelahan dengan Naik dan Turun. | Salah tekan sebelum simpan menghilangkan isi soal dari draft lokal. Memuat ulang dapat mengorbankan edit lain. | Sediakan “Urungkan hapus soal N” yang mengembalikan isi dan posisi. Pertahankan operasi lokal sampai Simpan; mengurangi kehilangan kerja tanpa dialog pada setiap perubahan urutan. |
| C3 · Low | **Kode.** [BankListPage](../admin/src/pages/BankListPage.jsx) 20–22 dan [PublicationActions](../admin/src/components/PublicationActions.jsx) 50–56. Error daftar menyebut “rules Firestore”; dialog menggunakan “pointer”; antarmuka mencampur “Publish”, “Published”, dan “Dipublikasikan”. | Detail teknis tidak membantu admin konten memulihkan akses atau mengambil keputusan. | Gunakan “Terbitkan”, “Terbit”, “Aktif untuk tes baru”. Pada kegagalan: “Daftar belum dapat dimuat. Coba lagi; jika tetap gagal, hubungi pengelola akses.” Simpan istilah teknis untuk dokumentasi dukungan. |
| C4 · Low | **Kode.** [BankPreviewPage](../admin/src/pages/BankPreviewPage.jsx) 24–32 memakai `.bank-meta` dengan empat grup; [BankDetailPage](../admin/src/pages/BankDetailPage.jsx) memakai kelas sama untuk pasangan label/nilai; grid [styles.css](../admin/src/styles.css) 50 mengasumsikan kolom label sempit. | Pada hasil simulasi, dua kolom berisi dimensi yang sederajat tetapi mendapat alokasi lebar berbeda. | Gunakan daftar empat pasangan “Dimensi / Skor” atau grid setara khusus hasil. Pertahankan tanda +/−, keterangan nol dan hasil seimbang. Verifikasi hasil panjang pada ponsel sebelum mengubahnya. |
| C5 · Medium | **Kode.** [OverviewPage](../admin/src/pages/OverviewPage.jsx) 26–27 mengganti `key` daftar saat muat ulang; cursor [BankListPage](../admin/src/pages/BankListPage.jsx) dimulai dari halaman satu saat komponen dibuat. | Admin yang menyegarkan dari halaman lanjut kehilangan konteks. Saat paket kosong, petunjuk hanya “Belum ada paket pada halaman ini”. | Bedakan segarkan halaman saat ini dari kembali ke terbaru; jika cursor tidak lagi berlaku, beritahu bahwa daftar direset. Pada daftar awal kosong arahkan ke aksi Buat draft yang sudah ada. Uji dengan lebih dari 20 paket; kasus ini tidak tersedia pada sesi browser. |

## 6. Inkonsistensi sistem desain

| ID / tingkat | Bukti dan masalah | Aturan yang disarankan dan dampak |
|---|---|---|
| D1 · Low | **Kode.** [styles.css](../admin/src/styles.css) 14–22, 37–48: jarak label dan submit diterapkan ke seluruh form; margin 24 px di tiap grup aksi lalu dibatalkan di beberapa komponen dengan utility. Aksen merek diulang pada beberapa selector. | Pertahankan variabel CoreUI; tetapkan peran warna merek, teks sekunder, permukaan dan fokus, serta skala jarak 4/8/12/16/24 px. Bedakan jarak antar-field, antar-aksi, dan antar-bagian. Terapkan pertama pada editor dan daftar agar perubahan login tidak ikut menggeser editor. |
| D2 · Low | **Browser + kode.** [BankWorkspace](../admin/src/components/BankWorkspace.jsx) 26–41 dan [OverviewPage](../admin/src/pages/OverviewPage.jsx) 17: judul konteks berulang, termasuk eyebrow kapital 11 px; header mobile menjadi dua baris pada 390 px, email disembunyikan. | Pertahankan satu H1 per layar, H2 untuk kelompok kerja, label biasa untuk metadata. Di header sempit utamakan menu, lingkungan dan akun; sediakan identitas akun melalui menu. Gunakan aksen plum untuk tindakan utama; warna status selalu ditemani kata. |

## 7. Aksesibilitas dan responsivitas

Pengukuran berikut diambil pada daftar yang sama, posisi gulir awal. Banner bawah Firebase Emulator terlihat dalam sesi lokal; jangan menganggapnya bagian dari pengalaman cloud.

| Viewport | Observasi browser |
|---|---|
| Desktop 1366 × 768 | Sidebar tetap; tabel dan wadah sama-sama ≈990 px. Baris pertama mulai y≈779. Tombol detail muat secara horizontal. |
| Tablet 820 × 1180 | Tabel ≈699 px, muat dalam wadah ≈699 px. Baris pertama mulai y≈769 dan terlihat pada layar ini. |
| Ponsel 390 × 844 | Header membungkus; baris pertama mulai y≈869. Tabel lebih lebar daripada wadah; lebar dokumen sendiri sama dengan area klien. |

**Yang sudah baik:** login memiliki label dan autocomplete, status sibuk dan pesan gagal; editor punya label dan nama aksi urutan yang menyebut nomor soal. Pratinjau memakai radio native dalam fieldset/legend. Dialog aktivasi memiliki nama, tombol Batal, dan penjelasan dampak pada tes baru. Ada gaya fokus global. Satu langkah Tab dari Kembali menuju Pratinjau terverifikasi di editor; ini belum membuktikan seluruh alur keyboard.

**Batas bukti dan uji lanjutan:** temuan bertanda kode tidak dianggap hasil uji pengguna. Belum dilakukan uji pembaca layar, zoom 200%, perangkat sentuh fisik, semua status jaringan/akses, fokus terperangkap dan kembali dari modal, ataupun tema kontras tinggi. Saat implementasi, periksa urutan Tab/Shift+Tab dan Escape pada menu/modal, pengumuman soal baru dalam simulasi, serta keterbacaan feedback error/sukses. Pastikan bilah simpan yang diusulkan tidak menutup field terakhir atau indikator fokus pada layar pendek.

## 8. Arah visual yang disarankan

Pertahankan **CoreUI dan identitas plum Teencu**. Gunakan ruang terbesar untuk objek yang dikerjakan: pada daftar, tampilkan paket dan status; pada editor, tampilkan teks soal dan arah skornya; pada konfirmasi, tampilkan versi asal, tujuan, serta akibat tindakan. Logo, tagline pada login dan badge lingkungan sudah cukup memberi identitas.

Pada detail draft, urutkan **Edit pertanyaan → Pratinjau → Terbitkan**. Pada detail versi terbit, jelaskan apakah versi sedang dipakai dan mudahkan membuat revisi. Simpan penjelasan tentang paket terkunci tepat di tempat admin memutuskan untuk menerbitkan atau menyalin. Pertahankan konfirmasi terpisah untuk aktivasi. Jangan mengganti empat skor dengan grafik, menambah KPI global dari satu halaman data, atau membuat menu kosong agar sidebar tampak penuh.

## 9. Rencana perbaikan berprioritas

| Urutan | Perubahan pertama yang dapat dirilis sendiri | Kriteria selesai |
|---|---|---|
| 1. Editor yang dapat disimpan dan dikoreksi dari mana saja | U1–U2: bilah simpan/status dan error per-field dahulu; baru ringkas soal serta tambah undo (C2). | Pada paket 20 soal, admin dapat menyimpan edit soal 1 tanpa pergi ke akhir. Kosongkan soal 17: UI menunjuk soal 17 dan fokus dapat menuju field-nya. Pratinjau, konflik simpan dan perlindungan draft tetap berlaku. |
| 2. Daftar yang langsung bisa dipakai, termasuk di ponsel | U3, U5, U7: ringkas bagian atas, pindahkan akses detail ke judul, perbaiki kontras sekunder. | Pada 1366×768 ada data pada layar awal. Pada 390×844 paket dapat dibuka tanpa geser horizontal. Tablet tetap mudah untuk membandingkan versi; tombol aktif terbaca pada abu dan putih. |
| 3. Tindakan yang sesuai status dan perpindahan layar yang jelas | U4, U6, C1, C3: bedakan aktif/tidak diketahui, utamakan aksi per status, arahkan ke salinan, perbaiki fokus dan istilah. | Paket aktif tidak meminta aktivasi ulang; gagal membaca status tidak terlihat seperti “tidak aktif”. Pratinjau dikenali lewat judul/breadcrumb. Salin → detail salinan → Edit tetap satu jalur. Publikasi tidak mengaktifkan paket dan Batal tidak mengubah data. |

Setelah tiga perubahan ini, lanjutkan C4–C5 dan konsolidasikan aturan D1–D2 saat menyentuh komponen terkait. Bandingkan ulang dengan ukuran layar dan contoh paket yang sama. Audit ini tidak mengubah implementasi.
