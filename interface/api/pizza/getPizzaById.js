import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.js";

export function getPizzaById(pizzaId) {
  const params = {
    headers: {
      Authorization: `Bearer ${__ENV.PIZZA_TOKEN}`,
    },
    tags: { name: "Pizza/GetById" },
  };

  const url = `${__ENV.BASEURL}/api/pizza/${pizzaId}`;
  const res = http.get(url, params);

  const { data } = check200(res, params.tags.name);

  return data;
}
