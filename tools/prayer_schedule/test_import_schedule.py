import unittest
from datetime import date
from pathlib import Path
import importlib.util

spec = importlib.util.spec_from_file_location("import_schedule", Path(__file__).with_name("import_excel.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ScheduleImportTests(unittest.TestCase):
    def row(self, when, iqama="13:20"):
        return dict(date=when, fajr="05:20", sunrise="07:12", dhuhr="12:14",
                    asr="14:40", maghrib="17:04", isha="18:31", iqama_dhuhr=iqama)

    def test_copenhagen_summer_and_winter_keep_local_wall_clock(self):
        x = module.convert([self.row("2026-03-29"), self.row("2026-10-25")], "fredericia", "Fredericia", "Europe/Copenhagen")
        self.assertEqual(x["timetable"]["2026-03-29"][2], "12:14")
        self.assertEqual(x["timetable"]["2026-10-25"][2], "12:14")
        self.assertEqual(x["dailyIqama"]["2026-10-25"]["dhuhr"], "13:20")

    def test_rejects_invalid_clock_time(self):
        row = self.row("2026-11-20")
        row["asr"] = "25:30"
        with self.assertRaises(ValueError):
            module.convert([row], "fredericia", "Fredericia", "Europe/Copenhagen")

    def test_rejects_duplicate_dates(self):
        with self.assertRaises(ValueError):
            module.convert([self.row("2026-11-20")] * 2, "fredericia", "Fredericia", "Europe/Copenhagen")

    def test_rejects_non_iana_timezone(self):
        with self.assertRaises(Exception):
            module.convert([self.row("2026-11-20")], "fredericia", "Fredericia", "Copenhagen")

    def test_rejects_incomplete_year_in_full_year_mode(self):
        with self.assertRaises(ValueError):
            module.convert([self.row("2026-11-20")], "fredericia", "Fredericia", "Europe/Copenhagen", True)


if __name__ == "__main__":
    unittest.main()
