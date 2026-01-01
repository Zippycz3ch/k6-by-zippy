import { sleep } from "k6";
import { getDoughs } from "../../../../interface/api/pizza/getDoughs.js";
import { getScenarioConfig, getCommonThresholds, logTestStart, logTestEnd } from "../../testConfig.js";

export const options = {
  scenarios: {
    [__ENV.SCENARIO || "20iter-5vu"]: getScenarioConfig("getDoughsTest"),
  },
  thresholds: getCommonThresholds({
    "http_req_duration{name:Pizza/GetDoughs}": ["p(95)<600"],
  }),
};

export function getDoughsTest() {
  logTestStart();

  const doughs = getDoughs();

  if (doughs?.doughs) {
    console.log(`Retrieved ${doughs.doughs.length} doughs`);
  }

  sleep(1);
  logTestEnd();
}

export function teardown() {
  console.log("Test completed");
}
