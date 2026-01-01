import { sleep } from "k6";
import { postRatings } from "../../../../interface/api/ratings/postRatings.js";
import { postPizza } from "../../../../interface/api/pizza/postPizza.js";
import { getScenarioConfig, getCommonThresholds, logTestStart, logTestEnd } from "../../../../helpers/testConfig.js";

export const options = {
  scenarios: {
    [__ENV.SCENARIO || "20iter-5vu"]: getScenarioConfig("postRatingsTest"),
  },
  thresholds: getCommonThresholds({
    "http_req_duration{name:Ratings/Create}": ["p(95)<800"],
  }),
};

export function setup() {
  const pizza = postPizza();

  return {
    pizzaId: pizza?.pizza?.id,
  };
}

export function postRatingsTest(data) {
  logTestStart();

  const pizzaId = data.pizzaId;

  if (pizzaId) {
    const stars = Math.floor(Math.random() * 5) + 1;
    const rating = postRatings(pizzaId, stars);

    if (rating?.id) {
      console.log(`Created rating ID: ${rating.id} - ${stars} stars for pizza ${pizzaId}`);
    }
  }

  sleep(1);
  logTestEnd();
}
