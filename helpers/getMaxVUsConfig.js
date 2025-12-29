export function getMaxVUsConfig(optionsJson) {
  let maxVUs = 1;

  if (optionsJson.scenarios) {
    for (const scenarioName in optionsJson.scenarios) {
      const scenario = optionsJson.scenarios[scenarioName];
      if (scenario.vus && scenario.vus > maxVUs) {
        maxVUs = scenario.vus;
      }
      if (scenario.stages) {
        for (const stage of scenario.stages) {
          if (stage.target && stage.target > maxVUs) {
            maxVUs = stage.target;
          }
        }
      }
    }
  }

  return maxVUs;
}
