import http from "k6/http";
import { checkResponse } from "../../../helpers/API/checkResponse.js";

export function getIngredients(token, type) {
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    tags: { name: "Pizza/GetIngredients" },
  };

  const res = http.get(`${__ENV.BASEURL}/api/ingredients/${type}`, params);

  const { data } = checkResponse(res, params.tags.name);

  return data.ingredients;
}
