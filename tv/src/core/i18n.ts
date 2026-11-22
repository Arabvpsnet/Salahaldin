import type { Lang, PrayerKey } from './settings';

export const PRAYER_AR: Record<PrayerKey | 'jumuah', string> = {
  fajr: 'الفجر', sunrise: 'الشروق', dhuhr: 'الظهر', asr: 'العصر', maghrib: 'المغرب', isha: 'العشاء', jumuah: 'الجمعة',
};
const PRAYER_LAT: Record<Exclude<Lang, 'ar'>, Record<PrayerKey | 'jumuah', string>> = {
  fr: { fajr: 'Fajr', sunrise: 'Chourouq', dhuhr: 'Dhohr', asr: 'Asr', maghrib: 'Maghrib', isha: 'Icha', jumuah: 'Joumou‘a' },
  en: { fajr: 'Fajr', sunrise: 'Sunrise', dhuhr: 'Dhuhr', asr: 'Asr', maghrib: 'Maghrib', isha: 'Isha', jumuah: 'Jumu‘ah' },
  da: { fajr: 'Fajr', sunrise: 'Solopgang', dhuhr: 'Dhuhr', asr: 'Asr', maghrib: 'Maghrib', isha: 'Isha', jumuah: 'Fredagsbøn' },
  tr: { fajr: 'Sabah', sunrise: 'Güneş', dhuhr: 'Öğle', asr: 'İkindi', maghrib: 'Akşam', isha: 'Yatsı', jumuah: 'Cuma' },
};

export const prayerName = (k: PrayerKey | 'jumuah', lang: Lang) => (lang === 'ar' ? PRAYER_AR[k] : PRAYER_LAT[lang][k]);

const dict = {
  next: { fr: 'Prochaine prière', en: 'Next prayer', ar: 'الصلاة القادمة' },
  in: { fr: 'dans', en: 'in', ar: 'بعد' },
  iqama: { fr: 'Iqama', en: 'Iqamah', ar: 'الإقامة' },
  adhan: { fr: 'Adhan', en: 'Adhan', ar: 'الأذان' },
  iqamaIn: { fr: 'Iqama dans', en: 'Iqamah in', ar: 'الإقامة بعد' },
  adhanNow: { fr: 'C’est l’heure de l’adhan', en: 'It is time for the adhan', ar: 'حان الآن موعد أذان' },
  prayerNow: { fr: 'La prière est en cours', en: 'Prayer in progress', ar: 'الصلاة قائمة' },
  silence: { fr: 'Merci d’éteindre vos téléphones', en: 'Please switch off your phones', ar: 'يرجى إغلاق الهواتف النقالة' },
  straighten: { fr: 'Alignez les rangs, comblez les vides', en: 'Straighten the rows, close the gaps', ar: 'استووا واعتدلوا وسدوا الخلل' },
  afterPrayer: { fr: 'Adhkar après la prière', en: 'Remembrance after prayer', ar: 'أذكار بعد الصلاة' },
  duaAfterAdhan: { fr: 'Invocation après l’adhan', en: 'Supplication after the adhan', ar: 'الدعاء بعد الأذان' },
  imsak: { fr: 'Imsak', en: 'Imsak', ar: 'الإمساك' },
  iftar: { fr: 'Iftar', en: 'Iftar', ar: 'الإفطار' },
  ramadan: { fr: 'Ramadan Moubarak', en: 'Ramadan Mubarak', ar: 'رمضان مبارك' },
  enableSound: { fr: 'Touchez l’écran pour activer le son de l’adhan', en: 'Tap the screen to enable the adhan sound', ar: 'المس الشاشة لتفعيل صوت الأذان' },
  settings: { fr: 'Réglages', en: 'Settings', ar: 'الإعدادات' },
  fullscreen: { fr: 'Plein écran', en: 'Fullscreen', ar: 'ملء الشاشة' },
  ayah: { fr: 'Verset', en: 'Verse', ar: 'آية' },
  dhikr: { fr: 'Dhikr', en: 'Dhikr', ar: 'ذكر' },
  info: { fr: 'Information', en: 'Notice', ar: 'إعلان' },
  offline: { fr: 'Hors ligne', en: 'Offline', ar: 'غير متصل' },
  estimatedTimes: { fr: 'Horaires estimés — calendrier du lieu indisponible', en: 'Estimated prayer times — mosque timetable unavailable', ar: 'تنبيه: مواقيت تقديرية — جدول المسجد غير متاح' },
  pin: { fr: 'Code PIN', en: 'PIN code', ar: 'الرمز السري' },
  wrongPin: { fr: 'Code incorrect', en: 'Wrong code', ar: 'رمز خاطئ' },
  tomorrow: { fr: 'demain', en: 'tomorrow', ar: 'غداً' },
  eid: { fr: 'Prière de l’Aïd', en: 'Eid prayer', ar: 'صلاة العيد' },
  duha: { fr: 'Duha', en: 'Duha', ar: 'الضحى' },
  qiyam: { fr: 'Dernier tiers de la nuit', en: 'Last third of the night', ar: 'الثلث الأخير' },
} as const;

