import { sleep } from "k6";
import { postPizza } from "../../../../interface/api/pizza/postPizza.js";

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
    exec: "postPizzaTest",
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
    "http_req_duration{name:Pizza/GetRecommendation}": ["p(95)<600"],
  },
};

export function postPizzaTest() {
  console.log(`--- VUs Started | ITER ${__ITER} | VU ${__VU} ---`);

  const pizzaData = postPizza();

  if (pizzaData?.pizza?.name) {
    console.log(`✓ Pizza: "${pizzaData.pizza.name}" | Calories: ${pizzaData.calories} | Vegetarian: ${pizzaData.vegetarian}`);
  }

  sleep(1);
  console.log(`--- VUs Finished | ITER ${__ITER} | VU ${__VU} ---`);
}

export function teardown() {
  console.log("✅ Teardown: Test completed");
}
