import http from "k6/http";
import { check201 } from "../../../helpers/API/checkResponse.ts";

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

  const { data } = check201(res, params.tags.name);

  return data;
}
