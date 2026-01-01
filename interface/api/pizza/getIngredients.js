import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.ts";

export function getIngredients(type) {
  const params = {
    headers: {
      Authorization: `Bearer ${__ENV.PIZZA_TOKEN}`,
    },
    tags: { name: "Pizza/GetIngredients" },
  };

  const url = `${__ENV.BASEURL}/api/ingredients/${type}`;
  const res = http.get(url, params);

  const { data } = check200(res, params.tags.name);

  return data.ingredients;
}
