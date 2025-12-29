import { check } from "k6";

export function checkResponse(res, tagName) {
  const isSuccess = res.status >= 200 && res.status < 300;

  if (!isSuccess) {
    console.error(`${tagName} - API failed with status ${res.status}, response: ${res.body}`);
  }

  let jsonData = null;

  // Only parse JSON if there's a body
  if (res.body && res.body.length > 0) {
    try {
      jsonData = res.json();
    } catch (e) {
      console.error(`${tagName} - Failed to parse JSON: ${e.message}`);
    }
  }

  const checks = check(res, {
    [`${tagName} - Succeeded:`]: (r) => r.status >= 200 && r.status < 300,
    [`-${tagName} - Response status code is 2xx`]: (r) => r.status >= 200 && r.status < 300,
  });

  return { checks, data: jsonData };
}
