import { settings, type SalahKey } from './settings';
import { invalidate } from './schedule';

type RemoteCalendar = {
  schemaVersion: 1; mosqueId: string; timezone: string; city: string;
  timetable: Record<string, string[]>;
  iqama?: Partial<Record<SalahKey, {mode:'fixed' | 'offset'; time:string; offset:number}>>;
};
const api = import.meta.env.VITE_SALAHALDIN_API_BASE as string | undefined;
const mosqueId = import.meta.env.VITE_SALAHALDIN_MOSQUE_ID as string | undefined;
const validTime = (v: unknown): v is string => typeof v === 'string' && /^([01]\d|2[0-3]):[0-5]\d$/.test(v);
export async function syncMosqueCalendar() {
  if (!api || !mosqueId || !/^[a-z0-9-]+$/.test(mosqueId)) return;
  const response = await fetch(api.replace(/\/$/, '') + '/api/salahaldin/v1/schedules/' + mosqueId, {cache: 'no-store'});
  if (!response.ok) throw new Error('Schedule HTTP '+response.status);
  const calendar = await response.json() as RemoteCalendar;
  if (calendar.schemaVersion !== 1 || calendar.mosqueId !== mosqueId ||
      typeof calendar.timezone !== 'string' || typeof calendar.city !== 'string' ||
      !calendar.timetable || Object.entries(calendar.timetable).some(([day, hours]) =>
        !/^\d{4}-\d{2}-\d{2}$/.test(day) || !Array.isArray(hours) || hours.length !== 6 || !hours.every(validTime))) {
    throw new Error('Invalid mosque calendar');
  }
  settings.set(s => {
    s.location.timezone = calendar.timezone;
    s.location.city = calendar.city;
    s.calc.source = 'table';
    s.timetable = calendar.timetable;
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
