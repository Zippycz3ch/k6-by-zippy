import { sleep } from "k6";
import { postPizza } from "../../../../interface/api/pizza/postPizza.js";
import { getScenarioConfig, getCommonThresholds, logTestStart, logTestEnd } from "../../../../helpers/testConfig.js";

export const options = {
  scenarios: {
    [__ENV.SCENARIO || "20iter-5vu"]: getScenarioConfig("postPizzaTest"),
  },
  thresholds: getCommonThresholds({
    "http_req_duration{name:Pizza/GetRecommendation}": ["p(95)<600"],
  }),
};

export function postPizzaTest() {
  logTestStart();

  const pizzaData = postPizza();

  if (pizzaData?.pizza?.name) {
    console.log(`✓ Pizza: "${pizzaData.pizza.name}" | Calories: ${pizzaData.calories} | Vegetarian: ${pizzaData.vegetarian}`);
  }

  sleep(1);
  logTestEnd();
}