export type I18nKey = keyof typeof dict;
const extra: Record<'da' | 'tr', Partial<Record<I18nKey, string>>> = {
  da: {next: 'Næste bøn', in: 'om', iqama: 'Iqama', adhan: 'Adhan', iqamaIn: 'Iqama om', adhanNow: 'Det er tid til adhan', prayerNow: 'Bønnen er i gang', silence: 'Sluk venligst mobiltelefonen', straighten: 'Ret rækkerne op', afterPrayer: 'Dhikr efter bønnen', duaAfterAdhan: 'Dua efter adhan', imsak: 'Imsak', iftar: 'Iftar', ramadan: 'Ramadan mubarak', enableSound: 'Tryk på skærmen for at aktivere adhanlyden', settings: 'Indstillinger', fullscreen: 'Fuld skærm', ayah: 'Vers', dhikr: 'Dhikr', info: 'Meddelelse', offline: 'Offline', estimatedTimes: 'Beregnet bedetid – moskeens kalender er utilgængelig', pin: 'PIN-kode', wrongPin: 'Forkert kode', tomorrow: 'i morgen', eid: 'Eid-bøn', duha: 'Duha', qiyam: 'Den sidste tredjedel af natten'},
  tr: {next: 'Sonraki namaz', in: 'sonra', iqama: 'Kamet', adhan: 'Ezan', iqamaIn: 'Kamete kalan', adhanNow: 'Ezan vakti', prayerNow: 'Namaz kılınıyor', silence: 'Lütfen telefonlarınızı kapatın', straighten: 'Safları düzeltin', afterPrayer: 'Namaz sonrası zikirler', duaAfterAdhan: 'Ezan duası', imsak: 'İmsak', iftar: 'İftar', ramadan: 'Hayırlı Ramazanlar', enableSound: 'Ezan sesini etkinleştirmek için ekrana dokunun', settings: 'Ayarlar', fullscreen: 'Tam ekran', ayah: 'Ayet', dhikr: 'Zikir', info: 'Duyuru', offline: 'Çevrimdışı', estimatedTimes: 'Tahmini namaz vakitleri – cami takvimi kullanılamıyor', pin: 'PIN kodu', wrongPin: 'Yanlış kod', tomorrow: 'yarın', eid: 'Bayram namazı', duha: 'Duha', qiyam: 'Gecenin son üçte biri'},
};
export const t = (k: I18nKey, lang: Lang): string => {
  if (lang === 'da' || lang === 'tr') return extra[lang][k] ?? dict[k].en;
  return dict[k][lang];
};

export const locale = (lang: Lang) => ({ ar: 'ar-DZ', en: 'en-GB', fr: 'fr-FR', da: 'da-DK', tr: 'tr-TR' })[lang];
