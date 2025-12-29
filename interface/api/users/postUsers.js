import http from "k6/http";
import { checkResponse } from "../../../helpers/API/checkResponse.js";

export function postUsers(username, password) {
  const payload = JSON.stringify({
    username: username,
    password: password,
  });

  const params = {
    headers: {
      "Content-Type": "application/json",
    },
    tags: { name: "Users/Register" },
  };

  const res = http.post(`${__ENV.BASEURL}/api/users`, payload, params);

  const { data } = checkResponse(res, params.tags.name);

  return data;
}
