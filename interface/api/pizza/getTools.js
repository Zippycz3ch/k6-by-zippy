import http from "k6/http";
import { checkResponse } from "../../../helpers/API/checkResponse.js";

export function getTools(token) {
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    tags: { name: "Pizza/GetTools" },
  };

  const res = http.get(`${__ENV.BASEURL}/api/tools`, params);

  const { data } = checkResponse(res, params.tags.name);

  return data.tools;
}
