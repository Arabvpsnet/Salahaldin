import { describe, expect, it } from 'vitest';
import { defaults } from '../src/core/settings';
import { iqamaTime } from '../src/core/prayer';
import { fromZoned, formatHM } from '../src/core/time';

describe('per-date mosque iqama overrides', () => {
  it('uses approved daily iqama in Denmark across seasonal timezone changes', () => {
    const s = defaults();
    s.location.timezone = 'Europe/Copenhagen';
    s.dailyIqama = {
      '2026-03-29': { dhuhr: '13:20' },
      '2026-10-25': { dhuhr: '13:20' },
    };
    for (const [y, m, d] of [[2026, 3, 29], [2026, 10, 25]]) {
      const adhan = fromZoned(y, m, d, 12, 12, s.location.timezone);
      const iqama = iqamaTime(s, 'dhuhr', adhan, { y, m, d });
      expect(formatHM(iqama, s.location.timezone, true)).toBe('13:20');
    }
  });
  it('falls back to relative rule if daily iqama precedes the adhan', () => {
    const s = defaults();
    s.location.timezone = 'Europe/Copenhagen';
    s.iqama.dhuhr = { mode: 'offset', offset: 15, time: '13:00' };
    s.dailyIqama = {'2026-11-20': {dhuhr: '11:00'}};
    const adhan = fromZoned(2026, 11, 20, 12, 12, s.location.timezone);
    expect(formatHM(iqamaTime(s, 'dhuhr', adhan, {y:2026,m:11,d:20}), s.location.timezone, true)).toBe('12:27');
  });
});
