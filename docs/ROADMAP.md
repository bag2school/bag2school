# Roadmap Bag2School

Satu-satunya sumber kebenaran untuk rencana kerja. Berkas ini **manual**
(diperbarui setiap ada pekerjaan selesai), lalu di-export ke Excel oleh
`tool/build_roadmap_xlsx.py`.

- Terakhir diperbarui: **31 Oktober 2026** (sore)
- Commit terakhir: `7bd9c4b`
- Situs kebijakan: <https://bag2school.github.io/bag2school/>
- Email dukungan: bag2school.project@gmail.com
- Tahap sekarang: **pengembangan fitur selesai → menuju rilis Play Store**

## Cara membaca

| Status | Arti |
|---|---|
| `Done` | sudah selesai, ter-commit, analyzer bersih |
| `In progress` | sedang dikerjakan |
| `Next` | berikutnya, sudah disepakati |
| `Backlog` | ide/permintaan, belum dijadwalkan |
| `Blocked` | menunggu keputusan atau pekerjaan lain |
| `Dropped` | dibatalkan (dengan alasan) |

Prioritas: **P0** (harus), **P1** (penting), **P2** (bagus kalau sempat).

---

## 1. Selesai

| ID | Area | Item | Status | Prioritas | Catatan | Commit |
|---|---|---|---|---|---|---|
| D-01 | Akun | Login & signup dengan Supabase | Done | P0 | pesan error dibedakan | — |
| D-02 | Akun | Lupa password: email → set password baru | Done | P0 | deep link `bag2school://reset-password` | `788c006`, `9cff428` |
| D-03 | Akun | Multi-device + pemberitahuan login di perangkat lain | Done | P1 | sesi lain tidak lagi diputus | `264c053` |
| D-04 | Keluarga | Buat keluarga, undang via kode 4 huruf / link token | Done | P0 | role owner / parent guardian / caregiver / child | — |
| D-05 | Keluarga | Child Access ringkas (expandable) + pilih akses sebelum undang | Done | P1 | grant masih lokal | — |
| D-06 | Jadwal | 5 tipe aktivitas, recurrence, konflik, kalender bulan | Done | P0 | view-only untuk anak lain | — |
| D-07 | Persiapan | Item default per tipe, tambah/hapus, progress | Done | P0 | toggle reminder per item disembunyikan | — |
| D-08 | PR | Tambah/edit/hapus, history, tautan ke aktivitas | Done | P0 | — | — |
| D-09 | Home | Kartu kesiapan, fokus besok, kartu anak lain | Done | P1 | — | — |
| D-10 | Notifikasi | Reminder harian 19:00 (opt-in, teks bergaya Bagi) | Done | P1 | tap → Home / Login | — |
| D-11 | Offline | Cache keluarga + strip "offline" di Home | Done | P1 | `bag2school_family_cache_v1_<userId>` | `cf65113` |
| D-12 | Profil anak | Switch child dengan avatar, kelas, chip Active / View only | Done | P1 | sheet scrollable + pencarian >5 anak | `08932d9` |
| D-13 | UI | Transisi halaman halus (fade + lift) + cross-fade AuthGate | Done | P1 | hormat setelan "hapus animasi" | `08932d9` |
| D-14 | Arsitektur | `main.dart` 23.980 → 563 baris (76 → 5 class) | Done | P0 | 14 langkah, satu commit tiap langkah | `ae1f194`…`7f62c94` |
| D-15 | Arsitektur | Model, serializer, store, otorisasi keluar dari `main.dart` | Done | P0 | — | `ae1f194`, `7352ef6`, `6912406` |
| D-16 | Arsitektur | 5 form aktivitas dipisah ke `features/schedule/forms/` | Done | P1 | `schedule_page.dart` 6.682 → 3.726 baris | `fcf9d5f` |
| D-17 | Test | 31 test model, serialisasi, dan transisi | Done | P1 | `flutter test` ±1 detik | `3a5ef33` |
| D-18 | Dokumentasi | Knowledge graph, symbol index, Obsidian canvas, AGENTS.md | Done | P1 | di-generate ulang lewat `tool/` | `458cfb5`, `042be0a`, `41e8872` |
| D-19 | Tooling | `ensure_tunnel.ps1`, `run_phone.ps1`, troubleshooting | Done | P1 | tunnel `adb reverse` otomatis | `079fce2`, `79570f4`, `b68265a` |
| D-20 | Proses | Roadmap Markdown + export Excel otomatis | Done | P1 | `tool/build_roadmap_xlsx.py` | `ee62648` |

