import { CalculationMethod, CalculationParameters, Coordinates, HighLatitudeRule, Madhab, PrayerTimes } from 'adhan';
import { methodById } from '../data/methods';
import { PRAYERS, type PrayerKey, type SalahKey, type Settings } from './settings';
import { addDays, fromZoned, parseHM, todayIn, ymdKey, pad, type YMD } from './time';

export type Source = 'calc' | 'api' | 'table';
export interface DayTimes { date: YMD; times: Record<PrayerKey, Date>; source: Source }

/* ------------------------------------------------------------------ */
/*  1. Local astronomical calculation (offline, adhan-js)              */
/* ------------------------------------------------------------------ */

export function buildParams(s: Settings, ramadan = false): CalculationParameters {
  const def = methodById(s.calc.method);
  let p: CalculationParameters;
  if (def.id === 'custom') {
    p = new CalculationParameters('Other', s.calc.fajrAngle, s.calc.ishaAngle, s.calc.ishaInterval || 0);
  } else if (def.adhanPreset) {
    p = CalculationMethod[def.adhanPreset]();
  } else {
    p = new CalculationParameters('Other', def.fajr, def.isha, def.ishaInterval || 0, def.maghribAngle || 0);
  }
  if (def.maghribAdj || def.dhuhrAdj) {
    p.methodAdjustments = { ...p.methodAdjustments, dhuhr: (p.methodAdjustments.dhuhr || 0) + (def.dhuhrAdj || 0), maghrib: (p.methodAdjustments.maghrib || 0) + (def.maghribAdj || 0) };
  }
  // Umm al-Qura: Isha is 120 min after Maghrib during Ramadan.
  if (def.id === 'makkah' && ramadan) p.ishaInterval = 120;
  p.madhab = s.calc.madhab === 'hanafi' ? Madhab.Hanafi : Madhab.Shafi;
  p.highLatitudeRule =
    s.calc.highLat === 'middle' ? HighLatitudeRule.MiddleOfTheNight
    : s.calc.highLat === 'seventh' ? HighLatitudeRule.SeventhOfTheNight
    // 'auto' = angle-based portions, the convention used by Aladhan, IslamicFinder and most timetables.
    : HighLatitudeRule.TwilightAngle;
  return p;
}

export function calcDay(s: Settings, date: YMD, ramadan = false): DayTimes {
  const coords = new Coordinates(s.location.lat, s.location.lng);
  // adhan reads the local Y/M/D of the Date it receives, so build it from the mosque's calendar day.
  const pt = new PrayerTimes(coords, new Date(date.y, date.m - 1, date.d, 12), buildParams(s, ramadan));
  return {
    date, source: 'calc',
    times: { fajr: pt.fajr, sunrise: pt.sunrise, dhuhr: pt.dhuhr, asr: pt.asr, maghrib: pt.maghrib, isha: pt.isha },
  };
}

/* ------------------------------------------------------------------ */
/*  2. Aladhan API (monthly calendar, cached for offline use)          */
/* ------------------------------------------------------------------ */

const API_CACHE = 'salahaldin.aladhan.v2.';

function apiParams(s: Settings): string {
  const def = methodById(s.calc.method);
  const q = new URLSearchParams({
    latitude: String(s.location.lat), longitude: String(s.location.lng),
    school: s.calc.madhab === 'hanafi' ? '1' : '0',
    timezonestring: s.location.timezone,
    iso8601: 'false',
  });
  if (def.aladhan === 99) {
    const fajr = def.id === 'custom' ? s.calc.fajrAngle : def.fajr;
    const isha = def.id === 'custom' ? (s.calc.ishaInterval ? `${s.calc.ishaInterval} min` : s.calc.ishaAngle) : def.isha;
    q.set('method', '99');
    q.set('methodSettings', `${fajr},null,${isha}`);
  } else q.set('method', String(def.aladhan));
  q.set('latitudeAdjustmentMethod', s.calc.highLat === 'middle' ? '1' : s.calc.highLat === 'seventh' ? '2' : '3');
  return q.toString();
}

function apiCacheKey(s: Settings, y: number, m: number) {
  return `${API_CACHE}${y}-${pad(m)}:${apiParams(s)}`;
}

