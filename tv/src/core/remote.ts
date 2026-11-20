import { settings, type SalahKey } from './settings';
import { invalidate } from './schedule';

type RemoteCalendar = {
  schemaVersion: 1; mosqueId: string; timezone: string; city: string;
  timetable: Record<string, string[]>;
  dailyIqama?: Record<string, Partial<Record<SalahKey, string>>>;
  iqama?: Partial<Record<SalahKey, {mode:'fixed' | 'offset'; time:string; offset:number}>>;
};
const api = import.meta.env.VITE_SALAHALDIN_API_BASE as string | undefined;
const mosqueId = import.meta.env.VITE_SALAHALDIN_MOSQUE_ID as string | undefined;
const isSupportedZone = (zone: string): boolean => {
  try { new Intl.DateTimeFormat('en', { timeZone: zone }); return true; }
  catch { return false; }
};
const validDate = (input: string): boolean => {
  if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(input)) return false;
  const [y,m,d] = input.split('-').map(Number);
  const date = new Date(Date.UTC(y, m-1, d));
  return date.getUTCFullYear() === y && date.getUTCMonth() === m-1 && date.getUTCDate() === d;
};
const validTime = (v: unknown): v is string => typeof v === 'string' && /^([01]\d|2[0-3]):[0-5]\d$/.test(v);
export async function syncMosqueCalendar() {
  if (!api || !mosqueId || !/^[a-z0-9-]+$/.test(mosqueId)) return;
  const base = new URL(api);
  if (base.protocol !== 'https:' && base.hostname !== 'localhost' && base.hostname !== '127.0.0.1') {
    throw new Error('HTTPS required for remote mosque configuration');
  }
  const response = await fetch(api.replace(/\/$/, '') + '/api/salahaldin/v1/schedules/' + mosqueId, {cache: 'no-store'});
  if (!response.ok) throw new Error('Schedule HTTP '+response.status);
  const body = await response.text();
  if (body.length > 1000000) throw new Error('Schedule payload too large');
  const calendar = JSON.parse(body) as RemoteCalendar;
  if (calendar.schemaVersion !== 1 || calendar.mosqueId !== mosqueId ||
      typeof calendar.timezone !== 'string' || !isSupportedZone(calendar.timezone) || typeof calendar.city !== 'string' || calendar.city.length > 120 ||
      !calendar.timetable || Object.keys(calendar.timetable).length < 1 || Object.keys(calendar.timetable).length > 800 || Object.entries(calendar.timetable).some(([day, hours]) =>
        !validDate(day) || !Array.isArray(hours) || hours.length !== 6 || !hours.every(validTime))) {
    throw new Error('Invalid mosque calendar');
  }
  if (calendar.dailyIqama && Object.entries(calendar.dailyIqama).some(([day, byPrayer]) =>
      !validDate(day) || !byPrayer || typeof byPrayer !== 'object' ||
      Object.entries(byPrayer).some(([prayer, time]) =>
        !['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'].includes(prayer) || !validTime(time)))) {
    throw new Error('Invalid daily iqama schedule');
  }
  settings.set(s => {
    s.location.timezone = calendar.timezone;
    s.location.city = calendar.city;
    s.calc.source = 'table';
    s.timetable = calendar.timetable;
    s.dailyIqama = calendar.dailyIqama ?? {};
    for (const key of ['fajr','dhuhr','asr','maghrib','isha'] as SalahKey[]) {
      const rule=calendar.iqama?.[key];
      if (rule && ['fixed','offset'].includes(rule.mode) && validTime(rule.time) &&
        Number.isFinite(rule.offset) && rule.offset >= 0) s.iqama[key] = rule;
    }
  });
  invalidate();
}
export function startMosqueSync() {
  if (!api || !mosqueId) return;
  void syncMosqueCalendar().catch(console.warn);
  window.setInterval(() => void syncMosqueCalendar().catch(console.warn), 60000);
}
