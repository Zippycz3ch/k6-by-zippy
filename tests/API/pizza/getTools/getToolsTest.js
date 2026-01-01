import { sleep } from "k6";
import { getTools } from "../../../../interface/api/pizza/getTools.js";
import { getScenarioConfig, getCommonThresholds, logTestStart, logTestEnd } from "../../../../helpers/testConfig.js";

export const options = {
  scenarios: {
    [__ENV.SCENARIO || "20iter-5vu"]: getScenarioConfig("getToolsTest"),
  },
  thresholds: getCommonThresholds({
    "http_req_duration{name:Pizza/GetTools}": ["p(95)<600"],
  }),
};

export function getToolsTest() {
  logTestStart();

  const tools = getTools();

  if (tools?.tools) {
    console.log(`Retrieved ${tools.tools.length} tools`);
  }

  sleep(1);
  logTestEnd();
}
