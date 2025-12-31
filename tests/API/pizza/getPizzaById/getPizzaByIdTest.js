import { sleep } from "k6";
import { getPizzaById } from "../../../../interface/api/pizza/getPizzaById.js";
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
    exec: "getPizzaByIdTest",
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
    "http_req_duration{name:Pizza/GetById}": ["p(95)<600"],
  },
};

export function setup() {
  const pizza = postPizza();

  return {
    pizzaId: pizza?.pizza?.id,
  };
}

export function getPizzaByIdTest(data) {
  console.log(`--- VUs Started | ITER ${__ITER} | VU ${__VU} ---`);

  const pizzaId = data.pizzaId;

  if (pizzaId) {
    const pizza = getPizzaById(pizzaId);
    if (pizza) {
      console.log(`Retrieved pizza ID: ${pizzaId} - "${pizza.name}"`);
    }
  }

  sleep(1);
  console.log(`--- VUs Finished | ITER ${__ITER} | VU ${__VU} ---`);
}

export function teardown() {
  console.log("Test completed");
}
