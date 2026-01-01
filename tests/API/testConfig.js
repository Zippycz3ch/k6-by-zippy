// Common test configuration helpers

const SCENARIO_CONFIGS = {
  "1iter": { vus: 1, iterations: 1 },
  "20iter-1vu": { vus: 1, iterations: 20 },
  "20iter-5vu": { vus: 5, iterations: 20 },
  "20iter-10vu": { vus: 10, iterations: 20 },
  "100iter-1vu": { vus: 1, iterations: 100 },
  "100iter-5vu": { vus: 5, iterations: 100 },
  "100iter-10vu": { vus: 10, iterations: 100 },
};

export function getScenarioConfig(execName) {
  const scenario = __ENV.SCENARIO || "20iter-5vu";

  return {
    executor: "shared-iterations",
    ...SCENARIO_CONFIGS[scenario],
    maxDuration: "5m",
    exec: execName,
  };
}

export function getCommonThresholds(customThresholds = {}) {
  return {
    checks: ["rate>0.99"],
    http_req_duration: ["p(95)<1000"],
    http_req_failed: ["rate<0.01"],
    ...customThresholds,
  };
}

export function logTestStart() {
  console.log(`--- VUs Started | ITER ${__ITER} | VU ${__VU} ---`);
}

export function logTestEnd() {
  console.log(`--- VUs Finished | ITER ${__ITER} | VU ${__VU} ---`);
}
