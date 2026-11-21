import unittest

from validate_dataset import canonical_counts, validate_translation


class QuranEditionValidationTests(unittest.TestCase):
    def setUp(self):
        self.counts = [2, 1]
        self.rows = [
            {"id": 1, "surah": 1, "ayah": 1, "text": "synthetic text A"},
            {"id": 2, "surah": 1, "ayah": 2, "text": "synthetic text B"},
            {"id": 3, "surah": 2, "ayah": 1, "text": "synthetic text C"},
        ]

    def test_real_114_surah_canonical_boundaries(self):
        counts = canonical_counts()
        self.assertEqual(len(counts), 114)
        self.assertEqual(sum(counts), 6236)
        self.assertEqual(counts[0], 7)
        self.assertEqual(counts[-1], 6)

    def test_accepts_complete_synthetic_dataset(self):
        self.assertEqual(validate_translation(self.rows, self.counts),
                         {"surahs": 2, "verses": 3})

    def test_rejects_missing_and_duplicate_verses(self):
        with self.assertRaises(ValueError):
            validate_translation(self.rows[:-1], self.counts)
        rows = [dict(x) for x in self.rows]
        rows[1]["id"] = 1
        with self.assertRaises(ValueError):
            validate_translation(rows, self.counts)

    def test_rejects_ayah_mismatch_empty_text_and_injection(self):
        for key, value in [("ayah", 3), ("text", ""), ("text", "abc\u202edef")]:
            rows = [dict(x) for x in self.rows]
            rows[0][key] = value
            with self.assertRaises(ValueError):
                validate_translation(rows, self.counts)


if __name__ == "__main__":
    unittest.main()
