import { check } from 'k6';
import http from 'k6/http';


const endpoint = "https://ibwdkqptdr.ap-southeast-1.awsapprunner.com/api/test"; // Update with the HTTPS URL of your specific App Runner service and its endpoitn

const warmupPeriod = '20'
const periodDurationSeconds = '300'

export const options = {
    scenarios: {
        // warmup: {
        //     executor: 'constant-arrival-rate',
        //     rate: 5,
        //     timeUnit: '1s',
        //     duration: `${warmupPeriod}s`,
        //     preAllocatedVUs: 10000,
        //     maxVUs: 10000,
        // },
        rps_test_600: {
            executor: 'constant-arrival-rate',
            rate: 600,
            timeUnit: '1s',
            duration: `${periodDurationSeconds}s`,
            preAllocatedVUs: 10000,
            maxVUs: 10000,
            startTime: `${warmupPeriod}s`,
        },
        // rps_test_700: {
        //     executor: 'constant-arrival-rate',
        //     rate: 700,
        //     timeUnit: '1s',
        //     duration: `${periodDurationSeconds}s`,
        //     preAllocatedVUs: 10000,
        //     maxVUs: 10000,
        //     startTime: `${parseInt(warmupPeriod) + (parseInt(periodDurationSeconds) * 1)}s`
        // },
        // rps_test_750: {
        //     executor: 'constant-arrival-rate',
        //     rate: 750,
        //     timeUnit: '1s',
        //     duration: `${periodDurationSeconds}s`,
        //     preAllocatedVUs: 10000,
        //     maxVUs: 10000,
        //     startTime: `${parseInt(warmupPeriod) + (parseInt(periodDurationSeconds) * 2)}s`
        // },
        // rps_test_800: {
        //     executor: 'constant-arrival-rate',
        //     rate: 800,
        //     timeUnit: '1s',
        //     duration: `${periodDurationSeconds}s`,
        //     preAllocatedVUs: 10000,
        //     maxVUs: 10000,
        //     startTime: `${parseInt(warmupPeriod) + (parseInt(periodDurationSeconds) * 3)}s`
        // },
        // rps_test_900: {
        //     executor: 'constant-arrival-rate',
        //     rate: 900,
        //     timeUnit: '1s',
        //     duration: `${periodDurationSeconds}s`,
        //     preAllocatedVUs: 10000,
        //     maxVUs: 10000,
        //     startTime: `${parseInt(warmupPeriod) + (parseInt(periodDurationSeconds) * 4)}s`
        // },

    },
};

export default function () {
    const resTC = http.get(endpoint);
    check(resTC, { 'status 200': (r) => r.status == 200 });
}
