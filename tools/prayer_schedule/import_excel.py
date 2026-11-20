#!/usr/bin/env python3
"""Strict city/mosque prayer calendar import from CSV or XLSX; no DST hour is added manually."""
import argparse
import csv
import json
import os
import re
import tempfile
from datetime import date, datetime, time, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

PRAYERS = ("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")
IQAMA = ("fajr", "dhuhr", "asr", "maghrib", "isha")
HEADERS = ("date", *PRAYERS)
TIME_RE = re.compile(r"^([01]\d|2[0-3]):([0-5]\d)$")
ID_RE = re.compile(r"^[a-z0-9-]+$")


def to_date(value):
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    text = str(value or "").strip()
    try:
        return date.fromisoformat(text)
    except ValueError as exc:
        raise ValueError(f"Invalid ISO date: {text!r}") from exc


def to_hm(value):
    if isinstance(value, datetime):
        value = value.time()
    if isinstance(value, time):
        return value.strftime("%H:%M")
    # Excel can store time as a 0..1 day fraction in non-formatted cells.
    if isinstance(value, (float, int)) and 0 <= value < 1:
        minute = round(value * 24 * 60)
        if minute >= 1440:
            raise ValueError("Excel time fraction rounds past midnight")
        return f"{minute // 60:02}:{minute % 60:02}"
    text = str(value or "").strip()
    if not TIME_RE.fullmatch(text):
        raise ValueError(f"Expected HH:MM, got {text!r}")
    return text


def load_rows(file_path: Path):
    if file_path.suffix.lower() == ".csv":
        with file_path.open("r", encoding="utf-8-sig", newline="") as file:
            data = file.read()
        dialect = csv.Sniffer().sniff(data[:4096], delimiters=",;\t")
        return list(csv.DictReader(data.splitlines(), dialect=dialect))
    if file_path.suffix.lower() == ".xlsx":
        try:
            import openpyxl
        except ImportError as exc:
            raise RuntimeError("XLSX import requires: python3 -m pip install openpyxl") from exc
        workbook = openpyxl.load_workbook(file_path, read_only=True, data_only=True)
        try:
            sheet = workbook.active
            it = sheet.iter_rows(values_only=True)
            fields = [str(c or "").strip().lower() for c in next(it)]
            return [dict(zip(fields, row)) for row in it if any(c is not None for c in row)]
        finally:
            workbook.close()
    raise ValueError("Only .csv or .xlsx input is permitted")


def convert(rows, mosque_id: str, city: str, timezone: str, full_year: bool = False):
    if not ID_RE.fullmatch(mosque_id):
        raise ValueError("Mosque ID must use lowercase letters, digits and dashes")
    if not city.strip():
        raise ValueError("City is required")
    ZoneInfo(timezone)  # Require an authentic IANA zone; no manual summer/winter +1.
    if not rows:
        raise ValueError("At least one date is required")
    timetable, daily_iqama = {}, {}
    for idx, row in enumerate(rows, start=2):
        if any(key not in row for key in HEADERS):
            raise ValueError("Missing required headers: " + ", ".join(HEADERS))
        try:
            civil = to_date(row["date"])
            day = civil.isoformat()
            if day in timetable:
                raise ValueError("Duplicate local date")
            timetable[day] = [to_hm(row[prayer]) for prayer in PRAYERS]
            overrides = {}
            for prayer in IQAMA:
                raw = row.get("iqama_" + prayer)
                if raw is not None and str(raw).strip() != "":
                    overrides[prayer] = to_hm(raw)
            if overrides:
                daily_iqama[day] = overrides
        except Exception as exc:
            raise ValueError(f"Row {idx}: {exc}") from exc
    if full_year:
        dates = sorted(date.fromisoformat(key) for key in timetable)
        year = dates[0].year
        beginning, ending = date(year, 1, 1), date(year + 1, 1, 1)
        expected_days = (ending - beginning).days
        if len(dates) != expected_days or dates != [beginning + timedelta(days=n) for n in range(expected_days)]:
            raise ValueError("Full-year mode requires all 365/366 local dates of one calendar year")
    result = {
        "schemaVersion": 1, "mosqueId": mosque_id, "city": city.strip(),
        "timezone": timezone, "timetable": dict(sorted(timetable.items())),
        "dailyIqama": dict(sorted(daily_iqama.items()))
    }
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description="Import approved city prayer times as a single source for phone/TV")
    parser.add_argument("--input", required=True, type=Path, help="CSV or XLSX with date,fajr,sunrise,dhuhr,asr,maghrib,isha[,iqama_fajr...]")
    parser.add_argument("--mosque-id", required=True)
    parser.add_argument("--city", required=True)
    parser.add_argument("--timezone", required=True, help="IANA zone, e.g. Europe/Copenhagen")
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--full-year", action="store_true")
    args = parser.parse_args(argv)
    data = convert(load_rows(args.input), args.mosque_id, args.city, args.timezone, args.full_year)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=args.out.parent, delete=False) as f:
        temp_name = f.name
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(temp_name, args.out)
    print(f"Validated {len(data['timetable'])} dates for {data['city']} ({data['timezone']})")


if __name__ == "__main__":
    main()
