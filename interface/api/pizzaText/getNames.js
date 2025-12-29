import http from "k6/http";
import { checkResponse } from "../../../helpers/API/checkResponse.js";

export function getNames() {
  const params = {
    tags: { name: "PizzaText/GetNames" },
  };

  const res = http.get(`${__ENV.BASEURL}/api/names`, params);

  const { data } = checkResponse(res, params.tags.name);

  return data;
}
