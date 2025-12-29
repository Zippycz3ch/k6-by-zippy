import { sleep } from "k6";
import { postLogin } from "../../../../interface/api/users/postLogin.js";
import { registerUsersForTest } from "../../../../helpers/registerUsersForTest.js";
import { getReadyUser } from "../../../../helpers/getReadyUser.js";

function getScenarioConfig() {
  const scenario = __ENV.SCENARIO || "20iter-5vu";

  const configs = {
    "1iter": { vus: 1, iterations: 1 },
    "20iter-1vu": { vus: 1, iterations: 20 },
    "20iter-5vu": { vus: 5, iterations: 20 },
    "20iter-10vu": { vus: 10, iterations: 20 },
    "100iter-1vu": { vus: 1, iterations: 100 },
    "100iter-5vu": { vus: 5, iterations: 100 },
    "100iter-10vu": { vus: 10, iterations: 100 },
  };

  return {
    executor: "shared-iterations",
    ...configs[scenario],
    maxDuration: "5m",
    exec: "postLoginTest",
  };
}

export const options = {
  scenarios: {
    [__ENV.SCENARIO || "20iter-5vu"]: getScenarioConfig(),
  },
  thresholds: {
    checks: ["rate>0.99"],
    http_req_duration: ["p(95)<1000"],
    http_req_failed: ["rate<0.01"],
    "http_req_duration{name:Users/Login}": ["p(95)<800"],
  },
};

export function setup() {
  const scenarioConfig = getScenarioConfig();
  const maxVUs = scenarioConfig.vus || 1;

  console.log(`Max VUs: ${maxVUs}`);

  const userDataArray = registerUsersForTest(maxVUs);

  const data = {
    userDataArray,
  };

  return data;
}

export function postLoginTest(data) {
  console.log(`--- VUs Started | ITER ${__ITER} | VU ${__VU} ---`);

  const userDataArray = data.userDataArray;
  const userData = getReadyUser(userDataArray);

  const loginResponse = postLogin(userData.username, userData.password, true);

  if (loginResponse?.token) {
    console.log(`Login successful for user: ${userData.username} - Token received`);
  }

  sleep(1);
  console.log(`--- VUs Finished | ITER ${__ITER} | VU ${__VU} ---`);
}

export function teardown() {
  console.log("Test completed");
}
