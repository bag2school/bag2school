# Undangan & hak akses — keputusan desain

Catatan keputusan dari sesi 1 November 2026. Menjadi acuan implementasi
R-25…R-28.

## 1. Kode undangan

| Aturan | Nilai |
|---|---|
| Masa berlaku | **10 menit** sejak dibuat |
| Pemakaian | **sekali pakai** — begitu satu akun bergabung, kode dianggap terpakai |
| Setelah terpakai | owner melihat **kode baru** otomatis (generate ulang), bukan kode lama |
| Setelah kedaluwarsa | generate ulang saat halaman dibuka / tombol "new code" |
| Bentuk | 4 huruf kapital, misal `AB12` |
| Konflik | retry generate bila kode bentrok dengan yang aktif |

Implementasi yang disarankan:

```sql
alter table public.family_invitation_codes
  add column if not exists used_at timestamptz,
  add column if not exists used_by uuid references public.profiles(id) on delete set null;
```

- `consume_family_invitation_code(code)` menandai `used_at = now(), used_by = uid` di transaksi yang sama saat join.
- `issue_family_invitation_code(family_id)`:
  1. kalau ada kode milik family yang **belum terpakai** dan `created_at + 10 min > now()` → kembalikan itu;
  2. kalau tidak, buat kode baru (dan tandai yang lama `used_at`/`revoked`).
- UI menampilkan sisa waktu (`expires_at`) dan tombol **"New code"**.

## 2. Hak akses saat mengundang

Owner memilih **tingkat** lalu **rincian fitur**:

```
Role:  ( ) Full access   ( ) View only
Akses yang diberikan:
  [x] Schedule
  [x] Homework
  [x] Preparation
  [ ] Exam
```

| Tingkat | Arti |
|---|---|
| **Full** | boleh lihat **dan ubah** fitur yang dicentang |
| **View** | hanya lihat fitur yang dicentang; tombol edit tetap ada tapi memicu **Request access** ke owner |

Default yang disarankan: **View** dengan semua fitur dicentang, kecuali owner
secara sadar memberi Full.

## 3. Caregiver

Batas yang disepakati:

| Aksi | Caregiver |
|---|---|
| Melihat jadwal/PR/persiapan sesuai grant | ✅ |
| **Menambah anak** | ❌ |
| **Menghapus anak** | ❌ |
| **Mengubah grant access anak** | ❌ |
| Mengubah data (jadwal, PR, persiapan) | ❌ default — harus **request access** ke owner |
| Menerima grant `full` dari owner | ✅ lalu boleh mengubah fitur itu |

Aturan ini harus dijaga di **dua tempat**: tombolnya disembunyikan di UI *dan*
RLS/RPC menolak bila dipanggil langsung.


- Default **view only** untuk semua fitur.
- Perubahan data (tambah/edit/hapus jadwal, PR, persiapan) harus lewat
  **request access** ke owner; owner menyetujui → grant `full` untuk fitur itu.
- Alur ini sudah punya pondasi: `LocalAccessRequest`, `child_access_grants`,
  `family_access_defaults.dart`.

## 4. Invite by link

Sasaran: link `https://bag2school.github.io/bag2school/join.html?token=...`
(atau deep link `bag2school://join-family?token=...`) yang membuka app dan
langsung memakai token.

Status sekarang: belum berfungsi. Dugaan penyebab perlu diverifikasi:

1. `family_invitation_links` belum punya `GRANT` untuk `authenticated` (pola
   yang sama dengan tabel lain sebelum migrasi grant).
2. `create_family_invitation_link` memakai `encode(..., 'base64url')` yang
   tidak didukung Postgres versi ini.
3. Token tidak ikut terkirim saat app dibuka dari browser.

Langkah perbaikan: perbaiki fungsi pembuat token, tambah grant, uji lewat
`consume_family_invitation_link`, lalu sediakan halaman `join.html` di situs.

## 5. Urutan pengerjaan

1. **R-25** migrasi kode sekali pakai + regenerasi + UI hitung mundur (migrasi sudah ditulis)
2. **R-26** matriks akses saat mengundang (UI + payload grant)
3. **R-27** caregiver view-only + request access yang benar
4. **R-28** invite by link (fungsi + halaman join + deep link)
