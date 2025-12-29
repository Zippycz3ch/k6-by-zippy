import http from "k6/http";
import { checkResponse } from "../../../helpers/API/checkResponse.js";

export function getDoughs(token) {
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    tags: { name: "Pizza/GetDoughs" },
  };

  const res = http.get(`${__ENV.BASEURL}/api/doughs`, params);

  const { data } = checkResponse(res, params.tags.name);

  return data.doughs;
}
