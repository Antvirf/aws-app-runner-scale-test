import { check } from 'k6';
import http from 'k6/http';

import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";

const endpoint = ""; // Update with the HTTPS URL of your specific App Runner service

export const options = {
    scenarios: {
        rps_test: {
            executor: 'constant-arrival-rate',
            rate: 100,
            timeUnit: '1s',
            duration: `5m`,
            preAllocatedVUs: 10000,
            maxVUs: 10000,
        },
    },
};

export function handleSummary(data) {
    let filename = "./report_summary.html"
    let result = {}
    result[filename] = htmlReport(data)
    return result
}

export default function () {
    const resTC = http.get(`${endpoint}/api/test`);
    check(resTC, { 'response status was 200 OK': (r) => r.status == 200 });
}
