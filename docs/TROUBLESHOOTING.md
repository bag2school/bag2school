# Troubleshooting

Gejala yang sudah pernah muncul di proyek ini, penyebabnya, dan cara cepat
memulihkannya. Semua perintah dijalankan dari root proyek.

## "Connection refused ... 127.0.0.1, port = 54321"

```
Access token is expired and refreshing failed, aborting api request
AuthRetryableFetchException(... Connection refused ... uri=http://127.0.0.1:54321/auth/v1/token)
```

**Artinya:** HP tidak bisa mencapai Supabase. Aplikasi Android memakai
`127.0.0.1:54321`, yang hanya ada **di dalam HP**, jadi butuh tunnel
`adb reverse` ke laptop.

**Penyebab tersering** (bukan kode, bukan Supabase mati):

- kabel USB dicabut / HP reboot / `adb server` restart → tunnel hilang
- HP pindah dari USB ke Wi-Fi
- `flutter run` dijalankan tanpa `tool/run_phone.ps1`

**Cek:**

```powershell
adb devices                 # harus ada "<serial>  device"
adb reverse --list          # harus berisi tcp:54321 dan tcp:54324
Test-NetConnection 127.0.0.1 -Port 54321
docker ps --filter name=supabase_kong
```

**Perbaiki:**

```powershell
.\tool\ensure_tunnel.ps1            # pasang sekali
.\tool\ensure_tunnel.ps1 -Watch     # biarkan jalan, otomatis pasang ulang
```

Setelah tunnel kembali, **sesi tidak hilang**: Supabase menyimpan session dan
hanya menggagalkan request. Buka Home / tarik refresh / restart aplikasi untuk
memicu percobaan ulang. Kalau tetap diminta login, masuk lagi dengan akun yang
sama.

### Urutan wajib sebelum `flutter run`

`adb reverse` **bukan setelan permanen**: mapping hilang setiap kabel dicabut,
HP reboot, atau adb server restart. Jadi urutannya selalu:

```powershell
# 1. HP tersambung dan sudah mengizinkan USB debugging
adb devices
#    harus: 4e1d78ca    device      (bukan: unauthorized / offline)

# 2. Pasang tunnel (HP 127.0.0.1:54321 -> laptop 54321)
adb reverse tcp:54321 tcp:54321
adb reverse tcp:54324 tcp:54324    # opsional: Inbucket (email reset password)

# 3. Pastikan mapping ada
adb reverse --list
#    harus: UsbFfs tcp:54321 tcp:54321

# 4. Baru jalankan aplikasi
flutter run
```

Satu perintah untuk langkah 1–4:

```powershell
.\tool\run_phone.ps1
```

Kalau kabel sempat tercabut **di tengah sesi** (`Lost connection to device`):

```powershell
.\tool\ensure_tunnel.ps1    # pasang ulang tunnel
flutter run                 # jalankan lagi
```

Atau biarkan pengawas berjalan di terminal kedua selama Anda bekerja:

```powershell
.\tool\ensure_tunnel.ps1 -Watch
```

### Jalankan tanpa kabel (Wi-Fi)

HP dan laptop harus di jaringan yang sama (cek: HP `192.168.86.x`, laptop
`192.168.86.x`), VPN HP mati, dan router tidak mengaktifkan *client isolation*.

**Cara A — sekali colok kabel (paling mudah, Android 8+):**

```powershell
# 1. colok kabel dulu
.\tool\connect_wifi.ps1

# 2. cabut kabel, lalu jalankan
flutter run -d 192.168.86.198:5555
.\tool\ensure_tunnel.ps1
```

**Cara B — tanpa kabel sama sekali (Android 11+, Wireless debugging):**

1. HP → Developer options → **Wireless debugging** → ON
2. Ketuk **Pair device with pairing code** (muncul IP:port dan 6 digit kode)
3. Di laptop:

```powershell
adb pair 192.168.86.198:<port-pairing> <kode-6-digit>
adb connect 192.168.86.198:<port-debugging>
adb devices
flutter run -d 192.168.86.198:<port-debugging>
```

Catatan:

- `adb reverse` **tetap bekerja** lewat Wi-Fi, jadi aplikasi tetap memakai
  `127.0.0.1:54321`. Tidak perlu ubah apa pun di kode.
- Port wireless debugging berubah setiap HP reboot → jalankan `adb connect` lagi.
- Kalau `adb connect` gagal: pastikan HP tidak tidur, lalu buka
  **Wireless debugging** sekali lagi (port berganti).
- Alternatif tanpa `adb reverse`: jalankan dengan
  `--dart-define=SUPABASE_URL=http://192.168.86.118:54321` (IP laptop) dan
  izinkan port 54321 di Windows Firewall. Cara ini lebih rapuh; `adb reverse`
  tetap disarankan.



| Tampilan | Arti | Tindakan |
|---|---|---|
| kosong | kabel/mode USB | cek kabel, pilih **File transfer / MTP**, bukan "Charging only" |
| `unauthorized` | izin belum diterima | buka HP, terima dialog *Allow USB debugging* |
| `offline` | adb server kacau | `adb kill-server ; adb start-server`, cabut–pasang kabel |
| `device` tapi app tetap refused | tunnel belum dibuat | ulangi langkah 2–3 |


