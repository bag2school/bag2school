# Bag2School — AI context pack

Ringkasan padat untuk dimuat sebelum mengerjakan kode. Perbarui bila arsitektur
berubah. Peta lengkap: [knowledge-graph.md](knowledge-graph.md).

## Identitas proyek

- Flutter 3.47 / Dart 3.13, target **Android** (Chrome hanya untuk cek cepat).
- Backend: **Supabase lokal** (`http://127.0.0.1:54321`, 31 migrasi, RLS aktif).
- Bahasa UI: **Inggris**. Maskot: **Bagi** (nada hangat, suportif).
- Warna: krem `#FFFCF8`, oranye `#FF7A21`, ungu `#7661D8` (PR), teal `#2A9D8F`.

## Struktur

| Area | Lokasi |
|---|---|
| Shell | `lib/main.dart` (565 baris: boot, MaterialApp, error screen) |
| Layar | `lib/features/<fitur>/` — home, schedule (+ forms/), homework, preparation, settings, family |
| Auth | `lib/auth_gate.dart`, `login_page.dart`, `signup_page.dart`, `reset_password_page.dart` |
| Keluarga | `choose_family_page.dart`, `create_family_page.dart`, `family_waiting_room_page.dart`, `services/bagi_family_service.dart` |
| Service | `lib/services/*` (18 file, termasuk bagi_message, reminder_content) |
| Widget bersama | `lib/widgets/*` (bagi_character, month_calendar, list_items, bubble_tail_painters, app_notification, daily_reminder_tile) |
| Store | `lib/data/store.dart` (Bag2SchoolStore, LocalAuthorization, bundle per anak) |
| Model | `lib/models/` (activity_models, family_models, child_profile) |
| Serializer | `lib/data/serializers.dart` |
| Utilitas | `lib/utils/controllers.dart`, `lib/utils/focus.dart` |
| Tema | `lib/theme/bag2school_tokens.dart`, `lib/theme/page_transitions.dart` |

## Aturan kerja yang WAJIB diikuti

1. **Commit dulu sebelum perubahan besar.** Setiap langkah = satu commit.
2. **`dart format` + `dart analyze`** sebelum commit. Baseline saat ini:
   **0 error, 26 warning** (semua warning lama: kode mati).
3. **Jangan ubah DB/migrasi** tanpa persetujuan eksplisit.
4. **Jangan hapus file** tanpa persetujuan.
5. Tooling: jalankan Flutter via `D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe`
   + `flutter_tools.snapshot`; perintah `flutter`/`dart` biasa bisa macet karena
   lock/cache. Analyzer butuh akses tulis ke folder SDK.
6. **Jangan pakai PowerShell `Set-Content` untuk file Dart** (emoji rusak).
7. Dispose `TextEditingController` **setelah** animasi route selesai
   (`_disposeControllersAfterRoute`, 450 ms).

## State & data

- 17 model data sudah dipisah ke `lib/models/` (langkah 1 dari rencana split).
- `Bag2SchoolStore` = kelas **statis** (bukan singleton instance), tanpa notifier.
  Setiap mutasi diikuti `setState` layar + `persistSchoolDataSoon()`.
- Data jadwal/persiapan/PR = **lokal** per anak:
  `bag2school_school_data_v1_<userId>_<childId>` di SharedPreferences.
- Supabase dipakai untuk: `profiles`, `families`, `family_members`, `children`,
  `family_invitation_codes`, `family_invitation_links`, `family_join_requests`,
  dan RPC (`create_family`, `join_family_with_invitation_code`,
  `consume_family_invitation_link`, `validate_family_invitation_code`, …).
- Cache offline keluarga: `bag2school_family_cache_v1_<userId>`.
- Grant akses: memori + snapshot `bag2school_access_grants_v1_<familyId>`.

## Tautan publik

- Privasi: https://bag2school.github.io/bag2school/privacy.html
- Hapus akun: https://bag2school.github.io/bag2school/delete-account.html

## Fitur yang sudah jalan

- Auth: login, signup, forgot password (link email → set password baru),
  multi-device dengan pemberitahuan login perangkat lain.
- Keluarga: buat, undang (kode 4 huruf / link token), pilih role, pilih akses
  per anak sebelum kode dibuat, Child Access ringkas (expandable).
- Jadwal: 5 jenis aktivitas, recurrence, konflik waktu, kalender bulan,
  timeline, edit/hapus, view-only jadwal anak lain (besok).
- Persiapan: default per tipe (bisa dihapus dengan ✕, tambahan tersimpan),
  reminder per item **disembunyikan**.
- PR: tambah/edit/hapus, history (selesai + lewat tenggat), tautan ke aktivitas.
- Kesiapan (GET READY): ring animasi, baris hijau saat dicentang, fokus pindah
  ke besok setelah semua aktivitas hari ini dimulai.
- Notifikasi: **satu** reminder harian (default 19:00, opt-in), isi bahasa
  Inggris bergaya Bagi, 10 judul × 10 penutup acak, menyebut anak aktif +
  item persiapan yang belum siap, lalu jumlah anak lain. Tap → Home/Login.
- Tutorial owner 17 langkah (+ lantai bonus untuk anak lain).

## Belum ada / utang teknis

| Item | Dampak |
|---|---|
| Jadwal belum disinkronkan ke Supabase | kartu anak lain & notifikasi perubahan hanya lokal |
| Push notification perubahan data | butuh sync + `device_tokens` + Edge Function + FCM |
| `child_access_grants` tanpa `GRANT` di migrasi | grant tidak lintas device |
| 26 warning analyzer (kode mati) | kerapian |
| 8 file backup di `archive/` | di luar build, aman |

## Perintah penting

```powershell
# analyzer (dengan akses penuh)
$dart='D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe'
$snap='D:\Flutter\flutter\bin\cache\flutter_tools.snapshot'
& $dart $snap analyze --no-pub lib

# jalankan di HP lewat USB (tunnel adb otomatis)
.\tool\run_phone.ps1

# perbarui graph
python tool/build_knowledge_graph.py
```

## Konvensi UI

- Transisi halaman memakai `softPageTransitionsTheme` (fade + lift 340 ms); jangan bikin animasi push sendiri.
- Kartu putih radius 20–28, latar krem, judul tebal (w700–w900).
- Target sentuh ≥ 48 dp; teks mengikuti skala sistem (jangan tinggi tetap).
- Konten lebar dibatasi `maxWidth: 960` (Home, Schedule, Preparation).
- Bagi menyapa dengan nama dari `BagiIdentityController.resolveAddressName`
  (prioritas: preferred_title → metadata akun → anggota keluarga → email).
