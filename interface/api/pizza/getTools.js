import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.js";

export function getTools(token) {
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    tags: { name: "Pizza/GetTools" },
  };

  const url = `${__ENV.BASEURL}/api/tools`;
  console.log(`[API REQUEST] Full URL: ${url}`);
  const res = http.get(url, params);

  const { data } = check200(res, params.tags.name);

  return data.tools;
}
