// Load config at init stage (global scope) - open() can only be called here
const configData = JSON.parse(open("/config.json"));

export function getEnvironmentConfig() {
  const environment = __ENV.ENVIRONMENT || "prod";
  const env = configData.environments[environment];

  return {
    environment,
    baseUrl: __ENV.BASEURL || env.baseUrl,
    token: __ENV.PIZZA_TOKEN || configData.auth.pizzaToken,
    thresholds: configData.thresholds,
  };
}
