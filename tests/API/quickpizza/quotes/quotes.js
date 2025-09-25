import http from "k6/http";
import { check, sleep } from "k6";

export let options = {
  executor: "shared-iterations",
  vus: 1,
  iterations: 1,
  duration: "10m",
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed: ["rate<0.01"],
    checks: ["rate>0.99"],
  },
};

const BASE_URL = "https://quickpizza.grafana.com";

export default function () {
  const res = http.get(`${BASE_URL}/api/quotes`);

  console.log(JSON.parse(res.body).quotes);

  check(res, {
    "GET /api/quotes status is 200": (r) => r.status === 200,
    "GET /api/quotes is not empty": (r) => Array.isArray(JSON.parse(r.body).quotes) && JSON.parse(r.body).quotes.length > 0,
  });

  sleep(1);
}
