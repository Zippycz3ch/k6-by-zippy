import http from 'k6/http'
import { BASE_URL, TOKEN } from './config.ts'

export function createClient() {
    return {
        get(path: string, params = {}) {
            const headers = TOKEN ? {
                'Authorization': `Bearer ${TOKEN}`,
                'Accept': 'application/json',
            } : {
                'Accept': 'application/json',
            }
            
            return http.get(`${BASE_URL}${path}`, {
                headers,
                ...params,
            })
        }
    }
}
