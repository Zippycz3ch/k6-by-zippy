import http from "k6/http";

export function makeRequest(method, url, useAuth, token) {
  const headers = { "Content-Type": "application/json" };

  if (useAuth) {
    headers["Authorization"] = `token ${token}`;
  }

  const body = method === "POST" ? JSON.stringify({}) : undefined;

  if (method === "POST") {
    return http.post(url, body, { headers });
  } else if (method === "PUT") {
    return http.put(url, body, { headers });
  } else if (method === "DELETE") {
    return http.del(url, undefined, { headers });
  } else {
    return http.get(url, { headers });
  }
}
