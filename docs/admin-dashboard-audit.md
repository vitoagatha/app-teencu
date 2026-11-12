# Audit awal dan rancangan dashboard admin Teencu

Tanggal: 12 November 2026.

Status: tahap pertama selesai berupa audit kode dan rancangan implementasi.
Dashboard belum dibuat. Dokumen ini membedakan perilaku yang sudah tersedia dari
perubahan yang diusulkan; tidak mengubah aplikasi, rules, atau data Firebase.

## Cakupan dan sumber pemeriksaan

Audit dilakukan pada checkout `update/teencu`, commit `1a72f9b`, dengan working
tree bersih sebelum dokumen ini ditambahkan. Tidak melakukan pull atau perubahan
branch. Kondisi Firebase Console, daftar Web App, akun admin, dan rules yang aktif
di cloud tidak diverifikasi pada tahap ini.

Sumber utama:

- [Model bank soal](../lib/model/mbti_test.dart).
- [Model pertanyaan](../lib/model/mbti_question.dart) dan
  [scoring Flutter](../lib/services/mbti_scoring.dart).
- [Repository MBTI](../lib/services/mbti_repository.dart),
  [pemuat tes](../lib/mbti_test_page.dart), dan
  [detail riwayat](../lib/mbti_history_page.dart).
- [Auth aplikasi](../lib/services/auth_service.dart).
- [Firestore Rules](../firestore.rules).
- [Publisher PowerShell](../tools/Publish-MbtiBank.ps1).
- [Seed v1](../seed/mbti-v1.json).
- [Tes aturan MBTI](../test/firestore/mbti.test.mjs) dan
  [panduan bank soal](mbti-bank-and-history.md).
- [Konfigurasi Firebase](../firebase.json), [package root](../package.json),
  dan [.gitignore](../.gitignore).

## Kesimpulan

React + JavaScript + Vite dapat memakai kontrak data yang sudah digunakan Flutter.
Dashboard menggunakan Firebase Web SDK sebagai client biasa; akses tetap dibatasi
rules berdasarkan `content_admins`. Tidak membutuhkan server aplikasi baru untuk
cakupan pengelolaan bank soal ini.

Fondasi yang sudah tersedia: login email/password, izin admin konten, draft,
publikasi immutable, pointer versi aktif, bank soal berversi, dan riwayat privat.
Yang belum tersedia: proyek web admin, daftar paket untuk admin, editor browser,
pratinjau JavaScript, konfigurasi Web App, serta konfigurasi hosting dashboard.

## Kontrak data yang dipertahankan

| Lokasi | Isi dan penggunaan |
| --- | --- |
| `content_admins/{uid}` | `enabled: true` memberikan izin admin konten. Hanya pemilik akun dapat membaca dokumennya melalui client. Pemberian/pencabutan izin dilakukan melalui Console atau lingkungan tepercaya. |
| `mbti_tests/{testId}` | Satu dokumen untuk satu paket. Field persis: `title`, `version`, `scoringVersion`, `status`, `questions`, `questionIds`, `createdAt`, `publishedAt`. |
| `mbti_config/active` | Field persis: `testId`, `updatedAt`. Menunjuk satu paket published. Aktif bukan status tambahan pada paket. |
| `users/{uid}/mbti_results/{resultId}` | Riwayat privat milik pengguna. Dashboard admin konten tidak membacanya. |

Detail kontrak paket:

- `testId`: ID dokumen unik, pola `^[a-zA-Z0-9_-]{1,80}$` sesuai parser Flutter.
- `title`: bukan whitespace saja, maksimum 160 karakter.
- `version`: label bukan whitespace saja, maksimum 80 karakter. Label ini bukan
  ID dokumen; uniqueness global label belum dijamin oleh kode/rules saat ini.
- `scoringVersion`: tetap `teencu-centered-v1`, bukan pilihan bebas admin.
- `questions`: 4–80 objek `{id, text, agreeWith}`; ID unik dalam paket dan mengikuti
  pola ID yang sama; teks bukan whitespace saja dan maksimum 1.000 karakter.
- `agreeWith`: huruf besar `E/I/S/N/T/F/J/P`. Dimensi diturunkan dari huruf,
  bukan disimpan sebagai field tambahan. Keempat dimensi harus terwakili.