type ApiMonth = Record<string, string[]>; // YYYY-MM-DD → six normalized HH:MM times

/** Keep only valid Aladhan wall-clock values; reject missing, malformed or misleading data. */
function aladhanTime(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const match = /^([01]\d|2[0-3]):([0-5]\d)(?:\s+\([^()]{1,40}\))?$/.exec(value.trim());
  return match ? match[1] + ':' + match[2] : null;
}

function validCivilDate(y: number, m: number, d: number): boolean {
  if (![y, m, d].every(Number.isInteger) || y < 1900 || y > 2200) return false;
  const date = new Date(Date.UTC(y, m - 1, d));
  return date.getUTCFullYear() === y && date.getUTCMonth() === m - 1 &&
    date.getUTCDate() === d;
}

function validApiMonth(value: unknown, year: number, month: number): value is ApiMonth {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return false;
  const days = Object.entries(value);
  const maxDays = new Date(Date.UTC(year, month, 0)).getUTCDate();
  if (days.length !== maxDays) return false;
  return days.every(([key, times]) => {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(key);
    return Boolean(match && Number(match[1]) === year && Number(match[2]) === month &&
      validCivilDate(year, month, Number(match[3])) && Array.isArray(times) &&
      times.length === PRAYERS.length && times.every((time) => aladhanTime(time) === time));
  });
}

/** Convert one *complete* Aladhan month to trustworthy local wall-clock values. */
export function parseAladhanMonth(input: unknown, year: number, month: number): ApiMonth {
  if (!input || typeof input !== 'object') throw new Error('Invalid Aladhan response');
  const payload = input as { code?: number; data?: unknown };
  if (payload.code !== 200 || !Array.isArray(payload.data)) throw new Error('Invalid Aladhan response');
  const maxDays = new Date(Date.UTC(year, month, 0)).getUTCDate();
  if (payload.data.length !== maxDays || payload.data.length > 31) throw new Error('Incomplete Aladhan month');
  const result: ApiMonth = Object.create(null);
  for (const entry of payload.data) {
    if (!entry || typeof entry !== 'object') throw new Error('Invalid Aladhan day');
    const value = entry as { date?: { gregorian?: { date?: unknown } }; timings?: unknown };
    const dayText = value.date?.gregorian?.date;
    if (typeof dayText !== 'string') throw new Error('Aladhan day lacks a date');
    const match = /^(\d{2})-(\d{2})-(\d{4})$/.exec(dayText);
    if (!match) throw new Error('Malformed Aladhan Gregorian date');
    const d = Number(match[1]), m = Number(match[2]), y = Number(match[3]);
    const dateKey = ymdKey({ y, m, d });
    if (y !== year || m !== month || !validCivilDate(y, m, d) ||
        Object.prototype.hasOwnProperty.call(result, dateKey)) {
      throw new Error('Unexpected or repeated Aladhan date');
    }
    const raw = value.timings as Record<string, unknown> | undefined;
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new Error('Aladhan times missing');
    const times = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((key) => aladhanTime(raw[key]));
    if (times.some((time) => time === null)) throw new Error('Invalid Aladhan clock time');
    result[dateKey] = times as string[];
  }
  if (!validApiMonth(result, year, month)) throw new Error('Incomplete Aladhan month');
  return result;
}

export async function fetchApiMonth(s: Settings, y: number, m: number): Promise<ApiMonth> {
  const key = apiCacheKey(s, y, m);
  try {
    const raw = localStorage.getItem(key);
    if (raw) {
      const cached: unknown = JSON.parse(raw);
      if (validApiMonth(cached, y, m)) return cached;
      localStorage.removeItem(key);
    }
  } catch { /* corrupted or unavailable storage — fetch fresh data */ }
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);
  let out: ApiMonth;
  try {
    const response = await fetch('https://api.aladhan.com/v1/calendar/' + y + '/' + m + '?' + apiParams(s),
      { signal: controller.signal, cache: 'no-store' });
    if (!response.ok) throw new Error('Aladhan HTTP ' + response.status);
    if (Number(response.headers.get('content-length') || 0) > 400000) {
      throw new Error('Aladhan response too large');
    }
    const body = await response.text();
    if (body.length > 400000) throw new Error('Aladhan response too large');
    out = parseAladhanMonth(JSON.parse(body) as unknown, y, m);
  } finally {
    clearTimeout(timeout);
  }
  try {
    // Keep current and following month. A cached response is always schema-checked on reuse.
    const now = todayIn(s.location.timezone);
    const next = addDays({ ...now, d: 28 }, 7);
    const keep = [apiCacheKey(s, now.y, now.m), apiCacheKey(s, next.y, next.m), key];
    for (let i = localStorage.length - 1; i >= 0; i--) {
      const k = localStorage.key(i);
      if (k && k.startsWith(API_CACHE) && !keep.includes(k)) localStorage.removeItem(k);
    }
    localStorage.setItem(key, JSON.stringify(out));
  } catch { /* full/private storage — still use fresh data */ }
  return out;
}

