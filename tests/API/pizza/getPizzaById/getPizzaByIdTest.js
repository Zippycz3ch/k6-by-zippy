import { sleep } from "k6";
import { getPizzaById } from "../../../../interface/api/pizza/getPizzaById.js";
import { postPizza } from "../../../../interface/api/pizza/postPizza.js";
import { getScenarioConfig, getCommonThresholds, logTestStart, logTestEnd } from "../../testConfig.js";

export const options = {
  scenarios: {
    [__ENV.SCENARIO || "20iter-5vu"]: getScenarioConfig("getPizzaByIdTest"),
  },
  thresholds: getCommonThresholds({
    "http_req_duration{name:Pizza/GetById}": ["p(95)<600"],
  }),
};

export function setup() {
  const pizza = postPizza();

  return {
    pizzaId: pizza?.pizza?.id,
  };
}

export function getPizzaByIdTest(data) {
  logTestStart();

  const pizzaId = data.pizzaId;

  if (pizzaId) {
    const pizza = getPizzaById(pizzaId);
    if (pizza) {
      console.log(`Retrieved pizza ID: ${pizzaId} - "${pizza.name}"`);
    }
  }

  sleep(1);
  logTestEnd();
}
