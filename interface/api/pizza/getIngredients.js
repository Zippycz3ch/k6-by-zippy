import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.js";

export function getIngredients(token, type) {
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    tags: { name: "Pizza/GetIngredients" },
  };

  const url = `${__ENV.BASEURL}/api/ingredients/${type}`;
  console.log(`[API REQUEST] Full URL: ${url}`);
  const res = http.get(url, params);

  const { data } = check200(res, params.tags.name);

  return data.ingredients;
}