- `questionIds`: dihasilkan dari urutan `questions`, bukan diedit terpisah.
- `createdAt`: server timestamp saat membuat draft, tetap pada update.
- Draft: `status: draft`, `publishedAt: null`.
- Published: `status: published`, `publishedAt` server timestamp saat publish.
- Tidak menambahkan `updatedAt`, `updatedBy`, atau field lain ke paket pada MVP:
  rules saat ini menggunakan daftar field yang ketat.

Versi published tidak dapat diperbarui atau dihapus melalui client. Draft juga
belum boleh dihapus. Menghapus pertanyaan di editor berbeda dengan menghapus paket.
Console/Admin SDK dapat melewati rules; immutable di sini adalah batas client.

## Temuan audit dan keputusan rancangan

| Temuan pada kode saat ini | Dampak | Rancangan tahap implementasi |
| --- | --- | --- |
| `mbti_tests` hanya memiliki izin `get`, bukan `list`. | Admin belum dapat menampilkan daftar bank soal melalui query. | Tambahkan `list` khusus admin dengan batas query, misalnya maksimal 21 dokumen untuk halaman berisi 20 paket. Pengguna biasa tetap memakai `get` versi published. |
| Rules draft mensyaratkan 4–80 soal dan metadata terisi. | Draft kosong belum bisa disimpan ke cloud. | Pada MVP, form baru boleh kosong di memori browser, tetapi Simpan draft hanya aktif setelah validasi penuh lulus. Sediakan salin versi lama agar tidak mulai dari nol. |
| `validBank` memeriksa struktur luar, ukuran, dan keunikan daftar ID, tetapi belum semua elemen pertanyaan. | Client admin yang melewati validasi dapat menulis paket yang ditolak parser Flutter. | Validasi lengkap saat simpan dan publish; jelaskan batas kepercayaan admin. Jangan mengklaim rules memvalidasi seluruh isi soal. Penguatan validasi server memerlukan pekerjaan terpisah. |
| Tidak ada revision atau waktu update pada paket. | Dua tab/admin bisa saling menimpa jika memakai update biasa. | Simpan lewat transaksi, bandingkan isi dokumen dengan snapshot awal editor; bila berubah, hentikan dan minta muat ulang. Jangan otomatis menimpa versi terbaru. |
| Publisher memakai precondition `updateTime` untuk setiap write. | Sudah mencegah write berdasarkan dokumen basi pada langkah tersebut. Namun ada jeda antara menyimpan draft dan membaca ulang untuk publish. | Jika admin lain mengubah draft pada jeda itu, skrip dapat menerbitkan isi terbaru yang berbeda dari seed. Catat untuk perbaikan publisher saat dashboard mulai dipakai bersama; dashboard harus memvalidasi dan membandingkan isi yang telah ditinjau dalam transaksi publish. |
| Config yang tersimpan hanya menunjukkan aplikasi Android. | Belum ada config Web App yang dapat dipakai dashboard. | Periksa/daftarkan Web App pada project yang sama, lalu gunakan config web resminya. Ketiadaan config di repo tidak membuktikan Web App belum terdaftar di Console. |
| Package root hanya berisi dependency `firebase`; tidak ada proyek React. | Belum ada build/tooling dashboard. | Buat package dan lockfile tersendiri di `admin/`; jangan mengganti package root yang sudah ada. |
| `.gitignore` belum secara eksplisit mencakup hasil build dan konfigurasi lokal admin. | File lokal/build dashboard dapat ikut staging. | Pada setup tambahkan aturan `admin/node_modules/`, `admin/dist/`, dan environment lokal; tetap sertakan `.env.example`. |

Validasi browser bukan batas keamanan terhadap pemilik akun admin yang sengaja
mengirim request langsung. Rules tetap menjadi batas otorisasi dan imutabilitas;
admin konten dipercaya untuk isi bank soal dalam desain MVP saat ini.

## Rancangan akses dan alur data

1. Firebase Auth memulihkan sesi atau menerima login email/password.
2. Baca/listen dokumen `content_admins/{uid}` milik akun tersebut.
3. Hanya `enabled === true` membuka halaman admin. Bedakan belum login,
   menunggu pemeriksaan, akses ditolak, dan pemeriksaan gagal karena koneksi.
