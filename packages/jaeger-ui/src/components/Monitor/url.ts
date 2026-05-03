// Copyright (c) 2021 The Jaeger Authors.
// SPDX-License-Identifier: Apache-2.0

import queryString from 'query-string';
import { matchPath } from 'react-router-dom';

import prefixUrl from '../../utils/prefix-url';

export const ROUTE_PATH = prefixUrl('/monitor');

export type MonitorUrlState = {
  service?: string;
  spanKind?: string;
  timeframe?: string | number;
  hideService?: boolean;
};

export function matches(path: string) {
  const pathname = path.split('?')[0];
  return Boolean(matchPath(ROUTE_PATH, pathname));
}

export function parseMonitorUrl(search: string): MonitorUrlState {
  const params = queryString.parse(search);
  return {
    service: params.service as string,
    spanKind: params.spanKind as string,
    timeframe: params.timeframe as string,
    hideService: params.hideService === 'true',
  };
}

export function getUrl(state?: MonitorUrlState) {
  if (!state) return ROUTE_PATH;

  const params: Record<string, string | number | boolean> = {};
  if (state.service) params.service = state.service;
  if (state.spanKind) params.spanKind = state.spanKind;
  if (state.timeframe) params.timeframe = state.timeframe;
  if (state.hideService) params.hideService = true;

  const search = queryString.stringify(params);
  return search ? `${ROUTE_PATH}?${search}` : ROUTE_PATH;
}
