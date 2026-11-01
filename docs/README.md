# Dokumentasi & peta kode

Folder ini berisi peta proyek untuk manusia dan AI.

## Isi

| Berkas | Sumber | Untuk apa |
|---|---|---|
| [ROADMAP.md](ROADMAP.md) | manual | Rencana kerja: selesai, berikutnya, backlog, terhambat |
| [ROADMAP.xlsx](ROADMAP.xlsx) | generate | Versi Excel (filter, warnai status, cetak) |
| [knowledge-graph.md](knowledge-graph.md) | manual | Modul, alur auth/keluarga/data, matriks izin, risiko, rencana split |
| [SYMBOL_INDEX.md](SYMBOL_INDEX.md) | generate | 613 method → class + baris, untuk di-grep |
| [AI_CONTEXT.md](AI_CONTEXT.md) | manual | Konteks ringkas (±1.300 token) untuk ditempel ke model AI mana pun |
| [features/](features/) | generate | Satu catatan per fitur + wiki-link (untuk Obsidian) |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | manual | Gejala umum: connection refused 54321, Supabase mati, mojibake, lock flutter |
| [generated/architecture-map.md](generated/architecture-map.md) | generate | Tabel & diagram otomatis (jangan diedit manual) |
| [../graph/nodes.json](../graph/nodes.json) | generate | Nodes + edges mentah (130 class, 253 edge) |
| [../graph/bag2school.canvas](../graph/bag2school.canvas) | generate | Peta visual untuk Obsidian Canvas |

## Pakai di Obsidian

1. **Open folder as vault** → pilih root proyek (`bag_2_school`).
2. Settings → **Files & Links → Excluded files**, tambahkan:
   ```
   build/
   .git/
   archive/
   android/
   ios/
   graph/nodes.json
   graph/imports.dot
   ```
3. Buka `docs/knowledge-graph.md` lalu tekan **Ctrl+E** (Reading view).
   Diagram Mermaid langsung ter-render.
4. Untuk peta visual: buka `graph/bag2school.canvas` — 79 kartu, 167 panah
   ketergantungan. Bisa di-drag, di-zoom, dan diklik.
5. **Graph View** (Ctrl+G) akan menampilkan 6 catatan fitur + knowledge-graph +
   AI_CONTEXT yang saling terhubung. Tambahkan `docs/features` ke favorit.

## Pakai dengan model AI lain

| Kebutuhan | Berkas yang ditempel |
|---|---|
| Chat baru, tugas apa pun | `docs/AI_CONTEXT.md` (±1.300 token) |
| Refactor / pindah kode | `AI_CONTEXT.md` + `knowledge-graph.md` |
| Kerja di satu fitur | `AI_CONTEXT.md` + `docs/features/<fitur>.md` + file layarnya |
| Agent di editor | biarkan membaca `AGENTS.md` di root (menunjuk ke AI_CONTEXT) |

`graph/nodes.json` sebaiknya **dibaca sebagai file**, bukan ditempel utuh
(±24.000 token).

## Memperbarui

```powershell
python tool/build_knowledge_graph.py   # nodes.json, imports.dot, architecture-map
python tool/build_obsidian.py          # features/*.md, bag2school.canvas
python tool/build_symbol_index.py      # SYMBOL_INDEX.md
python tool/build_roadmap_xlsx.py      # ROADMAP.xlsx dari ROADMAP.md
```

Jalankan setiap kali ada file/class/layar baru. `knowledge-graph.md` dan
`AI_CONTEXT.md` diperbarui manual karena berisi keputusan, bukan hasil parsing.

## Test

```powershell
$dart='D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe'
$snap='D:\Flutter\flutter\bin\cache\flutter_tools.snapshot'
& $dart $snap test
```

27 test, ±1 detik, tanpa perlu menyalakan HP:

| Berkas | Cakupan |
|---|---|
| `test/activity_models_test.dart` | recurrence (none/daily/weekdays/weekly/biweekly/monthly/custom/endDate), `PreparationItem.occursOn`, `HomeworkItem.copyWith`, `ActivityConflictDetector` |
| `test/serializers_test.dart` | round-trip JSON aktivitas/persiapan/PR, fallback data rusak, enum tak dikenal, helper tanggal |

