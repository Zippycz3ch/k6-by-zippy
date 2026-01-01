interface ScenarioConfig {
    vus?: number;
    startVUs?: number;
    stages?: Array<{
        duration: string;
        target: number;
    }>;
}

export function getMaxVUsConfig(scenarioConfig: ScenarioConfig): number {
    let maxVUs = 1;

    // Handle shared-iterations executor
    if (scenarioConfig.vus && scenarioConfig.vus > maxVUs) {
        maxVUs = scenarioConfig.vus;
    }

    // Handle ramping-vus executor - check stages for max target
    if (scenarioConfig.stages) {
        for (const stage of scenarioConfig.stages) {
            if (stage.target && stage.target > maxVUs) {
                maxVUs = stage.target;
            }
        }
    }

    // Fallback to startVUs if no stages found
    if (scenarioConfig.startVUs && scenarioConfig.startVUs > maxVUs) {
        maxVUs = scenarioConfig.startVUs;
    }

    return maxVUs;
}
