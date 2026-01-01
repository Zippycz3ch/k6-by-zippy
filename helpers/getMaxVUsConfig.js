export function getMaxVUsConfig(scenarioConfig) {
  let maxVUs = 1;

  // Handle shared-iterations executor
  if (scenarioConfig.vus && scenarioConfig.vus > maxVUs) {
    maxVUs = scenarioConfig.vus;
  }

  // Handle ramping-vus executor
  if (scenarioConfig.startVUs && scenarioConfig.startVUs > maxVUs) {
    maxVUs = scenarioConfig.startVUs;
  }

  if (scenarioConfig.stages) {
    for (const stage of scenarioConfig.stages) {
      if (stage.target && stage.target > maxVUs) {
        maxVUs = stage.target;
      }
    }
  }

  return maxVUs;
}
