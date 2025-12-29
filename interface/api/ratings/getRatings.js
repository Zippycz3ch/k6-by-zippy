import http from "k6/http";
import { checkResponse } from "../../../helpers/API/checkResponse.js";

export function getRatings(token) {
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    tags: { name: "Ratings/GetAll" },
  };

  const res = http.get(`${__ENV.BASEURL}/api/ratings`, params);

  const { data } = checkResponse(res, params.tags.name);

  return data;
}
