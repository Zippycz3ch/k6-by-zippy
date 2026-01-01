import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.ts";

export function getQuotes() {
  const params = {
    tags: { name: "PizzaText/GetQuotes" },
  };

  const res = http.get(`${__ENV.BASEURL}/api/quotes`, params);

  const { data } = check200(res, params.tags.name);

  return data;
}
