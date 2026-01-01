import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.js";

export function getDoughs() {
  const params = {
    headers: {
      Authorization: `Bearer ${__ENV.PIZZA_TOKEN}`,
    },
    tags: { name: "Pizza/GetDoughs" },
  };

  const url = `${__ENV.BASEURL}/api/doughs`;
  const res = http.get(url, params);

  const { data } = check200(res, params.tags.name);

  return data.doughs;
}
