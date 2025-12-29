import http from "k6/http";
import { checkResponse } from "../../../helpers/API/checkResponse.js";

export function getPizzaById(token, pizzaId) {
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    tags: { name: "Pizza/GetById" },
  };

  const res = http.get(`${__ENV.BASEURL}/api/pizza/${pizzaId}`, params);

  const { data } = checkResponse(res, params.tags.name);

  return data;
}
