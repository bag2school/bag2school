# AGENTS.md

Panduan singkat untuk agent AI (Cursor, Claude Code, Copilot, Codex) yang
bekerja di repo ini. Konteks lengkap: [docs/AI_CONTEXT.md](docs/AI_CONTEXT.md).

## Proyek

Bag2School — aplikasi Flutter (Android) untuk merencanakan sekolah anak, dengan
maskot **Bagi**. Backend Supabase lokal. Bahasa UI: Inggris.

- Flutter 3.47 / Dart 3.13
- `lib/main.dart` hanya shell (565 baris): boot, `MaterialApp`, error screen
- Fitur ada di `lib/features/<fitur>/`, data di `lib/data/`, model di `lib/models/`
- Service di `lib/services/`, widget bersama di `lib/widgets/`

## Tautan publik

- Kebijakan privasi: https://bag2school.github.io/bag2school/privacy.html
- Hapus akun (web): https://bag2school.github.io/bag2school/delete-account.html
- Halaman sumber: `docs/index.html`, `docs/privacy.html`, `docs/delete-account.html`
- Site URL yang dipakai di Supabase: https://bag2school.github.io/bag2school/

## Aturan wajib

1. **Commit sebelum perubahan besar.** Satu langkah = satu commit.
2. **`dart format` + `dart analyze` harus bersih** sebelum commit.
   Baseline: **0 error, 26 warning** (semua warning lama = kode mati).
3. **Jangan pakai `Set-Content` PowerShell untuk file Dart/teks** — pernah
   merusak encoding (mojibake). Pakai editor/Python UTF-8.
4. Dispose `TextEditingController` **setelah** animasi route
   (`disposeControllersAfterRoute`, 450 ms).
5. Jangan mengubah migrasi Supabase tanpa persetujuan.
6. Jangan menghapus file tanpa persetujuan.
7. **Setiap pekerjaan selesai → perbarui `docs/ROADMAP.md`** (status, catatan,
   commit), lalu:
   ```powershell
   python tool/build_roadmap_xlsx.py
   ```
   dan serahkan `ROADMAP.md` + `ROADMAP.xlsx` ke pengguna.

## Perintah

```powershell
# analyzer
$dart='D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe'
$snap='D:\Flutter\flutter\bin\cache\flutter_tools.snapshot'
& $dart $snap analyze --no-pub lib

# test (27 test model & serialisasi, ±1 detik)
& $dart $snap test

# build
& $dart $snap build apk --debug

# peta kode (setelah struktur berubah)
python tool/build_knowledge_graph.py
python tool/build_obsidian.py
python tool/build_symbol_index.py
```

## Data & state

- `Bag2SchoolStore` (di `lib/data/store.dart`) = state global statis.
- Jadwal/persiapan/PR **masih lokal** per anak di SharedPreferences.
- Supabase: profil, keluarga, anggota, anak, undangan.

## Jangan bingung

- `docs/knowledge-graph.md` (manual) dan `docs/generated/*` (hasil generate)
  menjawab "siapa memanggil siapa", bukan "apa maksud fungsi ini".
- 26 warning analyzer sudah ada sebelum refactor; jangan menambah yang baru.
