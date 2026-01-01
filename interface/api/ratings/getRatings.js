import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.ts";

export function getRatings() {
  const params = {
    headers: {
      Authorization: `Bearer ${__ENV.PIZZA_TOKEN}`,
    },
    tags: { name: "Ratings/GetAll" },
  };

  const res = http.get(`${__ENV.BASEURL}/api/ratings`, params);

  const { data } = check200(res, params.tags.name);

  return data;
}
