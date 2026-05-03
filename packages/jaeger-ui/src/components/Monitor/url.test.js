// Copyright (c) 2021 The Jaeger Authors.
// SPDX-License-Identifier: Apache-2.0
import { ROUTE_PATH, matches, getUrl, parseMonitorUrl } from './url';

describe('Monitor/url', () => {
  it('matches', () => {
    expect(matches('/monitor')).toBe(true);
    expect(matches('/monitor?var=123')).toBe(true);
    expect(matches('/bla')).toBe(false);
  });

  describe('parseMonitorUrl', () => {
    it('parses empty search', () => {
      expect(parseMonitorUrl('')).toEqual({
        service: undefined,
        spanKind: undefined,
        timeframe: undefined,
        hideService: false,
      });
    });

    it('parses full search', () => {
      const search = '?service=my-service&spanKind=client&timeframe=3600000&hideService=true';
      expect(parseMonitorUrl(search)).toEqual({
        service: 'my-service',
        spanKind: 'client',
        timeframe: '3600000',
        hideService: true,
      });
    });
  });

  describe('getUrl', () => {
    it('returns route path when no state is provided', () => {
      expect(getUrl()).toBe(ROUTE_PATH);
    });

    it('generates URL with query parameters', () => {
      const state = {
        service: 'my-service',
        spanKind: 'client',
        timeframe: 3600000,
        hideService: true,
      };
      const url = getUrl(state);
      expect(url).toContain(ROUTE_PATH);
      expect(url).toContain('service=my-service');
      expect(url).toContain('spanKind=client');
      expect(url).toContain('timeframe=3600000');
      expect(url).toContain('hideService=true');
    });
  });
});
