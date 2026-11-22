import { describe, expect, it } from 'vitest';
import { parseAladhanMonth, parseTimetable } from '../src/core/prayer';

function month(year: number, m: number) {
  const n = new Date(Date.UTC(year, m, 0)).getUTCDate();
  return {
    code: 200,
    data: Array.from({ length: n }, (_, index) => ({
      date: { gregorian: { date: String(index + 1).padStart(2, '0') + '-' +
        String(m).padStart(2, '0') + '-' + String(year) } },
      timings: {
        Fajr: '05:30 (CET)', Sunrise: '07:35 (CET)', Dhuhr: '12:10 (CET)',
        Asr: '14:25 (CET)', Maghrib: '16:45 (CET)', Isha: '18:20 (CET)',
      },
    })),
  };
}

describe('Aladhan monthly provider quality gates', () => {
  it('normalizes an entire month including timezone suffixes', () => {
    const parsed = parseAladhanMonth(month(2026, 2), 2026, 2);
    expect(Object.keys(parsed)).toHaveLength(28);
    expect(parsed['2026-02-28']).toEqual(['05:30','07:35','12:10','14:25','16:45','18:20']);
    expect(Object.getPrototypeOf(parsed)).toBeNull();
  });
  it('supports leap-year February without guessing local timezone', () => {
    expect(Object.keys(parseAladhanMonth(month(2028, 2), 2028, 2))).toHaveLength(29);
  });
  it('rejects malformed time, missing days, duplicate dates and wrong month', () => {
    const bad = month(2026, 11);
    bad.data[1].timings.Maghrib = '99:00';
    expect(() => parseAladhanMonth(bad, 2026, 11)).toThrow();
    const repeated = month(2026, 11);
    repeated.data[1].date.gregorian.date = repeated.data[0].date.gregorian.date;
    expect(() => parseAladhanMonth(repeated, 2026, 11)).toThrow();
    expect(() => parseAladhanMonth(month(2026, 11), 2026, 10)).toThrow();
    expect(() => parseAladhanMonth({ code: 200, data: [] }, 2026, 11)).toThrow();
  });
});

describe('official CSV importer — never silently shift prayer columns', () => {
  const times = '06:12,08:14,12:04,14:25,16:02,17:48';
  it('parses official calendar and DST transition days', () => {
    const result = parseTimetable('date,fajr,sunrise,dhuhr,asr,maghrib,isha\n2026-03-29,' +
      times + '\n2026-10-25,' + times);
    expect(result.errors).toBe(0);
    expect(result.rows['2026-03-29'][3]).toBe('14:25');
    expect(result.rows['2026-10-25'][5]).toBe('17:48');
  });
  it('handles quoted cells and Danish/European dates', () => {
    const data = parseTimetable('date;fajr;sunrise;dhuhr;asr;maghrib;isha\n' +
      '"29/03/2026";"6:12";08:14;12:04;14:25;16:02;17:48');
    expect(data.errors).toBe(0);
    expect(data.rows['2026-03-29'][0]).toBe('06:12');
  });
  it('rejects invalid dates, empty columns, duplicate rows and clock suffix injection', () => {
    const csv = '2026-02-30,' + times + '\n' +
      '2026-11-21,06:12,,12:04,14:25,16:02,17:48\n' +
      '2026-11-21,' + times + '\n' +
      '2026-11-21,' + times + '\n' +
      '2026-11-22,06:12,08:14,12:04,14:25,16:02,17:48BAD';
    const result = parseTimetable(csv);
    expect(result.errors).toBe(4);
    expect(Object.keys(result.rows)).toEqual(['2026-11-21']);
  });
  it('supports recurring leap day but rejects impossible 31 February', () => {
    expect(parseTimetable('29/02,' + times).rows['02-29']).toBeDefined();
    expect(parseTimetable('31/02,' + times).errors).toBe(1);
  });
  it('limits file size, retains no object prototype and avoids silent partial imports', () => {
    expect(parseTimetable('x'.repeat(600000)).errors).toBe(1);
    expect(Object.getPrototypeOf(parseTimetable('2026-11-21,' + times).rows)).toBeNull();
  });
});