| D-21 | Tutorial | Sorotan mengikuti keyboard, rotasi, dan dialog yang bergerak | Done | P1 | overlay diukur ulang ±30 fps | `624d27f` |
| D-22 | Tutorial | Dialog "Child saved!" setelah menyimpan profil saat tutorial | Done | P1 | sebelumnya berakhir diam | `624d27f` |
| D-23 | Akun | Hapus akun hanya di My Account, di bawah Sign out | Done | P1 | duplikat di Settings & dialog edit dihapus | `624d27f` |
| D-24 | Akun | Pesan sign-up spesifik (email salah/terdaftar/lemah/rate limit/konfirmasi) | Done | P0 | `SignUpResult` diperluas | `4def37c` |
| D-25 | Akun | Sandi minimal 8 karakter (signup & reset) | Done | P1 | — | `624d27f` |
| D-26 | Akun | Forgot password melaporkan penyebab gagal | Done | P1 | termasuk redirect & rate limit | `4def37c` |
| D-27 | Rilis | Halaman privasi & hapus akun (HTML statis) | Done | P0 | `docs/index.html`, `privacy.html`, `delete-account.html` | — |

## 2. Sedang dikerjakan

| ID | Area | Item | Status | Prioritas | Catatan | Commit |
|---|---|---|---|---|---|---|
| — | — | tidak ada | — | — | — | — |

## 3. Berikutnya: jalur rilis Play Store

Urutan ini **berurutan** — item di bawah mengandaikan item di atasnya selesai.

