import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.js";

export function getPizzaById(token, pizzaId) {
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    tags: { name: "Pizza/GetById" },
  };

  const url = `${__ENV.BASEURL}/api/pizza/${pizzaId}`;
  console.log(`[API REQUEST] Full URL: ${url}`);
  const res = http.get(url, params);

  const { data } = check200(res, params.tags.name);

  return data;
}
