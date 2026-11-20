from pathlib import Path

def edit(path, old, new, required=True):
    p=Path(path)
    text=p.read_text(encoding="utf-8")
    if old not in text:
        if required:
            raise RuntimeError(f"Upstream string missing in {path}: {old[:85]!r}")
        return
    p.write_text(text.replace(old,new), encoding="utf-8")

edit("tv/src/core/settings.ts",
     "export type Lang = 'fr' | 'en' | 'ar';",
     "export type Lang = 'fr' | 'en' | 'ar' | 'da' | 'tr';")
edit("tv/src/core/settings.ts",
     "lang: (navigator.language || 'fr').slice(0, 2) === 'ar' ? 'ar' : (navigator.language || '').startsWith('en') ? 'en' : 'fr',",
     "lang: (['ar', 'en', 'da', 'tr', 'fr'].includes((navigator.language || 'en').slice(0, 2)) ? (navigator.language || 'en').slice(0, 2) : 'en') as Lang,")
edit("tv/src/core/i18n.ts",
     "Record<'fr' | 'en', Record<PrayerKey | 'jumuah', string>>",
     "Record<Exclude<Lang, 'ar'>, Record<PrayerKey | 'jumuah', string>>")
edit("tv/src/core/i18n.ts",
     "  en: { fajr: 'Fajr', sunrise: 'Sunrise', dhuhr: 'Dhuhr', asr: 'Asr', maghrib: 'Maghrib', isha: 'Isha', jumuah: 'Jumu‘ah' },",
     "  en: { fajr: 'Fajr', sunrise: 'Sunrise', dhuhr: 'Dhuhr', asr: 'Asr', maghrib: 'Maghrib', isha: 'Isha', jumuah: 'Jumu‘ah' },\n  da: { fajr: 'Fajr', sunrise: 'Solopgang', dhuhr: 'Dhuhr', asr: 'Asr', maghrib: 'Maghrib', isha: 'Isha', jumuah: 'Fredagsbøn' },\n  tr: { fajr: 'Sabah', sunrise: 'Güneş', dhuhr: 'Öğle', asr: 'İkindi', maghrib: 'Akşam', isha: 'Yatsı', jumuah: 'Cuma' },")
old = "export const t = (k: I18nKey, lang: Lang) => dict[k][lang];"
new = """const extra: Record<'da' | 'tr', Partial<Record<I18nKey, string>>> = {
  da: {next: 'Næste bøn', in: 'om', iqama: 'Iqama', adhan: 'Adhan', iqamaIn: 'Iqama om', adhanNow: 'Det er tid til adhan', prayerNow: 'Bønnen er i gang', silence: 'Sluk venligst mobiltelefonen', straighten: 'Ret rækkerne op', afterPrayer: 'Dhikr efter bønnen', duaAfterAdhan: 'Dua efter adhan', imsak: 'Imsak', iftar: 'Iftar', ramadan: 'Ramadan mubarak', enableSound: 'Tryk på skærmen for at aktivere adhanlyden', settings: 'Indstillinger', fullscreen: 'Fuld skærm', ayah: 'Vers', dhikr: 'Dhikr', info: 'Meddelelse', offline: 'Offline', pin: 'PIN-kode', wrongPin: 'Forkert kode', tomorrow: 'i morgen', eid: 'Eid-bøn', duha: 'Duha', qiyam: 'Den sidste tredjedel af natten'},
  tr: {next: 'Sonraki namaz', in: 'sonra', iqama: 'Kamet', adhan: 'Ezan', iqamaIn: 'Kamete kalan', adhanNow: 'Ezan vakti', prayerNow: 'Namaz kılınıyor', silence: 'Lütfen telefonlarınızı kapatın', straighten: 'Safları düzeltin', afterPrayer: 'Namaz sonrası zikirler', duaAfterAdhan: 'Ezan duası', imsak: 'İmsak', iftar: 'İftar', ramadan: 'Hayırlı Ramazanlar', enableSound: 'Ezan sesini etkinleştirmek için ekrana dokunun', settings: 'Ayarlar', fullscreen: 'Tam ekran', ayah: 'Ayet', dhikr: 'Zikir', info: 'Duyuru', offline: 'Çevrimdışı', pin: 'PIN kodu', wrongPin: 'Yanlış kod', tomorrow: 'yarın', eid: 'Bayram namazı', duha: 'Duha', qiyam: 'Gecenin son üçte biri'},
};
export const t = (k: I18nKey, lang: Lang): string => {
  if (lang === 'da' || lang === 'tr') return extra[lang][k] ?? dict[k].en;
  return dict[k][lang];
};"""
edit("tv/src/core/i18n.ts",old,new)
edit("tv/src/core/i18n.ts",
     "export const locale = (lang: Lang) => (lang === 'ar' ? 'ar-DZ' : lang === 'en' ? 'en-GB' : 'fr-FR');",
     "export const locale = (lang: Lang) => ({ ar: 'ar-DZ', en: 'en-GB', fr: 'fr-FR', da: 'da-DK', tr: 'tr-TR' })[lang];")
