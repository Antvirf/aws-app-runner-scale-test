import { check } from 'k6';
import http from 'k6/http';

import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";

const endpoint = "https://txh3vgn4dm.ap-southeast-1.awsapprunner.com/";

export const options = {
    scenarios: {
        main: {
            executor: 'constant-vus',
            vus: 500,
            duration: '5m',
        }
    }
};

export function handleSummary(data) {
    let filename = "./report_summary.html"
    let result = {}
    result[filename] = htmlReport(data)
    return result
}

export default function () {
    // Open app - basic unauth fetches
    const resTC = http.get(`${endpoint}/api/test`);
    check(resTC, { 'response status was 200 OK': (r) => r.status == 200 });
}
