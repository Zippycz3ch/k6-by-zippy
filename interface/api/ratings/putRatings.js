import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.js";

export function putRatings(token, ratingId, pizzaId, stars) {
  const payload = JSON.stringify({
    pizza_id: pizzaId,
    stars: stars,
  });

  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    tags: { name: "Ratings/Update" },
  };

  const res = http.put(`${__ENV.BASEURL}/api/ratings/${ratingId}`, payload, params);

  const { data } = check200(res, params.tags.name);

  return data;
}
