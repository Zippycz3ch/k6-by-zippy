const GREEN = "\x1b[32m";
const RESET = "\x1b[0m";

export function getReadyUser(userDataArray) {
  const userData = userDataArray[__VU - 1]; // VU starts at 1, array index starts at 0

  console.log(`${GREEN}Selected User: ${userData.username}${RESET}`);

  return userData;
}