function cachedApiDay(s: Settings, date: YMD): string[] | null {
  try {
    const raw = localStorage.getItem(apiCacheKey(s, date.y, date.m));
    if (!raw) return null;
    const cached: unknown = JSON.parse(raw);
    if (!validApiMonth(cached, date.y, date.m)) return null;
    return cached[ymdKey(date)] ?? null;
  } catch { return null; }
}

/* ------------------------------------------------------------------ */
/*  3. Imported official timetable (CSV)                               */
/* ------------------------------------------------------------------ */

function tableDay(s: Settings, date: YMD): string[] | null {
  return s.timetable[ymdKey(date)] ?? s.timetable[`${pad(date.m)}-${pad(date.d)}`] ?? null;
}

/**
 * Accepts CSV/TSV/semicolon files with a date column then 6 times:
 *   date, fajr, sunrise, dhuhr, asr, maghrib, isha
 * Dates: YYYY-MM-DD, DD/MM/YYYY, DD-MM-YYYY or DD/MM (yearly table). A header row is skipped.
 */
/** Preserve empty CSV cells and support quoted fields (comma, semicolon or tab). */
function csvCells(line: string): string[] | null {
  const cells: string[] = [];
  let cell = '', quoted = false, closed = false;
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (char === '"') {
      if (quoted && line[i + 1] === '"') { cell += '"'; i++; }
      else if (!quoted && cell === '') quoted = true;
      else if (quoted) { quoted = false; closed = true; }
      else return null;
    } else if (!quoted && (char === ',' || char === ';' || char === '\t')) {
      cells.push(cell.trim()); cell = ''; closed = false;
    } else {
      if (closed && char.trim()) return null;
      cell += char;
    }
  }
  if (quoted) return null;
  cells.push(cell.trim());
  return cells;
}

function importClock(value: string): string | null {
  const match = /^([01]?\d|2[0-3]):([0-5]\d)$/.exec(value);
  return match ? pad(Number(match[1])) + ':' + match[2] : null;
}

/**
 * Import official CSV/TSV, preserving column positions and rejecting impossible dates.
 * A row is date, fajr, sunrise, dhuhr, asr, maghrib, isha.
 * Dates: YYYY-MM-DD, DD/MM/YYYY, DD-MM-YYYY, DD/MM (yearly table).
 */
export function parseTimetable(text: string): { rows: Record<string, string[]>; errors: number } {
  const rows: Record<string, string[]> = Object.create(null);
  if (text.length > 512 * 1024) return { rows, errors: 1 };
  let errors = 0;
  for (const raw of text.replace(/^\uFEFF/, '').split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const cells = csvCells(line);
    if (!cells || cells.length < 7) {
      if (/\d/.test(line)) errors++;
      continue;
    }
    if (/^date$/i.test(cells[0]) || /^datum$/i.test(cells[0])) continue;
    const key = parseDateCell(cells[0]);
    const times = cells.slice(1, 7).map(importClock);
    if (!key || times.some((time) => time === null) ||
        Object.prototype.hasOwnProperty.call(rows, key) || Object.keys(rows).length >= 800) {
      errors++;
      continue;
    }
    rows[key] = times as string[];
  }
  return { rows, errors };
}

