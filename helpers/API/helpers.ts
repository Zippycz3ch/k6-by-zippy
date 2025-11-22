import { check } from 'k6'

export function validateResponse(response) {
    return check(response, {
        'status is 200': (r) => r.status === 200,
    })
}