| ID | Area | Item | Status | Prioritas | Catatan | Commit |
|---|---|---|---|---|---|---|
| R-01 | Backend | Pindahkan Supabase ke hosted (HTTPS), jalankan migrasi, aktifkan RLS & SMTP | In progress | P0 | skema + GRANT + RLS **terverifikasi**; sisa SMTP dan uji signup end-to-end | `c4410cc` |
| R-02 | Config | URL Supabase dari `--dart-define`; build rilis menolak jalan tanpa URL | Done | P0 | `StateError` bila `SUPABASE_URL` kosong di release | `5c9d6c6` |
| R-03 | Android | Ganti `applicationId` menjadi `com.bag2school.app` | Done | P0 | namespace dibiarkan agar file Kotlin tidak berpindah | `5c9d6c6` |
| R-04 | Android | `targetSdk = 36` (Android 16), `compileSdk = 36` | Done | P0 | terbukti di APK rilis: `targetSdkVersion 36` | `2e07ffe` |
| R-05 | Android | Signing rilis: upload keystore + `key.properties` (gitignored) | Done | P0 | terverifikasi lewat `signingReport` dan `apksigner` (SHA-256 `2a1f3565…`); kata sandi & `.jks` **wajib Anda simpan** | `2e07ffe` |
| R-06 | Android | Label `Bag2School` | Done | P0 | ikon adaptif & `allowBackup` menyusul di R-14/R-15 | `5c9d6c6` |
| R-07 | Kode | Alat dev tidak ikut rilis | Done | P0 | `supabase_debug_page` hanya dipakai entry debug terpisah; tidak terjangkau dari `main.dart` | `5c9d6c6` |
| R-08 | Kode | Foto anak: tombol & teks dihapus | Done | P1 | keputusan Anda: **tidak mengumpulkan foto anak** (privasi) | `5c9d6c6` |
| R-09 | Legal | Kebijakan privasi publik (URL wajib di Play Console) | Done | P0 | live di https://bag2school.github.io/bag2school/privacy.html, termasuk bagian iklan & langganan | `57e6a73` |
| R-10 | Legal | Hapus akun: menu di Settings + halaman web untuk permintaan | Done | P0 | in-app di My Account (bawah Sign out) + halaman web live | `624d27f` |
| R-11 | Play Console | Data safety form (email, nama, profil anak, avatar) + bagian penghapusan data | Next | P0 | harus konsisten dengan R-09/R-10 | — |
| R-12 | Play Console | Content rating IARC + target audiens | Next | P0 | disarankan **18+ / dewasa** (dipakai orang tua) agar tidak masuk Families policy | — |
| R-13 | Play Console | Akun developer, verifikasi identitas, App access (kredensial tes), deklarasi iklan | Next | P0 | biaya sekali US$25 | — |
| R-14 | Aset | Ikon 512×512, feature graphic 1024×500, ≥2 screenshot, deskripsi singkat & panjang | Next | P1 | — | — |
| R-15 | Build | AAB rilis: obfuscate, split per ABI, ukuran wajar, uji di perangkat bersih | Next | P0 | **APK rilis arm64 terbukti**: 21,5 MB, `com.bag2school.app`, targetSdk 36, ter-sign; AAB penuh & uji perangkat menyusul | `2e07ffe` |
| R-16 | Testing | Internal testing → closed test **12 tester aktif 14 hari** → production | Next | P0 | syarat akun personal baru (dibuat setelah 13 Nov 2023) | — |
| R-17 | Rilis | Pre-launch report bersih, lalu ajukan production access (review ≤7 hari) | Next | P0 | perlu ringkasan feedback tester | — |
| R-22 | Rilis | Publikasikan `docs/` lewat GitHub Pages → Site URL | Done | P0 | https://bag2school.github.io/bag2school/ (branch publish → main, folder /docs) | — |
| R-23 | Rilis | Ganti email placeholder dengan email dukungan asli | Done | P0 | bag2school.project@gmail.com di kedua halaman | — |
| R-24 | Akun | Uji konfirmasi email hosted (nyalakan kembali sebelum rilis + SMTP sendiri) | Next | P0 | default hosted ON; SMTP bawaan dibatasi per jam | — |
| R-18 | Akun | **Continue with Google** (OAuth) untuk daftar & masuk | Next | P1 | butuh Google Cloud OAuth + provider Goole di Supabase + deep link; kurangi friksi orang tua | — |
| R-19 | Akun | Tangani konfirmasi email saat signup di hosted | Next | P0 | hosted mengaktifkan konfirmasi email; app harus menampilkan "cek email" dengan benar | — |
| R-20 | Akun | Kebijakan sandi: minimal 8 karakter + petunjuk kekuatan | Next | P2 | sekarang 6 agar sama dengan signup lama | — |
| R-21 | Akun | Kebijakan sesi: tetap masuk + halaman Devices | Next | P2 | jangan paksa login harian; sediakan daftar perangkat & sign out | — |

## 3c. Keluarga & akses (hasil sesi 1 Nov)

Detail desain: [INVITATIONS.md](INVITATIONS.md)

