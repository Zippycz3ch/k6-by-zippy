import http from "k6/http";
import { check201 } from "../../../helpers/API/checkResponse.js";

export function postRatings(pizzaId, stars) {
  const payload = JSON.stringify({
    pizza_id: pizzaId,
    stars: stars,
  });

  const params = {
    headers: {
      Authorization: `Bearer ${__ENV.PIZZA_TOKEN}`,
      "Content-Type": "application/json",
    },
    tags: { name: "Ratings/Create" },
  };

  const url = `${__ENV.BASEURL}/api/ratings`;
  console.log(`[API REQUEST] Full URL: ${url}`);
  const res = http.post(url, payload, params);

  const { data } = check201(res, params.tags.name);

  return data;
}
