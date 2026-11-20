# Excel prayer calendar import

1. Provide CSV or XLSX with headers: `date,fajr,sunrise,dhuhr,asr,maghrib,isha,iqama_fajr,iqama_dhuhr,iqama_asr,iqama_maghrib,iqama_isha`. Optional iqama columns may be omitted.
2. Every row is a **local calendar date** (YYYY-MM-DD) and prayer time (HH:MM). Enter published summer and winter times exactly as approved by the mosque. Do not adjust DST manually.
3. For XLSX files install `python3 -m pip install openpyxl`. CSV uses only Python standard libraries.

Example:

```sh
python3 tools/prayer_schedule/import_excel.py \
  --input fredericia-2027.xlsx \
  --mosque-id fredericia --city Fredericia \
  --timezone Europe/Copenhagen --full-year \
  --out server/storage/app/prayer/schedules/fredericia.json
```

The importer validates dates, time strings, duplicate rows, timezone and optionally all 365/366 days; it writes JSON atomically. Configure the TV `VITE_SALAHALDIN_API_BASE` and `VITE_SALAHALDIN_MOSQUE_ID`. The screen consumes these exact times and day-specific iqamas. A privileged web-based importer and mobile mosque subscription are separate incomplete tasks.
