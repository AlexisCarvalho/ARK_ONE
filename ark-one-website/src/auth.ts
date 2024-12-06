export let authToken: string | null = null;

export function setAuthToken(token: string) {
  authToken = token;
}
