# CoreUI Free React untuk dashboard Teencu

Dashboard menggunakan pola layout CoreUI Free React Admin Template: sidebar tetap
di desktop, menu overlay di layar kecil, header, breadcrumb, konten kartu, dan footer.
Layout diadaptasi ke fitur Teencu yang sudah ada, tanpa membawa halaman demo,
Redux, atau mengganti logika Firebase dengan autentikasi contoh template.

Paket gratis yang digunakan: `@coreui/react`, `@coreui/coreui`, `@coreui/icons`, dan
`@coreui/icons-react`. Komponen CoreUI menangani sidebar, header, breadcrumb,
kartu, tabel, badge, tombol, serta form/input. CSS Teencu mempertahankan warna
pink/ungu pada komponen utama. Source aplikasi tetap JavaScript + JSX dan Vite.

Referensi layout: https://github.com/coreui/coreui-free-react-admin-template

Dokumentasi komponen: https://coreui.io/react/docs/

Lisensi komponen MIT disertakan di `admin/THIRD_PARTY_NOTICES.md`. Tidak menggunakan
paket PRO atau fitur yang memerlukan lisensi komersial.

## Menjalankan dan memeriksa

Jika dev server masih berjalan, restart setelah pemasangan dependency baru.
Dari folder `admin/`:

```sh
npm ci
npm run dev
```

Pastikan Firebase Emulator berjalan untuk mode lokal. Alur akun dan contoh data
tetap mengikuti [uji auth](admin-auth-testing.md) serta [uji bank](admin-bank-testing.md).
Periksa login, akun tanpa izin, ringkasan, tabel, detail, dan penyalinan draft.
Pada layar kecil, buka menu lewat ikon di header, tutup lewat tombol silang atau
pilihan menu. Pada desktop, sidebar tampil di sisi kiri konten.

Tidak ada tambahan kebutuhan deploy rules untuk perubahan tampilan ini. Perubahan
rules dari tahap keempat tetap diperlukan untuk query bank soal di cloud.

## Catatan dependency

Saat integrasi, `npm audit` melaporkan empat temuan high dalam rantai dependency
Firebase -> Firestore -> `@grpc/grpc-js` (versi terpasang 1.9.16). Temuan tersebut
bukan pada CoreUI. Rekomendasi otomatis npm adalah downgrade Firebase lintas major;
tidak diterapkan karena dapat mengubah API aplikasi. Tindak lanjut dependency
Firebase/Node perlu diuji tersendiri. Advisory:
https://github.com/advisories/GHSA-m9gg-hp2v-232j
dan https://github.com/advisories/GHSA-f596-whhp-79r4.

Build juga masih mengingatkan ukuran bundle JavaScript utama lebih dari 500 kB;
optimasi pemisahan bundle dapat dilakukan setelah halaman editor selesai.
