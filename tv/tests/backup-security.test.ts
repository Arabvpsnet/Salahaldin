import { describe, expect, it } from 'vitest';
import { defaults, settings } from '../src/core/settings';

describe('malicious backup protection', () => {
  it('ignores prototype keys and unrecognized backup properties', () => {
    const raw = JSON.parse('{"__proto__":{"polluted":true},"mosque":{"__proto__":{"polluted":true},"name":"Safe"},"unexpected":{"danger":1}}');
    settings.replace(raw);
    expect(({} as { polluted?: boolean }).polluted).toBeUndefined();
    expect((settings.get() as unknown as Record<string, unknown>).unexpected).toBeUndefined();
    expect(settings.get().mosque.name).toBe('Safe');
    settings.replace(defaults());
  });
});
