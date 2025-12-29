import { postUsers } from "../interface/api/users/postUsers.js";

export function registerUsersForTest(maxVUs) {
  console.log(`Registering ${maxVUs} users for test...`);

  const baseUsername = `testuser_${Date.now()}`;
  const password = "securePassword123";
  const userDataArray = [];

  for (let i = 0; i < maxVUs; i++) {
    const username = `${baseUsername}_VU${i + 1}`;
    const registerResponse = postUsers(username, password);

    if (registerResponse?.id) {
      userDataArray.push({
        username: username,
        password: password,
        userId: registerResponse.id,
      });
      console.log(`✓ Registered user: ${username} (ID: ${registerResponse.id})`);
    }
  }

  console.log(`Registration complete: ${userDataArray.length}/${maxVUs} users ready`);

  return userDataArray;
}
