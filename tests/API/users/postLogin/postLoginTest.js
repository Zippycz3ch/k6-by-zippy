import { sleep } from "k6";
import { postLogin } from "../../../../interface/api/users/postLogin.js";
import { registerUsersForTest } from "../../../../helpers/registerUsersForTest.js";
import { getReadyUser } from "../../../../helpers/getReadyUser.js";
import { getScenarioConfig, getCommonThresholds, logTestStart, logTestEnd } from "../../testConfig.js";

export const options = {
  scenarios: {
    [__ENV.SCENARIO || "20iter-5vu"]: getScenarioConfig("postLoginTest"),
  },
  thresholds: getCommonThresholds({
    "http_req_duration{name:Users/Login}": ["p(95)<800"],
  }),
};

export function setup() {
  const scenarioConfig = getScenarioConfig("postLoginTest");
  const maxVUs = scenarioConfig.vus || 1;

  console.log(`Max VUs: ${maxVUs}`);

  const userDataArray = registerUsersForTest(maxVUs);

  return {
    userDataArray,
  };
}

export function postLoginTest(data) {
  logTestStart();

  const userDataArray = data.userDataArray;
  const userData = getReadyUser(userDataArray);

  const loginResponse = postLogin(userData.username, userData.password, true);

  if (loginResponse?.token) {
    console.log(`Login successful for user: ${userData.username} - Token received`);
  }

  sleep(1);
  logTestEnd();
}
