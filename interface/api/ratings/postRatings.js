import http from "k6/http";
import { checkResponse } from "../../../helpers/API/checkResponse.js";

export function postRatings(token, pizzaId, stars) {
  const payload = JSON.stringify({
    pizza_id: pizzaId,
    stars: stars,
  });

  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    tags: { name: "Ratings/Create" },
  };

  const res = http.post(`${__ENV.BASEURL}/api/ratings`, payload, params);

  const { data } = checkResponse(res, params.tags.name);

  return data;
}
