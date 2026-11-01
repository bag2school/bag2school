---
name: Bag2School
description: Sistem visual hangat untuk membantu keluarga menyiapkan hari sekolah.
colors:
  orange-utama: "#FF7A21"
  oranye-lembut: "#FFE8D5"
  persik-pucat: "#FFF1E6"
  krem-latar: "#FFFCF8"
  tinta-hangat: "#302722"
  teks-redup: "#756B65"
  ungu-tugas: "#7661D8"
  ungu-lembut: "#F0EDFF"
  teal-aktivitas: "#2A9D8F"
  hijau-selesai: "#55A56B"
typography:
  headline:
    fontFamily: "Roboto, sans-serif"
    fontSize: "20px"
    fontWeight: 900
  title:
    fontFamily: "Roboto, sans-serif"
    fontSize: "15px"
    fontWeight: 800
  body:
    fontFamily: "Roboto, sans-serif"
    fontSize: "13.5px"
    fontWeight: 600
  label:
    fontFamily: "Roboto, sans-serif"
    fontSize: "12px"
    fontWeight: 700
rounded:
  sm: "7px"
  md: "16px"
  lg: "18px"
  xl: "28px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "20px"
components:
  tombol-utama:
    backgroundColor: "{colors.orange-utama}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "14px 20px"
  bidang-input:
    backgroundColor: "#FFFFFF"
    textColor: "{colors.tinta-hangat}"
    rounded: "{rounded.md}"
    padding: "16px"
  kartu-jadwal:
    backgroundColor: "#FFFFFF"
    textColor: "{colors.tinta-hangat}"
    rounded: "{rounded.xl}"
    padding: "18px 16px 14px"
  navigasi-bawah:
    backgroundColor: "{colors.persik-pucat}"
    textColor: "{colors.tinta-hangat}"
    rounded: "{rounded.md}"
    padding: "8px"
  chip-hari:
    backgroundColor: "{colors.oranye-lembut}"
    textColor: "{colors.tinta-hangat}"
    rounded: "{rounded.md}"
    padding: "8px 12px"
---

# Sistem Desain: Bag2School

## Overview

**Creative North Star: "Pendamping Hangat Hari Sekolah"**

Bag2School terasa seperti pendamping keluarga yang ramah saat orang tua memeriksa jadwal, persiapan, dan pekerjaan rumah anak. Kanvas krem, permukaan putih yang terangkat lembut, serta aksen oranye membentuk suasana hangat tanpa mengurangi kejelasan informasi. Bagi hadir sebagai teman yang suportif di dalam alur kerja, bukan sebagai hiasan yang mengalihkan perhatian.

Antarmuka memakai pola Material 3 Android dengan bentuk membulat, tombol responsif, dan navigasi bawah yang akrab. Teks Roboto yang tebal membantu orang tua memindai agenda dan status dengan cepat. Ungu dan teal memberi pembeda ringan untuk jenis aktivitas, sementara oranye tetap menjadi aksen utama.

**Key Characteristics:**
- Hangat dan menenangkan melalui latar krem serta permukaan putih.
- Ramah dan taktil lewat kontrol Material 3 dan sudut membulat.
- Mudah dipindai dengan judul tegas dan aksen warna kontekstual.
- Berpusat pada anak dan keluarga; Bagi menyampaikan dukungan dengan singkat.

## Colors

Palet krem dan oranye memimpin; ungu dan teal membedakan konteks tugas, dengan warna tinta hangat menjaga keterbacaan.

### Primary
- **Oranye Teman Sekolah**: warna aksi utama untuk tombol, ikon aktif, sorotan, dan umpan balik interaksi.
- **Oranye Lembut**: bidang indikator terpilih dan aksen pendukung di sekitar tindakan utama.

### Secondary
- **Ungu Pekerjaan Rumah**: menandai pekerjaan rumah dan konteks terkait tanpa bersaing dengan aksi utama.
- **Teal Aktivitas**: aksen untuk aktivitas dan status terkait.

### Neutral
- **Krem Pagi**: latar layar utama yang hangat.
- **Tinta Hangat**: judul dan teks utama.
- **Abu Hangat**: teks sekunder, waktu, dan keterangan.
- **Putih**: bidang kartu dan isian.
- **Hijau Siap**: menandai tugas yang selesai atau siap.

**Aturan Aksen Kontekstual.** Oranye memimpin tindakan; ungu dan teal dipakai untuk membantu membedakan jenis tugas, bukan sebagai warna aksi umum.

## Typography

**Display Font:** Roboto (fallback sans-serif sistem Android)  
**Body Font:** Roboto (fallback sans-serif sistem Android)  
**Label/Mono Font:** Tidak ada keluarga monospace khusus.

**Character:** Sans-serif sistem yang familier menjaga tampilan terasa langsung dan mudah dibaca. Hierarki dibentuk terutama melalui ukuran dan bobot tebal, bukan pergantian keluarga huruf.

### Hierarchy
- **Headline** (tebal sangat kuat, sekitar 19–21 px): judul layar dan bagian penting.
- **Title** (tebal, sekitar 15–18 px): nama aktivitas, anak, dan item daftar.
- **Body** (sedang hingga semitebal, sekitar 13–15 px): isi, waktu, dan keterangan yang perlu dipindai.
- **Label** (semitebal hingga tebal, sekitar 10–12 px): label navigasi, metadata, dan status singkat.

