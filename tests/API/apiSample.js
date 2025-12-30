import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  thresholds: {
    checks: ["rate>0.99"],
    http_req_duration: ["p(95)<1000"],
    http_req_failed: ["rate<0.01"],
  },
  scenarios: {
    default: {
      executor: "shared-iterations",
      vus: 1,
      iterations: 10,
      maxDuration: "5m",
      exec: "apiSampleTest",
    },
  },
};

export function setup() {
  const baseUrl = __ENV.BASEURL || "http://quickpizza:3333";
  const token = __ENV.PIZZA_TOKEN;
  return { baseUrl, token };
}

export function apiSampleTest(data) {
  const { baseUrl, token } = data;
  const testName = "API Sample - Get Doughs";

  console.log(`--- Starting: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);

  // Make API request with auth header
  const url = `${baseUrl}/api/doughs`;
  console.log(`[API TEST] Full URL: ${url}`);
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  };
  const res = http.get(url, params);

  // Basic checks
  check(res, {
    [`${testName} - Response status is 200`]: (r) => r.status === 200,
    [`${testName} - Response has body`]: (r) => r.body && r.body.length > 0,
    [`${testName} - Response is JSON`]: (r) => {
      try {
        JSON.parse(r.body);
        return true;
      } catch {
        return false;
      }
    },
    [`${testName} - Response contains doughs array`]: (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body.doughs);
      } catch {
        return false;
      }
    },
  });

  sleep(1);
  console.log(`--- Finished: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);
}