4. Tidak menyediakan registrasi atau perubahan role dari dashboard. Tidak perlu
   memanggil pembuatan profil Flutter untuk masuk sebagai admin.
5. Bila logout, sesi berubah, atau izin dicabut, bersihkan state privat dan listener.
   Rules tetap menolak operasi setelah izin dicabut meskipun UI belum diperbarui.
6. Repository admin hanya beroperasi pada bank soal, pointer aktif, dan pemeriksaan
   izin sendiri. Tidak menyediakan query seluruh profil atau riwayat pengguna.

Daftar awal memakai urutan `createdAt` menurun, cursor, dan limit 21 untuk
menampilkan 20 paket. Status paket dan penanda aktif ditampilkan di daftar.
Filter server berdasarkan status dapat menyusul dengan indeks yang sesuai;
MVP tidak memerlukan filter tersebut.

Ringkasan awal menampilkan paket aktif, jumlah soal aktif, dan jumlah paket pada
halaman yang dimuat. Jangan menamai hitungan satu halaman sebagai total seluruh
draft/published. Total global ditunda sampai desain agregasi dan rules-nya diuji.

## Alur editor, publikasi, dan aktivasi

- **Buat draft:** isi form lokal atau salin paket lama. Paket hasil salinan memakai
  `testId` baru; ID pertanyaan yang tetap sama boleh dipertahankan antarversi.
  Perubahan belum tersimpan tidak dijanjikan bertahan setelah reload browser.
- **Simpan:** validasi semua data, gunakan transaksi untuk memastikan ID baru belum
  ada atau dokumen lama masih draft dan cocok dengan snapshot awal editor.
  Transaksi yang diulang otomatis tetap membandingkan snapshot awal yang tetap.
- **Edit:** tambah/hapus/urutkan soal; arah dipilih dari dropdown. Setelah penghapusan,
  Simpan dinonaktifkan jika jumlah atau cakupan dimensinya tidak valid.
- **Pratinjau:** simulasi dari isi editor yang valid. Tampilkan bila masih ada
  perubahan belum disimpan. Tidak menulis hasil, profil, atau riwayat pengguna.
- **Publish:** hanya untuk draft tersimpan tanpa perubahan lokal. Validasi dokumen
  lagi dalam transaksi dan pastikan sama dengan isi yang telah ditinjau sebelum
  mengganti status dan mengisi `publishedAt`. Konflik menuntut peninjauan ulang.
- **Aktifkan:** tindakan terpisah setelah publish. Transaksi membaca paket tujuan
  dan pointer saat ini; pastikan target published dan pointer masih sesuai yang
  dilihat admin, lalu tulis `testId` dan `updatedAt` server timestamp. Jika pointer
  sudah berubah, minta konfirmasi ulang, bukan mengganti diam-diam.
- **Kegagalan jaringan:** pertahankan form dan tampilkan status yang jelas. Setelah
  hasil operasi tidak pasti, baca ulang server sebelum menawarkan retry. Jangan
  menampilkan sukses sebelum server mengonfirmasi.

Tes baru di Flutter membaca pointer aktif dan menyimpan snapshot paket dalam sesi.
Pergantian aktif tidak mengubah sesi yang sedang berlangsung. Detail riwayat
mengambil paket berdasarkan `testId` lama. Pengguna yang sudah mempunyai hasil
v1 tidak diwajibkan mengerjakan v2 dan tetap bisa mengakses chat.

## Kesetaraan scoring JavaScript dan Dart

Pratinjau perlu implementasi JavaScript terpisah karena kode Dart tidak langsung
diimpor React. Gunakan spesifikasi yang sama:

```text
kontribusi = (jawaban - 3) * arah
arah E/S/T/J = +1; arah I/N/F/P = -1
jawaban bilangan bulat 1..5
skor positif memilih E/S/T/J; negatif memilih I/N/F/P
salah satu dimensi nol -> hasil masih seimbang, tidak memaksakan empat huruf
```

Gunakan fixture JSON bersama untuk pengujian kedua implementasi: semua netral,
ESTJ, INFP, tie sebagian, arah tiap huruf, serta input tidak valid. Untuk seed v1:

```text
ESTJ: 5,1,5,5,5, 5,5,5,5,1, 5,5,5,5,1, 5,5,1,1,5
INFP: tukar 1 dan 5 pada urutan di atas
Seimbang: semua 3
```

