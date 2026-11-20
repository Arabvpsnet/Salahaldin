import { settings, type SalahKey } from './settings';
import { invalidate } from './schedule';

export type RemoteCalendar = {
  schemaVersion: 1;
  mosqueId: string;
  timezone: string;
  city: string;
  timetable: Record<string, string[]>;
  dailyIqama?: Record<string, Partial<Record<SalahKey, string>>>;
  iqama?: Partial<Record<SalahKey, { mode: 'fixed' | 'offset'; time: string; offset: number }>>;
};

const API_BASE = import.meta.env.VITE_SALAHALDIN_API_BASE as string | undefined;
const MOSQUE_ID = import.meta.env.VITE_SALAHALDIN_MOSQUE_ID as string | undefined;
const PRAYERS: SalahKey[] = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
const clock = (time: unknown): time is string =>
  typeof time === 'string' && /^([01]\d|2[0-3]):[0-5]\d$/.test(time);
const record = (value: unknown): value is Record<string, unknown> =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

function validDate(input: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(input)) return false;
  const [year, month, day] = input.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}
function validTimeZone(input: string): boolean {
  try {
    new Intl.DateTimeFormat('en', { timeZone: input });
    return true;
  } catch {
    return false;
  }
}

/** A pure boundary validator; malformed or forged dates never reach cached mosque schedules. */
export function validateRemoteCalendar(input: unknown, mosqueId: string): RemoteCalendar {
  if (!record(input) || input.schemaVersion !== 1 || input.mosqueId !== mosqueId ||
      typeof input.timezone !== 'string' || !validTimeZone(input.timezone) ||
      typeof input.city !== 'string' || input.city.trim().length < 1 || input.city.length > 120 ||
      !record(input.timetable)) {
    throw new Error('Invalid mosque calendar envelope');
  }

  const days = Object.entries(input.timetable);
  if (days.length < 1 || days.length > 800) throw new Error('Invalid timetable length');
  for (const [day, hours] of days) {
    if (!validDate(day) || !Array.isArray(hours) || hours.length !== 6 ||
        !hours.every(clock)) throw new Error('Invalid timetable date or time');
  }

  if (input.dailyIqama !== undefined) {
    if (!record(input.dailyIqama) || Object.keys(input.dailyIqama).length > 800) {
      throw new Error('Invalid daily iqamah length');
    }
    for (const [day, entry] of Object.entries(input.dailyIqama)) {
      if (!validDate(day) || !record(entry) ||
          Object.entries(entry).some(([prayer, time]) =>
            !PRAYERS.includes(prayer as SalahKey) || !clock(time))) {
        throw new Error('Invalid daily iqamah entry');
      }
    }
  }

  if (input.iqama !== undefined) {
    if (!record(input.iqama) || Object.keys(input.iqama).length > 5) {
      throw new Error('Invalid iqamah rule set');
    }
    for (const [prayer, rule] of Object.entries(input.iqama)) {
      if (!PRAYERS.includes(prayer as SalahKey) || !record(rule) ||
          (rule.mode !== 'fixed' && rule.mode !== 'offset') ||
          !clock(rule.time) || typeof rule.offset !== 'number' ||
          !Number.isFinite(rule.offset) || rule.offset < 0 || rule.offset > 240) {
        throw new Error('Invalid iqamah rule');
      }
    }
  }
  return input as RemoteCalendar;
}

function remoteUrl(): string | null {
  if (!API_BASE || !MOSQUE_ID || !/^[a-z0-9-]{1,80}$/.test(MOSQUE_ID)) return null;
  const url = new URL(API_BASE);
  if (url.protocol !== 'https:' && !(url.protocol === 'http:' &&
       ['localhost', '127.0.0.1'].includes(url.hostname))) {
    throw new Error('HTTPS required for remote mosque configuration');
  }
  // Deliberately reject query strings, fragments and user-info in the backend URL.
  if (url.username || url.password || url.search || url.hash) {
    throw new Error('Invalid remote server URL');
  }
  return new URL('api/salahaldin/v1/schedules/' + MOSQUE_ID,
    url.href.replace(/\/?$/, '/')).href;
}

export async function syncMosqueCalendar(): Promise<void> {
  const url = remoteUrl();
  if (!url) return;
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), 10000);
  try {
    const response = await fetch(url, { cache: 'no-store', signal: controller.signal });
    if (!response.ok) throw new Error('Schedule HTTP ' + response.status);
    const size = response.headers.get('content-length');
    if (size && Number(size) > 1_000_000) throw new Error('Calendar too large');
    const content = await response.text();
    if (content.length > 1_000_000) throw new Error('Calendar too large');
    const calendar = validateRemoteCalendar(JSON.parse(content) as unknown, MOSQUE_ID!);
    settings.set((s) => {
      s.location.timezone = calendar.timezone;
      s.location.city = calendar.city;
      s.location.configured = true;
      s.calc.source = 'table';
      s.timetable = calendar.timetable;
      s.dailyIqama = calendar.dailyIqama ?? {};
      if (calendar.iqama) {
        for (const prayer of PRAYERS) {
          const rule = calendar.iqama[prayer];
          if (rule) s.iqama[prayer] = rule;
        }
      }
    });
    invalidate();
  } finally {
    clearTimeout(timeout);
  }
}

export function startMosqueSync(): void {
  if (!API_BASE || !MOSQUE_ID) return;
  void syncMosqueCalendar().catch(console.warn);
  window.setInterval(() => void syncMosqueCalendar().catch(console.warn), 60000);
}
