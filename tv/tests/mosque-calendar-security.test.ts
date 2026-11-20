import { describe, expect, it } from 'vitest';
import { defaults, settings } from '../src/core/settings';
import { validateRemoteCalendar } from '../src/core/remote';

const sample = () => ({
  schemaVersion: 1 as const,
  mosqueId: 'an-nour',
  timezone: 'Europe/Copenhagen',
  city: 'Fredericia',
  timetable: { '2026-11-21': ['06:01', '08:11', '12:13', '14:30', '16:10', '18:01'] },
  dailyIqama: { '2026-11-21': { fajr: '06:20', dhuhr: '12:25' } },
});

describe('canonical mosque calendars', () => {
  it('accepts valid dates in the configured IANA timezone', () => {
    const data = validateRemoteCalendar(sample(), 'an-nour');
    expect(data.city).toBe('Fredericia');
    expect(data.timetable['2026-11-21'][0]).toBe('06:01');
  });

  it('rejects forged dates and invalid timezone names', () => {
    expect(() => validateRemoteCalendar({ ...sample(), timetable: { '2026-02-30': sample().timetable['2026-11-21'] } }, 'an-nour')).toThrow();
    expect(() => validateRemoteCalendar({ ...sample(), timezone: 'Europe/Fake' }, 'an-nour')).toThrow();
    expect(() => validateRemoteCalendar(sample(), 'another-mosque')).toThrow();
  });

  it('rejects invalid iqamah times, unsupported keys and unbounded content', () => {
    expect(() => validateRemoteCalendar({ ...sample(), dailyIqama: { '2026-11-21': { fajr: '25:44' } } }, 'an-nour')).toThrow();
    expect(() => validateRemoteCalendar({ ...sample(), dailyIqama: { '2026-11-21': { admin: '12:00' } } }, 'an-nour')).toThrow();
    expect(() => validateRemoteCalendar({ ...sample(), timetable: {} }, 'an-nour')).toThrow();
  });

  it('preserves validated daily mosque timetable/iqamah after settings restore', () => {
    const data = sample();
    settings.replace(data);
    expect(settings.get().timetable['2026-11-21'][2]).toBe('12:13');
    expect(settings.get().dailyIqama['2026-11-21']?.dhuhr).toBe('12:25');
    settings.reset();
  });

  it('ignores injected keys and rejects invalid entries in backups', () => {
    const raw = JSON.parse('{"timetable":{"__proto__":["a"],"2026-02-30":["03:00","04:00","05:00","06:00","07:00","08:00"]},"dailyIqama":{"2026-11-21":{"constructor":"12:00"}}}');
    settings.replace(raw);
    expect(({} as { polluted?: boolean }).polluted).toBeUndefined();
    expect(Object.keys(settings.get().timetable)).toHaveLength(0);
    expect(Object.keys(settings.get().dailyIqama)).toHaveLength(0);
    settings.replace(defaults());
  });
});