edit("tv/src/ui/settings-panel.ts",
     "lang === 'en' ? b.labelEn || b.label : b.label",
     "(lang === 'en' || lang === 'da' || lang === 'tr') ? b.labelEn || b.label : b.label")
edit("tv/src/ui/settings-panel.ts",
     "const L = (fr: string, en: string, ar: string) => (lang === 'ar' ? ar : lang === 'en' ? en : fr);",
     "const L = (fr: string, en: string, ar: string) => (lang === 'ar' ? ar : lang === 'fr' ? fr : en);")
edit("tv/src/ui/settings-panel.ts",
     "[['ar', 'العربية'], ['fr', 'FR'], ['en', 'EN']]",
     "[['ar', 'العربية'], ['da', 'Dansk'], ['en', 'English'], ['tr', 'Türkçe'], ['fr', 'FR']]")
edit("tv/src/ui/settings-panel.ts",
     "h('b', null, 'Sakina')",
     "h('b', null, 'Salahaldin')")
# Connected timetable API (opt-in). Authoritative prayer times are never independently recalculated after a remote calendar is applied.
Path("tv/src/core/remote.ts").write_text("""import { settings, type SalahKey } from './settings';
import { invalidate } from './schedule';

type RemoteCalendar = {
  schemaVersion: 1; mosqueId: string; timezone: string; city: string;
  timetable: Record<string, string[]>;
  iqama?: Partial<Record<SalahKey, {mode:'fixed' | 'offset'; time:string; offset:number}>>;
};
const api = import.meta.env.VITE_SALAHALDIN_API_BASE as string | undefined;
const mosqueId = import.meta.env.VITE_SALAHALDIN_MOSQUE_ID as string | undefined;
const validTime = (v: unknown): v is string => typeof v === 'string' && /^([01]\\d|2[0-3]):[0-5]\\d$/.test(v);
export async function syncMosqueCalendar() {
  if (!api || !mosqueId || !/^[a-z0-9-]+$/.test(mosqueId)) return;
  const response = await fetch(api.replace(/\\/$/, '') + '/api/salahaldin/v1/schedules/' + mosqueId, {cache: 'no-store'});
  if (!response.ok) throw new Error('Schedule HTTP '+response.status);
  const calendar = await response.json() as RemoteCalendar;
  if (calendar.schemaVersion !== 1 || calendar.mosqueId !== mosqueId ||
      typeof calendar.timezone !== 'string' || typeof calendar.city !== 'string' ||
      !calendar.timetable || Object.entries(calendar.timetable).some(([day, hours]) =>
        !/^\\d{4}-\\d{2}-\\d{2}$/.test(day) || !Array.isArray(hours) || hours.length !== 6 || !hours.every(validTime))) {
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
""",encoding="utf-8")
p=Path("tv/src/main.ts")
s=p.read_text(encoding="utf-8")
s="import { startMosqueSync } from './core/remote';\n"+s
s += "\nstartMosqueSync();\n"
p.write_text(s,encoding="utf-8")
# Backend: public read-only route. Admin import and per-mosque authentication must be added before deployment.
p=Path("server/routes/api.php")
s=p.read_text(encoding="utf-8")
s += """
// Salahaldin: public read-only mosque schedule in an IANA time zone.
// Only vetted JSON files created by the administrator should be placed in storage/app/prayer/schedules.
Route::get('salahaldin/v1/schedules/{mosque}', function (string $mosque) {
    $path = storage_path('app/prayer/schedules/'.$mosque.'.json');
    abort_unless(is_file($path), 404);
    return response()->file($path, [
        'Content-Type' => 'application/json; charset=utf-8',
        'Cache-Control' => 'public, max-age=30',
    ]);
})->where('mosque', '[a-z0-9-]+');
"""
p.write_text(s,encoding="utf-8")
Path("tv/.env.example.salahaldin").write_text(
    "VITE_SALAHALDIN_API_BASE=https://your-api-domain.example\nVITE_SALAHALDIN_MOSQUE_ID=fredericia\n",encoding="utf-8")
