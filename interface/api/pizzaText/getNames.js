import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.js";

export function getNames() {
  const params = {
    tags: { name: "PizzaText/GetNames" },
  };

  const res = http.get(`${__ENV.BASEURL}/api/names`, params);

  const { data } = check200(res, params.tags.name);

  return data;
}
