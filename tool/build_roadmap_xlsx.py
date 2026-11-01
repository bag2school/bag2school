#!/usr/bin/env python3
"""Export docs/ROADMAP.md to docs/ROADMAP.xlsx.

The Markdown file is the source of truth; this script only reads it. Run it
after editing the roadmap:

    python tool/build_roadmap_xlsx.py

Uses openpyxl (bundled Python) with a status coloured sheet, frozen header,
autofilter and sensible column widths.
"""

from __future__ import annotations

import pathlib
import re
import sys

try:
    from openpyxl import Workbook
    from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
    from openpyxl.utils import get_column_letter
    from openpyxl.worksheet.datavalidation import DataValidation
except ImportError:  # pragma: no cover
    sys.exit(
        "openpyxl tidak ditemukan. Jalankan dengan Python bawaan DSH:\n"
        "  C:\\Users\\Riandi\\.dsh\\dsh-runtimes\\dsh-primary-runtime\\"
        "dependencies\\python\\python.exe tool/build_roadmap_xlsx.py"
    )

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "ROADMAP.md"
TARGET = ROOT / "docs" / "ROADMAP.xlsx"

SECTION_RE = re.compile(r"^##\s+\d+\.\s+(.+)$")
ROW_RE = re.compile(r"^\|\s*(.+?)\s*$")

COLUMNS = ["ID", "Area", "Item", "Status", "Prioritas", "Catatan", "Commit"]

STATUS_FILL = {
    "Done": "1E7B34",
    "In progress": "B8860B",
    "Next": "2F6FB2",
    "Backlog": "6B6B6B",
    "Blocked": "B3261E",
    "Dropped": "8A8A8A",
    "—": "9E9E9E",
}

HEADER_FILL = PatternFill("solid", fgColor="FF7A21")
SECTION_FILL = PatternFill("solid", fgColor="FFF1E6")
THIN = Side(style="thin", color="E8DCD2")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)


def parse_markdown() -> list[tuple[str, list[list[str]]]]:
    """Return [(section title, rows)] with the header row removed."""
    text = SOURCE.read_text(encoding="utf-8")
    sections: list[tuple[str, list[list[str]]]] = []
    current_title: str | None = None
    current_rows: list[list[str]] = []
    in_table = False

    for line in text.split("\n"):
        section = SECTION_RE.match(line.strip())
        if section:
            if current_title:
                sections.append((current_title, current_rows))
            current_title = section.group(1).strip()
            current_rows = []
            in_table = False
            continue

        if line.startswith("|"):
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            if not in_table:
                in_table = True
                continue
            if all(set(cell) <= {"-", ":", " "} for cell in cells):
                continue
            current_rows.append(cells)
        elif in_table:
            in_table = False

    if current_title:
        sections.append((current_title, current_rows))

    return sections


def main() -> None:
    sections = parse_markdown()
    if not sections:
        sys.exit("Tidak ada tabel yang terbaca dari docs/ROADMAP.md")

    workbook = Workbook()
    sheet = workbook.active
    sheet.title = "Roadmap"

    header = ["No", *COLUMNS]
    sheet.append(header)
    for column, _ in enumerate(header, start=1):
        cell = sheet.cell(row=1, column=column)
        cell.font = Font(bold=True, color="FFFFFF", size=11)
        cell.fill = HEADER_FILL
        cell.alignment = Alignment(horizontal="center", vertical="center")
        cell.border = BORDER

    row_index = 2
    counter = 0

    for title, rows in sections:
        if not rows:
            continue

        sheet.cell(row=row_index, column=1, value=title)
        sheet.merge_cells(
            start_row=row_index, start_column=1, end_row=row_index, end_column=len(header)
        )
        section_cell = sheet.cell(row=row_index, column=1)
        section_cell.font = Font(bold=True, size=11, color="9A3E00")
        section_cell.fill = SECTION_FILL
        section_cell.alignment = Alignment(horizontal="left", vertical="center")
        row_index += 1

        for cells in rows:
            if len(cells) < len(COLUMNS):
                cells = cells + [""] * (len(COLUMNS) - len(cells))
            counter += 1
            sheet.cell(row=row_index, column=1, value=counter)
            for offset, value in enumerate(cells[: len(COLUMNS)], start=2):
                cell = sheet.cell(row=row_index, column=offset, value=value)
                cell.border = BORDER
                cell.alignment = Alignment(vertical="top", wrap_text=True)
                if offset == 5:
                    colour = STATUS_FILL.get(value.strip(), "9E9E9E")
                    cell.fill = PatternFill("solid", fgColor=colour)
                    cell.font = Font(color="FFFFFF", bold=True, size=10)
                    cell.alignment = Alignment(horizontal="center", vertical="center")
                if offset == 2:
                    cell.font = Font(bold=True)
            sheet.row_dimensions[row_index].height = 30
            row_index += 1

    widths = {"A": 5, "B": 12, "C": 16, "D": 52, "E": 12, "F": 9, "G": 44, "H": 16}
    for column, width in widths.items():
        sheet.column_dimensions[column].width = width

    sheet.freeze_panes = "A2"
    sheet.auto_filter.ref = f"A1:{get_column_letter(len(header))}{row_index - 1}"

    validation = DataValidation(
        type="list",
        formula1='"Done,In progress,Next,Backlog,Blocked,Dropped"',
        allow_blank=True,
    )
    sheet.add_data_validation(validation)
    validation.add(f"E2:E{max(row_index - 1, 2)}")

    summary = workbook.create_sheet("Ringkasan")
    summary.append(["Status", "Jumlah"])
    summary["A1"].font = Font(bold=True, color="FFFFFF")
    summary["B1"].font = Font(bold=True, color="FFFFFF")
    summary["A1"].fill = HEADER_FILL
    summary["B1"].fill = HEADER_FILL

    counts: dict[str, int] = {}
    for _, rows in sections:
        for cells in rows:
            status = cells[3] if len(cells) > 3 else "—"
            counts[status] = counts.get(status, 0) + 1

    for status in ["Done", "In progress", "Next", "Backlog", "Blocked", "Dropped"]:
        summary.append([status, counts.get(status, 0)])

    summary.append(["Total", sum(counts.values())])
    summary["A8"].font = Font(bold=True)
    summary["B8"].font = Font(bold=True)
    summary.column_dimensions["A"].width = 18
    summary.column_dimensions["B"].width = 10

    import os

    temp = TARGET.with_suffix(".tmp.xlsx")
    workbook.save(temp)

    try:
        os.replace(temp, TARGET)
        written = TARGET
    except PermissionError:
        # The workbook is open in Excel; keep a clearly named copy instead.
        fallback = TARGET.with_name("ROADMAP_updated.xlsx")
        os.replace(temp, fallback)
        written = fallback
        print(
            "PERHATIAN: ROADMAP.xlsx sedang dibuka (terkunci).\n"
            f"Versi baru ditulis ke {fallback.name}; tutup Excel lalu jalankan lagi."
        )

    print(f"wrote {written.relative_to(ROOT)}")
    print(f"  item: {sum(counts.values())}, selesai: {counts.get('Done', 0)}")
    for status in ["In progress", "Next", "Backlog", "Blocked", "Dropped"]:
        if counts.get(status):
            print(f"  {status}: {counts[status]}")


if __name__ == "__main__":
    main()
