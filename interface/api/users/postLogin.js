import http from "k6/http";
import { check200 } from "../../../helpers/API/checkResponse.ts";

export function postLogin(username, password, setCookie = false) {
  const payload = JSON.stringify({
    username: username,
    password: password,
  });

  const params = {
    headers: {
      "Content-Type": "application/json",
    },
    tags: { name: "Users/Login" },
  };

  const url = setCookie ? `${__ENV.BASEURL}/api/users/token/login?set_cookie=true` : `${__ENV.BASEURL}/api/users/token/login`;

  const res = http.post(url, payload, params);

  const { data } = check200(res, params.tags.name);

  return data;
}
