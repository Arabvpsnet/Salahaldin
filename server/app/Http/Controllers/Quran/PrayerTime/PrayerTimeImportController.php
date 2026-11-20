<?php

namespace App\Http\Controllers\Quran\PrayerTime;

use App\Http\Controllers\Controller;
use App\Models\Quran\Prayer\PrayerTime;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Shuchkin\SimpleXLSX;

class PrayerTimeImportController extends Controller
{
    public function index()
    {
    }

    public function import(Request $request)
    {
        // Route is already protected by auth/permissions; validate file before parsing.
        $validated = $request->validate([
            'file' => ['required', 'file', 'mimes:xlsx', 'max:5120'],
        ]);
        try {
            $file = $validated['file'];
            $xlsx = SimpleXLSX::parse($file->getRealPath());
            if (!$xlsx) {
                return response()->json(['message' => 'Invalid spreadsheet'], 422);
            }
            $rows = $xlsx->rows();
            if (count($rows) < 3 || count($rows) > 10005) {
                return response()->json(['message' => 'Invalid spreadsheet row count'], 422);
            }
            $headers = array_filter($rows[0] ?? []);
            DB::transaction(function () use ($rows, $headers) {
                foreach (array_slice($rows, 2) as $prayerTimes) {
                    foreach (array_chunk($prayerTimes, 10) as $i => $times) {
                        if (count($times) < 10) {
                            continue;
                        }
                        $city = $i == 0 ? ($headers[0] ?? 'Unknown') : ($headers[10 * $i] ?? 'Unknown');
                        $date = Carbon::parse($times[0])->format('Y-m-d');
                        $record = [
                            'city' => mb_substr((string) $city, 0, 120),
                            'date' => $date,
                            'imsak' => $this->timeFormat($times[1]),
                            'sunrise' => $this->timeFormat($times[2]),
                            'fajr_start' => $this->timeFormat($times[3]),
                            'zuhr_start' => $this->timeFormat($times[4]),
                            'asr_start' => $this->timeFormat($times[5]),
                            'maghrib_start' => $this->timeFormat($times[6]),
                            'isha_start' => $this->timeFormat($times[7]),
                            'sehri' => $this->timeFormat($times[8]),
                            'iftar' => $this->timeFormat($times[9])
                        ];
                        PrayerTime::updateOrCreate(['city' => $record['city'], 'date' => $date], $record);
                    }
                }
            }, 2);
            return response()->json(['message' => 'Data imported successfully'], 201);
        } catch (\Throwable $exception) {
            // Never leak stack traces, file paths, DB credentials or row payloads to clients.
            Log::warning('Prayer time import rejected', ['exception_type' => get_class($exception)]);
            return response()->json(['message' => 'Data import failed'], 422);
        }
    }

    private function timeFormat($input, $format = 'H:i:s')
    {
        if (!is_string($input)) {
            return null;
        }
        if (preg_match('/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/', $input)) {
            return Carbon::parse($input)->format($format);
        }
        if (preg_match('/^(?:[01]?[0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9])?(?:\s?[APMapm]{2})?$/', $input)) {
            return Carbon::parse($input)->format($format);
        }
        return null;
    }
}
