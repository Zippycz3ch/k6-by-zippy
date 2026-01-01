import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.ts";

export function deleteRatings(ratingId) {
  const params = {
    headers: {
      Authorization: `Bearer ${__ENV.PIZZA_TOKEN}`,
    },
    tags: { name: "Ratings/Delete" },
  };

  const res = http.del(`${__ENV.BASEURL}/api/ratings/${ratingId}`, null, params);

  const { data } = check200(res, params.tags.name);

  return data;
}