function parseDateCell(raw: string): string | null {
  let m = /^(\d{4})-(\d{1,2})-(\d{1,2})$/.exec(raw);
  if (m) {
    const year = Number(m[1]), month = Number(m[2]), day = Number(m[3]);
    return validCivilDate(year, month, day) ? ymdKey({ y: year, m: month, d: day }) : null;
  }
  m = /^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$/.exec(raw);
  if (m) {
    const day = Number(m[1]), month = Number(m[2]), year = Number(m[3]);
    return validCivilDate(year, month, day) ? ymdKey({ y: year, m: month, d: day }) : null;
  }
  m = /^(\d{1,2})[/.-](\d{1,2})$/.exec(raw);
  if (m) {
    const day = Number(m[1]), month = Number(m[2]);
    return validCivilDate(2000, month, day) ? pad(month) + '-' + pad(day) : null;
  }
  return null;
}

/* ------------------------------------------------------------------ */
/*  Public API                                                         */
/* ------------------------------------------------------------------ */

function fromStrings(s: Settings, date: YMD, arr: string[], source: Source): DayTimes | null {
  const times = {} as Record<PrayerKey, Date>;
  for (let i = 0; i < PRAYERS.length; i++) {
    const v = parseHM(arr[i]);
    if (v === null) return null;
    times[PRAYERS[i]] = fromZoned(date.y, date.m, date.d, Math.floor(v / 60), v % 60, s.location.timezone);
  }
  return { date, times, source };
}

function applyAdjustments(s: Settings, day: DayTimes): DayTimes {
  const t = { ...day.times };
  for (const k of PRAYERS) t[k] = new Date(t[k].getTime() + (s.calc.adjust[k] || 0) * 60000);
  return { ...day, times: t };
}

/** Times for a calendar day in the mosque's zone. Never throws: falls back to local calculation. */
export function getDay(s: Settings, date: YMD, ramadan = false): DayTimes {
  let day: DayTimes | null = null;
  if (s.calc.source === 'table') {
    const r = tableDay(s, date);
    if (r) day = fromStrings(s, date, r, 'table');
  } else if (s.calc.source === 'api') {
    const r = cachedApiDay(s, date);
    if (r) day = fromStrings(s, date, r, 'api');
  }
  return applyAdjustments(s, day ?? calcDay(s, date, ramadan));
}

/** Pre-fetch API months (current + next) so the screen keeps working offline. */
export async function warmApi(s: Settings): Promise<void> {
  if (s.calc.source !== 'api') return;
  const t = todayIn(s.location.timezone);
  const next = addDays({ ...t, d: 28 }, 7);
  await fetchApiMonth(s, t.y, t.m);
  await fetchApiMonth(s, next.y, next.m).catch(() => undefined);
}

export function iqamaTime(s: Settings, key: SalahKey, adhan: Date, date: YMD): Date {
  // Mosque-approved per-day iqamah overrides fixed and relative rules, including DST transitions.
  const dailyTime = s.dailyIqama?.[ymdKey(date)]?.[key];
  if (dailyTime) {
    const parsed = parseHM(dailyTime);
    if (parsed !== null) {
      const fixed = fromZoned(date.y, date.m, date.d, Math.floor(parsed / 60), parsed % 60, s.location.timezone);
      if (fixed.getTime() >= adhan.getTime()) return fixed;
    }
  }
  const r = s.iqama[key];
  if (r.mode === 'fixed') {
    const v = parseHM(r.time);
    if (v !== null) {
      const fixed = fromZoned(date.y, date.m, date.d, Math.floor(v / 60), v % 60, s.location.timezone);
      if (fixed.getTime() >= adhan.getTime()) return fixed;
    }
  }
  return new Date(adhan.getTime() + Math.max(0, r.offset) * 60000);
}

/** Compare local calculation with Aladhan for today — used by the "verify" button in settings. */
export async function verifyWithApi(s: Settings): Promise<{ key: PrayerKey; local: Date; api: Date; diff: number }[]> {
  const date = todayIn(s.location.timezone);
  const month = await fetchApiMonth(s, date.y, date.m);
  const api = fromStrings(s, date, month[ymdKey(date)], 'api');
  const local = calcDay(s, date);
  if (!api) throw new Error('No API data');
  return PRAYERS.map((key) => ({
    key, local: local.times[key], api: api.times[key],
    diff: Math.round((local.times[key].getTime() - api.times[key].getTime()) / 60000),
  }));
}
