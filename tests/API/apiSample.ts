import { sleep } from 'k6'
import { createClient, BASE_URL } from './quickPizza/client.ts'
import { validateResponse } from '/helpers/API/helpers.ts'

export const options = {
    thresholds: {
        checks: ['rate>0.99'],
        http_req_duration: ['p(95)<500'],
        http_req_failed: ['rate<0.01'],
    },
    scenarios: {
        default: {
            executor: 'shared-iterations',
            vus: 1,
            iterations: 10,
            maxDuration: '5m',
            exec: 'test',
        },
    },
}

const client = createClient()

export function test() {
    const { response, data } = client.getPizzaRecommendation({
        maxCaloriesPerSlice: 800,
        mustBeVegetarian: true,
        excludedIngredients: ['anchovies', 'bacon'],
        maxNumberOfToppings: 4,
        minNumberOfToppings: 2,
    })

    const checks = validateResponse(response)

    if (checks) {
        console.log(`✓ Got pizza: "${data.pizza?.name}"`)
    } else {
        console.error('✗ Pizza recommendation failed checks')
    }

    sleep(1)
}

export function setup() {
    console.log('🍕 Starting QuickPizza API Sample Test')
    console.log(`Base URL: ${BASE_URL}`)
}

export function teardown() {
    console.log('✅ Sample test completed')
}