## Supabase lokal mati total

```powershell
supabase.cmd start          # atau: supabase start
docker ps --filter name=supabase
```

Catatan: `supabase_vector_*` kadang restart-loop (pengumpul log). Itu **tidak**
mengganggu API; hanya berisik di `docker ps`. Bisa dibersihkan dengan
`supabase.cmd stop ; supabase.cmd start`.

### Container "not ready: unhealthy" padahal log-nya normal

Gejala:

```
supabase_studio_bag_2_school container is not ready: unhealthy
supabase_realtime_bag_2_school container is not ready: unhealthy
supabase_storage_bag_2_school container is not ready: unhealthy
supabase_pg_meta_bag_2_school container is not ready: unhealthy
```

Padahal log container menunjukkan server sudah siap
(`Server listening at http://0.0.0.0:8080`, `✓ Ready in 0ms`).

**Artinya:** container hidup, tapi healthcheck Docker gagal. Hampir selalu
masalah jaringan WSL2 setelah laptop tidur, bukan data rusak.

**Cek alasan pastinya:**

```powershell
docker inspect --format '{{json .State.Health}}' supabase_storage_bag_2_school |
  ConvertFrom-Json | Select-Object -ExpandProperty Log | Select-Object -Last 2
```

**Perbaikan (berurutan):**

```powershell
# 1. Restart WSL + Docker Desktop — menyelesaikan mayoritas kasus
wsl --shutdown
# buka Docker Desktop dari Start Menu, tunggu "Engine running"
supabase.cmd start

# 2. Kalau masih menolak, nyalakan hanya yang dipakai aplikasi
supabase.cmd start -x analytics,vector,studio,pg_meta,realtime,storage,imgproxy
```

Dengan opsi `-x` di atas: auth, database, REST, dan Kong tetap jalan — cukup
untuk login, keluarga, dan semua data. Yang hilang hanya Studio (browser DB),
upload avatar (Storage), realtime, dan analytics.

**Cek hasilnya:**

```powershell
supabase.cmd status
Test-NetConnection 127.0.0.1 -Port 54321
```


## `INSTALL_FAILED_USER_RESTRICTED` (Xiaomi / MIUI / HyperOS)

`flutter run` gagal dengan:

```
adb.exe: failed to install ...: Failure [INSTALL_FAILED_USER_RESTRICTED: Install canceled by user]
```

Ini pembatasan MIUI, bukan Flutter.

1. Developer options → aktifkan **Install via USB** dan **USB debugging (Security settings)**
2. Matikan **Verify apps over USB**
3. Matikan "Verify apps" di Play Protect bila masih menolak
4. Restart HP setelah mengubah setting

Kalau tetap menolak, install lewat `pm` (jalur ini yang berhasil di Redmi Note 9 Pro):

```powershell
adb push build\app\outputs\flutter-apk\app-debug.apk /data/local/tmp/bag2school.apk
adb shell pm install -r -t /data/local/tmp/bag2school.apk
adb shell monkey -p com.bag2school.app -c android.intent.category.LAUNCHER 1
```

`pm install` memberi pesan error yang lebih jelas daripada `adb install`.

## Inbucket (email reset password)

Supabase lokal tidak mengirim email keluar; email ditampung di
**http://127.0.0.1:54324**. Tautan reset password dibuka dari sana.

## `flutter`/`dart` menggantung tanpa output

Biasanya ada lock sisa:

```powershell
Remove-Item D:\Flutter\flutter\bin\cache\flutter.bat.lock -ErrorAction SilentlyContinue
```

Kalau tetap macet, pakai jalur langsung:

```powershell
$dart='D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe'
$snap='D:\Flutter\flutter\bin\cache\flutter_tools.snapshot'
& $dart $snap build apk --debug
```

## Teks/emoji jadi `Ã¢â‚¬â€` (mojibake)

Penyebab: file ditulis lewat `Set-Content` PowerShell. **Jangan** menulis file
Dart/teks dengan PowerShell; pakai editor atau Python UTF-8.

Kalau terlanjur: pulihkan dari git (`git checkout -- <file>`) atau dekode ulang
lapisan mojibake sebelum commit.

## `flutter build apk` gagal: butuh core library desugaring

Sudah diperbaiki di `android/app/build.gradle.kts`
(`isCoreLibraryDesugaringEnabled = true`). Kalau muncul lagi setelah mengubah
dependensi, pastikan blok itu masih ada.

## Layar merah setelah menambah PR / menutup dialog

Gejala di log: `A TextEditingController was used after being disposed`, lalu
`Duplicate GlobalKey`.

Aturan: dispose controller **setelah** animasi route selesai, lewat
`disposeControllersAfterRoute(...)` di `lib/utils/controllers.dart` (450 ms).

## Analyzer

```powershell
$dart='D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe'
& $dart analyze lib
```

Baseline yang sehat: **0 error, 26 warning** (semua warning lama = kode mati).
Kalau warning naik, biasanya ada import yang tidak terpakai setelah memindah
kode — hapus, jangan dibiarkan.

## Test

```powershell
& $dart $snap test      # 27 test, ±1 detik, tanpa HP
```

Kalau test gagal padahal kode tidak diubah, cek apakah perilakunya memang
berubah (test mengunci perilaku lama).
