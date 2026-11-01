# Copy & tone guide

Semua teks yang dilihat pengguna harus terasa seperti **Bagi**: hangat, tenang,
jelas. Bukan bahasa sistem, bukan bahasa formulir.

## Prinsip

1. **Sapa dengan "you"**, pakai bentuk pendek ("you're", "let's").
2. **Bagi menyapa sebagai teman** — pihak ketiga yang membantu, bukan robot:
   "Bagi could not save this yet" → bukan "System error".
3. **Satu pesan = satu tindakan.** Kalau bisa, sebutkan langkah berikutnya.
4. **Jangan menyalahkan.** "That email looks unfinished" bukan "Invalid email".
5. **Maksimal dua kalimat** untuk error. Detail teknis hanya di log.
6. **Tenang saat gagal, hangat saat berhasil.** Tanda seru hanya untuk kabar baik.
7. **Jangan berlebihan.** Hindari "Oopsie", "Yay" di pesan error.

## Contoh

| Konteks | Jangan | Pakai |
|---|---|---|
| Email salah | "Invalid email address." | "That email looks unfinished. Check for a missing @ or domain." |
| Password pendek | "Password must be at least 8 characters." | "A little longer, please — 8 characters or more keeps your account safe." |
| Kode undangan terpakai | "Code not valid." | "Someone already used this code. Ask the family owner for the fresh one." |
| Rate limit | "Rate limit exceeded." | "We have sent a few emails already. Give it a minute, then try again." |
| Hapus akun | "This action is irreversible." | "Your account and its data will be removed for good." |
| Sukses simpan | "Operation successful." | "Saved! Bagi will keep this in mind." |

## Istilah tetap

| Pakai | Hindari |
|---|---|
| child / children | kid profile, student record |
| family owner | admin, superuser |
| invite code | token, OTP |
| plan (jadwal/PR/persiapan) | data entry, records |
| Request access | permission denied |

## Sudah diperbarui (sesi 1–2 Nov 2026)

- Dialog akses anggota ("What can they see?")
- Dialog hapus akun + sukses
- Pesan kode undangan (tidak aktif / terpakai / kedaluwarsa)
- Pesan sign-up: email tidak lengkap, password lemah, rate limit, konfirmasi email
- Pesan reset password
- Dialog batalkan pembuatan keluarga
- Emoji rusak (7 tempat) diperbaiki

## Belum diperbarui (inventaris)

| Area | Berkas | Contoh teks sekarang |
|---|---|---|
| Empty state PR | `features/homework/homework_page.dart` | "No homework yet" |
| Dialog persiapan | `features/preparation/preparation_page.dart` | "Remove … from this preparation list?" |
| Form aktivitas | `features/schedule/forms/*.dart` | "Give the event a name first — then we'll get it on the calendar." (sudah cukup hangat) |
| Error screen | `main.dart` (`_BagiErrorScreen`) | "Bagi tripped on something" (sudah hangat) |
| Tutorial | `features/settings/settings_page.dart` | "Enter your child's name, then pick Boy or Girl below…" |
| Notifikasi harian | `services/reminder_content.dart` | sudah bergaya Bagi |
| Pengaturan | `features/settings/settings_page.dart` | "Keep Bag2School data safe across devices" |

Saat mengubah salah satu area di atas, perbarui tabel ini.

## Aturan untuk agent

- Setiap string baru **wajib** mengikuti tabel "Contoh".
- Jangan menambah tanda seru pada pesan error.
- Setelah mengubah copy, jalankan `dart format` + `dart analyze`, lalu perbarui
  `docs/ROADMAP.md` bila item terkait selesai.
