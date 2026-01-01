import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.ts";

export function getTools() {
  const params = {
    headers: {
      Authorization: `Bearer ${__ENV.PIZZA_TOKEN}`,
    },
    tags: { name: "Pizza/GetTools" },
  };

  const url = `${__ENV.BASEURL}/api/tools`;
  const res = http.get(url, params);

  const { data } = check200(res, params.tags.name);

  return data.tools;
}