Jangan menjadikan port JavaScript sebagai dasar perubahan algoritma mobile.
Scoring ini juga belum merupakan validasi psikometrik atau otorisasi reward.

## Struktur folder yang diusulkan

Struktur berikut adalah rancangan; folder dan file ini belum dibuat.

```text
admin/
  package.json
  package-lock.json
  vite.config.js
  index.html
  .env.example
  src/
    main.jsx
    App.jsx
    styles.css
    lib/firebase.js
    auth/AdminSessionProvider.jsx
    auth/RequireAdmin.jsx
    pages/LoginPage.jsx
    pages/AccessDeniedPage.jsx
    pages/OverviewPage.jsx
    pages/BankListPage.jsx
    pages/BankDetailPage.jsx
    pages/BankEditorPage.jsx
    pages/BankPreviewPage.jsx
    components/AdminLayout.jsx
    components/QuestionEditor.jsx
    components/ConfirmDialog.jsx
    services/adminAccess.js
    services/mbtiBankRepository.js
    domain/validateMbtiBank.js
    domain/calculateMbti.js
  tests/
    scoring.test.js
    bankValidation.test.js
    adminAccess.test.jsx
    bankEditor.test.jsx
test/
  fixtures/mbti-scoring-cases.json
  firestore/admin-dashboard.test.mjs
```

Firebase initialization hanya di `lib/firebase.js`; halaman menggunakan service,
bukan menulis Firestore langsung. Domain validasi/scoring tidak bergantung React
atau Firebase sehingga dapat diuji sebagai fungsi murni.

Config web memakai environment build dengan contoh yang dapat disalin. Config
client Firebase bukan kredensial admin; jangan memasukkan service-account key
atau password ke bundle. Mode emulator harus eksplisit menggunakan project
`demo-teencu` dan host lokal; konfigurasi emulator tidak boleh diam-diam berpindah
ke cloud. Hosting/build baru disiapkan pada tahap deployment berikutnya.

## Verifikasi yang diperlukan pada tahap implementasi

- Pengguna anonim dan pengguna biasa tidak dapat query bank/draft atau menulis
  konten, meskipun melewati UI; admin dapat query dengan limit yang diizinkan.
- Admin tidak dapat menaikkan role sendiri atau membaca riwayat orang lain;
  pencabutan role menolak operasi berikutnya.
- Draft valid dapat dibuat/disimpan; ID bentrok dan data tidak valid ditangani.
- Edit dari dua tab/admin menghasilkan konflik yang terlihat, bukan overwrite.
- Published tetap tidak dapat diedit/dihapus; draft belum bisa dihapus melalui UI.
- Publish dan aktivasi gagal dengan benar jika isi/pointer berubah atau target
  belum published. Retrying tidak membuat publikasi atau aktivasi tak terduga.
- Skor pratinjau cocok dengan fixture Dart, termasuk tie dan input invalid.
- Setelah aktivasi v2, sesi v1 dan riwayat lama masih berfungsi; pengguna v1 tidak
  perlu mengulang tes. Pengujian rules Flutter yang sudah ada tetap lulus.
- UI menangani loading, offline, izin dicabut, dan perubahan belum disimpan.

Audit ini meninjau kode dan tes yang ada, tidak menjalankan ulang suite atau
menganggap seluruh skenario di atas sudah teruji. Tidak ada perubahan runtime
pada tahap pertama sehingga belum diperlukan instalasi dependency atau deployment.

## Referensi teknis

- [Firebase Web setup](https://firebase.google.com/docs/web/setup): registrasi Web
  App dan config untuk SDK browser.
- [Firestore query security](https://firebase.google.com/docs/firestore/security/rules-query):
  izin query harus sesuai rules; rules bukan filter hasil query.
- [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions):
  transaksi untuk membaca dan menulis secara atomik; callback dapat diulang ketika
  dokumen berubah sehingga tidak boleh memodifikasi UI di dalam callback.

Tahap berikutnya: setup proyek `admin/` dan konfigurasi lokal/emulator berdasarkan
rancangan ini. Git, pengaturan cloud, dan deployment mengikuti alur yang disepakati
dengan pemilik proyek.
