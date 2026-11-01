# Konsep: Pengingat Harian Bag2School

Status: **draf untuk persetujuan** — belum ada kode yang ditulis.

## 1. Tujuan

Satu notifikasi harian yang mengingatkan orang tua menyiapkan sekolah **besok**,
pada jam yang bisa diatur (default **20:00**), dan tetap muncul **walaupun
aplikasi ditutup**.

## 2. Bukan bagian dari pekerjaan ini

- **Reminder per item** (per PR, per persiapan, per aktivitas) — sengaja tidak
  dibuat. Dengan 5–8 item per hari, notifikasi akan menumpuk dan diabaikan.
  Toggle "Remind me" yang ada sekarang akan **disembunyikan** agar tidak
  menyesatkan (datanya tetap tersimpan, tidak dihapus).
- **Push dari server (FCM)** — tidak perlu. Semua data ada di perangkat, jadi
  notifikasi lokal sudah cukup dan tidak butuh biaya server.
- **Menyusun isi notifikasi saat notifikasi berbunyi** — Android tidak
  menjalankan kode aplikasi di latar untuk ini. Isi disusun saat aplikasi
  terakhir dipakai (lihat §6).

## 3. Ringkasan teknis

| Bagian | Pilihan |
|---|---|
| Paket | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Jenis jadwal | `zonedSchedule` harian pada jam pilihan, `DateTimeComponents.time` |
| ID notifikasi | tetap (mis. `1001`) supaya penjadwalan ulang menimpa, bukan menumpuk |
| Kanal Android | `bag2school_daily_reminder`, importance default, getar standar |
| Penyimpanan setelan | `SharedPreferences`: aktif/tidak, jam, menit |

## 4. Izin dan manifest Android

| Kebutuhan | Detail |
|---|---|
| `POST_NOTIFICATIONS` | Android 13+, diminta saat toggle dinyalakan |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Android 12+, agar jam tidak digeser Doze |
| `RECEIVE_BOOT_COMPLETED` | jadwal dipulihkan setelah HP restart |
| Receiver plugin | `ScheduledNotificationBootReceiver` + `ScheduledNotificationReceiver` |

Kalau izin ditolak: toggle tetap bisa dinyalakan tetapi menampilkan status
*"Izin notifikasi belum diberikan"* dengan tombol menuju pengaturan Android.
Tidak ada crash, tidak ada penjadwalan diam-diam.

## 5. Alur pengguna (Settings)

```
Reminders
┌─────────────────────────────────────────┐
│ 🔔 Daily reminder            [switch]   │
│    Bagi menyapa tiap malam soal jadwal  │
│    besok                                │
│                            20:00  ›     │  ← tap untuk ubah jam
└─────────────────────────────────────────┘
```

- Switch OFF (default) → tidak ada notifikasi, tidak ada permintaan izin.
- Switch ON → minta izin → jadwalkan → tampilkan cuplikan isi pesan.
- Mengubah jam → jadwal lama dibatalkan, jadwal baru dibuat.
- Switch OFF → `cancel(1001)`, setelan disimpan.

## 6. Cakupan anak: **semua anak dalam family**

Bukan hanya anak yang sedang aktif. Alasannya: pengingat ini soal "menyiapkan
sekolah besok" untuk keluarga, dan orang tua biasanya menyiapkan tas beberapa
anak sekaligus. Anak aktif hanya menentukan urutan (anak aktif tampil pertama).

Aturan panjang isi:
- Maksimal **3 anak** ditulis lengkap, sisanya diringkas: *"dan 2 anak lain"*.
- Per anak maksimal **2 kegiatan** disebut, sisanya *"dan 1 kegiatan lain"*.
- Total isi dijaga di bawah ±180 karakter agar tidak terpotong di layar kunci.

Contoh dua anak:
> **Siap-siap untuk besok? ✨**
> Ryu: Matematika 07:00 · 2 persiapan
> Koko: tidak ada kegiatan
> Aku bantu ingatkan ya 😊

## 6b. Variasi kalimat (agar tidak monoton)

Judul dan penutup dipilih dari kumpulan kalimat, dan pemilihannya memakai
tanggal (hari ke-N dalam setahun) sehingga **berbeda tiap hari tetapi stabil**
kalau dijadwalkan ulang di hari yang sama.

**Judul (4 varian)**
1. `Besok sekolah, loh! 🎒`
2. `Siap-siap untuk besok? ✨`
3. `Bagi datang buat mengingatkan 🌙`
4. `Sedikit persiapan malam ini 😊`

**Penutup (4 varian)**
1. `Aku bantu ingatkan ya 😊`
2. `Kalau sudah siap, tidur lebih tenang 🌙`
3. `Sedikit demi sedikit, besok jadi ringan ✨`
4. `Kita siapkan pelan-pelan, ya 🙌`

**Hari kosong (3 varian)**
1. `Besok {nama} kosong, loh. Bisa santai dulu 😴`
2. `Besok tidak ada kegiatan. Selamat beristirahat 🌙`
3. `Jadwal besok lengang. Nikmati malamnya ya ✨`

## 7. Berkas yang akan tersentuh

| Berkas | Perubahan |
|---|---|
| `pubspec.yaml` | 3 dependency baru |
| `android/app/src/main/AndroidManifest.xml` | izin + receiver |
| `lib/services/reminder_service.dart` | **baru** — init, izin, jadwal, batal, susun teks |
| `lib/main.dart` | init saat boot, penjadwalan ulang setelah data berubah, seksi Settings |
| `lib/services/preparation_defaults.dart` dsb. | tidak berubah |

## 8. Rencana uji

1. Toggle ON → izin muncul → izin diberikan → cuplikan pesan tampil.
2. Ubah jam ke 2 menit ke depan → tutup aplikasi → notifikasi masuk.
3. Matikan HP, nyalakan → notifikasi tetap terjadwal (boot receiver).
4. Toggle OFF → tidak ada notifikasi.
5. Hapus semua kegiatan besok → isi pesan berubah menjadi versi "santai".
6. Uji di Chrome: fitur otomatis non-aktif (tidak ada crash).

## 9. Risiko dan mitigasi

| Risiko | Mitigasi |
|---|---|
| `flutter pub get` gagal (jaringan) | commit dulu; kalau gagal, `pubspec` dikembalikan |
| Build Gradle gagal karena plugin | uji dengan `flutter build apk --debug` sebelum menyerahkan |
| Notifikasi terlalu sering | satu ID tetap, satu kali sehari, default OFF |
| Isi pesan basi (data berubah tapi belum dijadwalkan ulang) | penjadwalan ulang dipanggil di setiap penyimpanan data + saat buka aplikasi |
| HP Xiaomi/Oppo membatasi notifikasi | catat sebagai batasan perangkat, bukan bug aplikasi |

## 10. Urutan kerja yang diusulkan

1. Commit checkpoint (sudah bersih).
2. Tambah dependency + `flutter pub get`.
3. Manifest + service + init di `main()`.
4. Toggle & pemilih jam di Settings.
5. Sembunyikan toggle "Remind me" per item.
6. `dart format` + `dart analyze` + `flutter build apk --debug`.
7. Commit, lalu uji manual di HP oleh Anda.

## 11. Keputusan yang sudah disetujui

1. Default **19:00**, bisa diubah di Settings.
2. Default fitur **OFF** (opt-in).
3. Toggle "Remind me" per item **disembunyikan sekarang** (data tetap tersimpan).
4. Cakupan: **semua anak** dalam family, anak aktif tampil pertama.
5. Kalimat bervariasi: 4 judul × 4 penutup, dipilih berdasarkan tanggal.
