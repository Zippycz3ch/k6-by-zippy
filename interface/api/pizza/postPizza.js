import http from "k6/http";
import { checkResponse } from "../../../helpers/API/checkResponse.js";

export function postPizza(token) {
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    tags: { name: "Pizza/GetRecommendation" },
  };

  const res = http.post(`${__ENV.BASEURL}/api/pizza`, JSON.stringify({}), params);

  const { data } = checkResponse(res, params.tags.name);

  return data;
}