| ID | Area | Item | Status | Prioritas | Catatan | Commit |
|---|---|---|---|---|---|---|
| R-25 | Keluarga | Kode undangan sekali pakai + kedaluwarsa 10 menit + generate ulang | In progress | P0 | migrasi **sudah dijalankan di hosted**; pesan `used`/`expired` diperjelas, hint AB12 dihapus; tinggal uji 3 akun setelah build baru | `ed32439` |
| R-26 | Keluarga | Matriks akses saat undang: Full/View + centang fitur | Done | P0 | dialog akses punya segmen None/View/Full + chip Schedule/Homework/Preparation/Exam; fitur disimpan lewat FamilyAccessDefaults.saveFeatures | — |
| R-27 | Keluarga | Caregiver: tidak bisa tambah/hapus anak & ubah grant; default view-only | In progress | P0 | tombol Full dihapus untuk caregiver + aksi kelola sudah di-gate `isOwner`; **RLS belum** menolak panggilan langsung | — |
| R-28 | Keluarga | Invite by link (token + halaman join) | In progress | P0 | akar masalah: encode(..., base64url) tidak valid + link memakai Uri.base (file://). Migrasi v16 + docs/join.html + URL HTTPS sudah dibuat; **menunggu SQL dijalankan** | — |
| R-29 | Kualitas | Assertion `_dependents.isEmpty` + ikon Child Access rusak | In progress | P0 | ikon rusak = emoji mojibake, **sudah diperbaiki** (7 tempat); assertion butuh reproduksi log | `ed32439` |
| R-32 | Copy | Review semua pesan/dialog agar hangat & jelas (panduan: docs/COPY.md) | In progress | P1 | 20 string kunci sudah diubah; sisa inventaris di COPY.md | — |
| R-30 | Akun | Google consent screen: nama Bag2School, logo, domain | Next | P2 | menghilangkan kesan "supabase.co" | — |
| R-31 | Lokalisasi | Bahasa Indonesia (ekstraksi string + terjemahan + pemilih bahasa) | Backlog | P1 | pekerjaan besar, 2–3 sesi | — |

## 3b. Monetisasi (rencana)

| ID | Area | Item | Status | Prioritas | Catatan | Commit |
|---|---|---|---|---|---|---|
| M-01 | Monetisasi | Iklan untuk pengguna gratis (AdMob) | Next | P1 | hanya free tier; premium bebas iklan | — |
| M-02 | Monetisasi | Langganan premium lewat Google Play Billing | Next | P1 | produk bulanan/tahunan; tanpa iklan | — |
| M-03 | Monetisasi | Status premium tersimpan di Supabase + gating di app | Next | P1 | tabel `subscriptions` + verifikasi purchase token | — |
| M-04 | Monetisasi | Consent iklan (UMP) untuk EEA/UK + deklarasi iklan di Play | Next | P0 | wajib sebelum iklan aktif | — |
| M-05 | Monetisasi | Perbarui Data safety & privacy policy setelah iklan aktif | Next | P0 | sebut mitra iklan + identifier | — |

## 3d. Dijeda

| ID | Area | Item | Status | Prioritas | Catatan | Commit |
|---|---|---|---|---|---|---|
| P-01 | UI | Migrasi semua dialog ke komponen Bagi (`showBagiDialog`) | Paused | P2 | **dihentikan sementara atas permintaan owner (2 Nov 2026)**. Komponen & dialog ganti-family sudah ada; sisanya jangan dikerjakan sampai diaktifkan lagi | `81a6657` |

## 4. Backlog

| ID | Area | Item | Status | Prioritas | Catatan | Commit |
|---|---|---|---|---|---|---|
| B-01 | Notifikasi | Push untuk perubahan data (jadwal baru, anggota bergabung) | Backlog | P1 | butuh sync jadwal + `device_tokens` + Edge Function + FCM | — |
| B-02 | Data | Sinkronisasi jadwal/persiapan/PR ke Supabase | Backlog | P1 | prasyarat B-01 | — |
| B-03 | Keluarga | Pengelompokan anak per keluarga di switch sheet | Backlog | P2 | perlu `familyId` per anak (Supabase + lokal) | — |
| B-04 | Keluarga | Grant akses lintas device | Backlog | P1 | `child_access_grants` belum punya `GRANT` di migrasi | — |
| B-05 | Akun | Kebijakan perangkat untuk tier premium | Backlog | P2 | arah: halaman Devices + tombol sign-out, bukan tendangan | — |
| B-06 | Profil anak | Upload foto anak | Dropped | P2 | keputusan produk: foto anak tidak dikumpulkan (privasi) | — |
| B-07 | Persiapan | Tampilkan kembali toggle "remind me" per item | Backlog | P2 | datanya masih disimpan | — |
| B-08 | Kualitas | Bersihkan 26 warning analyzer (kode mati) | Backlog | P2 | baseline aman, hanya kerapian | — |
| B-09 | Arsitektur | Pecah `_SchedulePageState` (3.280 baris, 48 method) | Backlog | P2 | memecah **state**, bukan file; risiko sedang | — |
| B-10 | Arsitektur | Pindahkan perhitungan kesiapan ke `lib/data/readiness.dart` + test | Backlog | P1 | sekarang duplikat di Home & Preparation | — |
| B-11 | Test | Test `Bag2SchoolStore` (pindah anak, simpan per anak, pemulihan) | Backlog | P1 | pakai `SharedPreferences.setMockInitialValues` | — |
| B-12 | Operasional | Crash reporting (Crashlytics/Sentry) + kebijakan update data safety | Backlog | P2 | berguna setelah rilis | — |

## 5. Terhambat

| ID | Area | Item | Status | Prioritas | Catatan | Commit |
|---|---|---|---|---|---|---|
| C-01 | Notifikasi | Push perubahan data | Blocked | P1 | menunggu B-02 (jadwal harus di server dulu) | — |
| C-02 | Rilis | Pengajuan production | Blocked | P0 | menunggu R-01…R-16 selesai + 14 hari closed test | — |

## 6. Dibatalkan

| ID | Area | Item | Status | Prioritas | Catatan | Commit |
|---|---|---|---|---|---|---|
| X-01 | Arsitektur | Dedup `_formatTime` / `_formatDate` antar layar | Dropped | P2 | semantiknya berbeda (12-jam vs 24-jam) | — |

---

## Lampiran: ketentuan Play Store yang sudah dikonfirmasi

Diambil dari dokumentasi resmi Google, 31 Oktober 2026.

| Ketentuan | Isi | Sumber |
|---|---|---|
| Target API level | Mulai **31 Agustus 2026**, aplikasi baru & update harus menargetkan **Android 16 (API 36)**. Perpanjangan bisa diajukan sampai 1 November 2026. Halaman diperbarui 28 Oktober 2026. | [developer.android.com/google/play/requirements/target-sdk](https://developer.android.com/google/play/requirements/target-sdk) |
| Uji tertutup akun personal | Akun personal yang dibuat **setelah 13 November 2023** wajib closed test dengan **≥12 tester** yang opt-in **terus-menerus 14 hari** sebelum boleh mengajukan production. Review pengajuan biasanya **≤7 hari**. | [support.google.com/.../14151465](https://support.google.com/googleplay/android-developer/answer/14151465) |
| Penghapusan akun | Jika aplikasi mengizinkan pembuatan akun, wajib ada **(a)** jalur hapus akun di dalam aplikasi dan **(b)** tautan web untuk mengajukan penghapusan. Keduanya diisi di Data safety form. | [support.google.com/.../13327111](https://support.google.com/googleplay/android-developer/answer/13327111) |

Ketentuan lain yang berlaku umum (perlu dicek saat submit): kebijakan privasi
wajib, Data safety form wajib, content rating wajib, deklarasi iklan, App access
(kredensial untuk reviewer), AAB (bukan APK), tanda tangan Play App Signing,
tidak ada kode yang mengunduh kode lain, dan aplikasi harus berfungsi tanpa
developer tool.

---

## Cara memperbarui (untuk saya maupun Anda)

1. Ubah tabel di atas: status, catatan, commit.
2. Perbarui baris "Terakhir diperbarui" dan "Commit terakhir".
3. Jalankan:

   ```powershell
   python tool/build_roadmap_xlsx.py
   ```

4. Commit keduanya (`docs/ROADMAP.md` dan `docs/ROADMAP.xlsx`).

Setiap kali satu pekerjaan selesai, saya akan memperbarui berkas ini,
membangkitkan ulang Excel-nya, dan menyerahkan keduanya.
