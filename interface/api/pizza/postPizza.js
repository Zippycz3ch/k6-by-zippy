import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.js";

export function postPizza() {
  const params = {
    headers: {
      Authorization: `Bearer ${__ENV.PIZZA_TOKEN}`,
      "Content-Type": "application/json",
    },
    tags: { name: "Pizza/GetRecommendation" },
  };

  const url = `${__ENV.BASEURL}/api/pizza`;
  console.log(`[API REQUEST] Full URL: ${url}`);
  const res = http.post(url, JSON.stringify({}), params);

  const { data } = check200(res, params.tags.name);

  return data;
}
