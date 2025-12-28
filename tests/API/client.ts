import { QuickPizzaAPIClient } from '/helpers/API/quickPizzaAPI.ts'

export const BASE_URL = __ENV.BASE_URL || 'https://quickpizza.grafana.com'
export const TOKEN = __ENV.PIZZA_TOKEN || "abcdef0123456789"
    ;
export function createClient() {
    return new QuickPizzaAPIClient({
        baseUrl: BASE_URL,
        commonRequestParameters: {
            headers: {
                'Authorization': `Token ${TOKEN}`,
                'Accept': 'application/json',
            },
        },
    })
}
