import { sleep } from 'k6'
import { options } from './config.ts'
import { createClient, BASE_URL } from './client.ts'
import { validateResponse } from '/helpers/API/helpers.ts'

export { options }

const client = createClient()

export default function () {
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
        //     console.log(`  - Dough: ${data.pizza?.dough?.name}`)
        //     console.log(`  - Ingredients: ${data.pizza?.ingredients?.map(i => i.name).join(', ')}`)
        //     console.log(`  - Tool: ${data.pizza?.tool}`)
        //     console.log(`  - Calories: ${data.calories} per slice`)
        //     console.log(`  - Vegetarian: ${data.vegetarian}`)
    } else {
        console.error('✗ Pizza recommendation failed checks')
    }

    sleep(1)
}

export function setup() {
    console.log('🍕 Starting QuickPizza API Load Test')
    console.log(`Base URL: ${BASE_URL}`)
}

export function teardown() {
    console.log('✅ Test completed')
}