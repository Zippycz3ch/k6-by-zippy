import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://host.docker.internal:3333";
const TOKEN = __ENV.PIZZA_TOKEN || "abcdef0123456789";

export const options = {
  vus: 1,
  iterations: 1,
  duration: "5s",
};

export default function () {
  let restrictions = {
    maxCaloriesPerSlice: 500,
    mustBeVegetarian: false,
    excludedIngredients: ["pepperoni"],
    excludedTools: ["knife"],
    maxNumberOfToppings: 6,
    minNumberOfToppings: 2,
  };

  let headers = {
    "Content-Type": "application/json",
    "Authorization": `Token ${TOKEN}`,
    "Accept": "application/json",
  };

  let res = http.post(`${BASE_URL}/api/pizza`, JSON.stringify(restrictions), { headers });

  check(res, {
    "status is 200": (res) => res.status === 200,
    "has pizza object": (res) => {
      try {
        const json = res.json();
        return !!json.pizza && !!json.pizza.name;
      } catch {
        return false;
      }
    },
  });

  try {
    const pizza = res.json().pizza;
    console.log(`${pizza.name} (${pizza.ingredients.length} ingredients)`);
  } catch (e) {
    console.log("No pizza recommendation received. Body:", res.body);
  }

  sleep(1);
}
