# Setup lokal dashboard admin

Dashboard memakai React + JavaScript + Vite di `admin/`. Tahap ketiga menambahkan
login email/password, pemeriksaan izin admin dari server, pemantauan pencabutan
izin, logout, serta halaman akses ditolak. Editor soal belum tersedia.

## Menjalankan dashboard

Dari root repositori, PowerShell atau Git Bash:

```sh
cd admin
npm ci
npm run dev
```

Buka http://127.0.0.1:5173. Node 22.16 yang tersedia saat setup dapat digunakan
dengan dependency yang dikunci dalam `admin/package-lock.json`. Vite major 6 dan
plugin React major 4 dipilih untuk kompatibilitas runtime ini. Package root untuk
tes Firebase yang sudah ada tetap terpisah.

## Mode emulator (default)

Tanpa `.env.local`, konfigurasi memakai project `demo-teencu`, Auth port 9099 dan
Firestore port 8080, keduanya di `127.0.0.1`. Cloud tidak digunakan sebagai fallback
jika emulator mati. Login dan pemeriksaan izin membutuhkan emulator berjalan.

Jalankan emulator dari root repo di terminal terpisah, dengan Java 21:

```powershell
$env:JAVA_HOME = 'C:/Program Files/Android/Android Studio/jbr'
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
firebase emulators:start --only auth,firestore --project demo-teencu
```

## Mode cloud (setelah konfigurasi Web App tersedia)

1. Di Firebase Console project `teencu-dev`, periksa daftar aplikasi. Gunakan
   konfigurasi Web App yang sesuai, atau daftarkan Web App baru bila belum ada.
   Tidak perlu mengaktifkan Hosting saat registrasi ini.
2. Salin contoh konfigurasi:

   ```powershell
   Copy-Item admin/.env.example admin/.env.local
   ```

3. Pada `.env.local`, ganti target menjadi `cloud` dan isi `apiKey`, `authDomain`,
   `projectId`, serta `appId` dari konfigurasi Web App resmi. `appId` harus memiliki
   bagian `:web:`, bukan App ID Android. Project harus `teencu-dev`.
4. Restart dev server. Untuk mode emulator lagi, ubah target ke `emulator` dan
   restart. Environment Vite dibaca saat startup/build.

Konfigurasi yang belum lengkap atau target salah menghasilkan pesan kesalahan;
aplikasi tidak otomatis berpindah lingkungan. Init Firebase dilakukan melalui
`getFirebaseServices()` di `admin/src/lib/firebase.js`, yang akan digunakan fitur
login. Hindari pemanggilan SDK langsung dari komponen.

Nilai `VITE_*` masuk ke bundle browser. Config client Firebase bukan kredensial
admin. Password, token, dan service-account key tidak boleh dimasukkan ke sana.
Pembatasan admin tetap melalui Auth dan Firestore Rules.
File `.env.local`, dependency, serta build admin sudah diabaikan Git.

## Pemeriksaan

```sh
npm test
npm run build
npm run preview
```

Perintah pemeriksaan dijalankan dari folder `admin/`.
Preview di http://127.0.0.1:4173 menampilkan hasil build terakhir. Build masuk ke
`admin/dist/`. Pengujian konfigurasi memeriksa default emulator, target salah,
config cloud tidak lengkap, project salah, dan penolakan App ID Android.
Pengujian ini tidak memverifikasi layanan cloud atau akses admin.

Struktur awal memisahkan `pages`, `components`, `auth`, `services`, `domain`, dan
`lib`. Folder yang belum berisi implementasi disimpan dengan `.gitkeep`.
Belum ada konfigurasi deployment hosting, perubahan rules, atau penulisan cloud
yang dilakukan pada tahap setup ini.

Referensi: [Vite](https://vite.dev/guide/),
[Auth emulator](https://firebase.google.com/docs/emulator-suite/connect_auth),
[Firestore emulator](https://firebase.google.com/docs/emulator-suite/connect_firestore).
