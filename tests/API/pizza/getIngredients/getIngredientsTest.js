import { sleep } from "k6";
import { getIngredients } from "../../../../interface/api/pizza/getIngredients.js";
import { getScenarioConfig, getCommonThresholds, logTestStart, logTestEnd } from "../../../../helpers/testConfig.js";

export const options = {
  scenarios: {
    [__ENV.SCENARIO || "20iter-5vu"]: getScenarioConfig("getIngredientsTest"),
  },
  thresholds: getCommonThresholds({
    "http_req_duration{name:Pizza/GetIngredients}": ["p(95)<600"],
  }),
};

export function getIngredientsTest() {
  logTestStart();

  const ingredients = getIngredients("topping");

  if (ingredients?.ingredients) {
    console.log(`Retrieved ${ingredients.ingredients.length} topping ingredients`);
  }

  sleep(1);
  logTestEnd();
}
