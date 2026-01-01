const GREEN = "\x1b[32m";
const RESET = "\x1b[0m";

interface UserData {
    username: string;
    password: string;
    userId: number;
}

export function getReadyUser(userDataArray: UserData[]): UserData {
    const userData = userDataArray[__VU - 1]; // VU starts at 1, array index starts at 0

    console.log(`${GREEN}Selected User: ${userData.username}${RESET}`);

    return userData;
}
