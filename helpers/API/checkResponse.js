import { check } from "k6";

function parseJsonData(res, tagName) {
  if (!res.body || res.body.length === 0) {
    return null;
  }

  try {
    return res.json();
  } catch (e) {
    console.error(`${tagName} - Failed to parse JSON: ${e.message}`);
    return null;
  }
}

export function check200(res, tagName) {
  const data = parseJsonData(res, tagName);

  const checks = check(res, {
    [`${tagName} - Status is 200`]: (r) => r.status === 200,
  });

  if (!checks) {
    console.error(`${tagName} - Failed: status ${res.status}, body: ${res.body}`);
  }

  return { checks, data };
}

export function check201(res, tagName) {
  const data = parseJsonData(res, tagName);

  const checks = check(res, {
    [`${tagName} - Status is 201`]: (r) => r.status === 201,
  });

  if (!checks) {
    console.error(`${tagName} - Failed: status ${res.status}, body: ${res.body}`);
  }

  return { checks, data };
}

export function check400(res, tagName) {
  const data = parseJsonData(res, tagName);

  const checks = check(res, {
    [`${tagName} - Status is 400`]: (r) => r.status === 400,
    [`${tagName} - Has error message`]: () => data && data.error,
  });

  return { checks, data };
}

export function check401(res, tagName) {
  const data = parseJsonData(res, tagName);

  const checks = check(res, {
    [`${tagName} - Status is 401`]: (r) => r.status === 401,
    [`${tagName} - Has authentication error`]: () => data && data.error,
  });

  return { checks, data };
}

export function check403(res, tagName) {
  const data = parseJsonData(res, tagName);

  const checks = check(res, {
    [`${tagName} - Status is 403`]: (r) => r.status === 403,
    [`${tagName} - Has error message`]: () => data && data.error,
  });

  return { checks, data };
}