**Aturan Skala Teks.** Gunakan gaya teks Material dan ukuran relatif terhadap skala sistem; ukuran di atas merangkum pola yang terlihat, bukan larangan terhadap penskalaan aksesibilitas.

## Layout

Layar ponsel menyusun konten dalam satu kolom dengan padding yang lazimnya 16–20 px. Bagian jadwal dan daftar memakai kartu putih, sementara panel fokus dapat memakai bidang lembut sesuai konteks. Jarak antaritem cukup rapat untuk pemantauan harian, tetapi padding kartu tetap memberi ruang sentuh dan pemisahan visual. Navigasi utama berada di bawah dengan lima tujuan. Pertahankan insets sistem Android dan perilaku adaptif Material 3 saat menambah layar atau ukuran perangkat.

## Elevation & Depth

Kedalaman terutama berasal dari kontras tonal antara latar krem, bidang aksen pastel, dan kartu putih. Kartu jadwal memakai bayangan hitam yang sangat halus (10% opasitas, blur 14 px, offset vertikal 5 px); gunakan bayangan serupa sebagai pemisah ambient, bukan efek dramatis. FAB memakai elevasi Material untuk menegaskan aksi utama.

**Aturan Kartu Terangkat Lembut.** Kartu putih boleh sedikit terangkat dari latar; gunakan tonal layering terlebih dahulu dan bayangan halus hanya jika perlu memisahkan bidang.

## Shapes

Bentuk antarmuka bersudut membulat dan bersahabat. Kartu besar umumnya menggunakan radius sekitar 24–30 px, tombol serta kolom isian sekitar 14–18 px, dan ikon dalam wadah kecil sekitar 12–15 px. Pilih radius konsisten dengan skala komponen yang sudah ada; hindari sudut tajam yang terasa asing di antara kartu lembut.

## Components

### Buttons
- **Karakter:** ramah dan taktil, mengikuti komponen Material 3.
- **Primary:** FilledButton oranye dengan teks putih; contoh layar memakai padding vertikal sekitar 14 px dan radius 14–18 px.
- **Focus / press:** pertahankan overlay interaksi Material dengan ripple; durasi animasi tema sekitar 120 ms.
- **Secondary:** tombol outlined dan text memakai aksen interaksi oranye dengan bobot visual lebih ringan.

### Chips
- **Style:** FilterChip atau ChoiceChip Material, dengan bidang pastel dan label ringkas.
- **State:** gunakan oranye lembut untuk pilihan utama; ungu lembut dapat mempertahankan konteks pekerjaan rumah.

### Cards / Containers
- **Corner Style:** kartu besar membulat lembut (sekitar 26–28 px).
- **Background:** putih untuk daftar dan jadwal; krem, persik, ungu lembut, atau warna kontekstual untuk panel sorotan.
- **Shadow Strategy:** bayangan ambient yang samar atau pemisahan melalui warna bidang.
- **Internal Padding:** umumnya 16–20 px; sesuaikan dengan kepadatan isi.

### Inputs / Fields
- **Style:** bidang putih terisi atau outlined, dengan garis tepi oranye pucat dan radius sekitar 16–18 px.
- **Focus:** pertahankan state fokus dan ripple standar Material 3; ikon awalan boleh memakai oranye.
- **Error / Disabled:** gunakan state semantik Material, jaga label dan pesan tetap terbaca.

### Navigation
- **Style:** NavigationBar Material 3 di bagian bawah untuk lima tujuan pada ponsel.
- **Default / active:** latar persik pucat, indikator terpilih oranye lembut, dan ikon terpilih berisi.
- **Behavior:** pertahankan navigasi sistem Back dan insets Android.

### Ringkasan Jadwal
Gunakan ikon aktivitas dalam wadah berwarna lembut, lalu judul tegas dan waktu sekunder. Warna ikon boleh membedakan kategori aktivitas, sementara isi teks tetap menjadi sumber informasi utama.

### Pendamping Bagi
Bagi menyapa dan memberi arahan pendek dengan nada hangat dan suportif. Letakkan karakter di dalam konteks onboarding atau panduan yang relevan, tanpa menutupi tindakan inti.

## Do's and Don'ts

### Do:
- **Do** gunakan oranye untuk aksi utama dan aksen interaksi.
- **Do** gunakan ungu dan teal untuk membedakan konteks pekerjaan rumah serta aktivitas.
- **Do** pertahankan kartu putih, latar krem, teks tinta hangat, dan sudut membulat.
- **Do** gunakan komponen Material 3 Android dan jaga target sentuh minimal 48 × 48 dp.
- **Do** biarkan teks mengikuti pengaturan ukuran font sistem.
- **Do** gunakan Bagi untuk dukungan yang singkat, ramah, dan relevan dengan alur.

### Don't:
- **Don't** menjadikan ungu atau teal sebagai pengganti aksen oranye untuk semua tindakan utama.
- **Don't** menambahkan bayangan berat pada kartu yang sudah terbaca lewat perbedaan warna bidang.
- **Don't** mengandalkan warna saja untuk menjelaskan status; sertakan label atau ikon yang jelas.
- **Don't** mengganti pola Material Android dengan kontrol bergaya platform lain.
