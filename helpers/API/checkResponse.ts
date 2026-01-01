import { check } from "k6";
import { RefinedResponse, ResponseType } from "k6/http";

interface CheckResult {
    checks: boolean;
    data: any;
}

function parseJsonData(res: RefinedResponse<ResponseType>, tagName: string): any {
    if (!res.body || (typeof res.body === 'string' && res.body.length === 0)) {
        return null;
    }

    try {
        return res.json();
    } catch (e) {
        console.error(`${tagName} - Failed to parse JSON: ${(e as Error).message}`);
        return null;
    }
}

export function check200(res: RefinedResponse<ResponseType>, tagName: string): CheckResult {
    const data = parseJsonData(res, tagName);

    const checks = check(res, {
        [`${tagName} - Status is 200`]: (r) => r.status === 200,
    });

    if (!checks) {
        console.error(`${tagName} - Failed: status ${res.status}, body: ${res.body}`);
    }

    return { checks, data };
}

export function check201(res: RefinedResponse<ResponseType>, tagName: string): CheckResult {
    const data = parseJsonData(res, tagName);

    const checks = check(res, {
        [`${tagName} - Status is 201`]: (r) => r.status === 201,
    });

    if (!checks) {
        console.error(`${tagName} - Failed: status ${res.status}, body: ${res.body}`);
    }

    return { checks, data };
}

export function check400(res: RefinedResponse<ResponseType>, tagName: string): CheckResult {
    const data = parseJsonData(res, tagName);

    const checks = check(res, {
        [`${tagName} - Status is 400`]: (r) => r.status === 400,
        [`${tagName} - Has error message`]: () => data && data.error,
    });

    return { checks, data };
}

export function check401(res: RefinedResponse<ResponseType>, tagName: string): CheckResult {
    const data = parseJsonData(res, tagName);

    const checks = check(res, {
        [`${tagName} - Status is 401`]: (r) => r.status === 401,
        [`${tagName} - Has authentication error`]: () => data && data.error,
    });

    return { checks, data };
}

export function check403(res: RefinedResponse<ResponseType>, tagName: string): CheckResult {
    const data = parseJsonData(res, tagName);

    const checks = check(res, {
        [`${tagName} - Status is 403`]: (r) => r.status === 403,
        [`${tagName} - Has error message`]: () => data && data.error,
    });

    return { checks, data };
}
