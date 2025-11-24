export let authToken: string | null = null;
export let userName: string | null = null;

const userNameListeners: Array<(name: string | null) => void> = [];

export function setAuthToken(token: string | null) {
  authToken = token;
}

export function setUserName(name: string | null) {
  userName = name;
  // notify listeners
  userNameListeners.forEach((cb) => {
    try { cb(userName); } catch (e) { /* ignore */ }
  });
}

export function getUserName() {
  return userName;
}

export function subscribeUserName(cb: (name: string | null) => void) {
  userNameListeners.push(cb);
  // return unsubscribe
  return () => {
    const idx = userNameListeners.indexOf(cb);
    if (idx >= 0) userNameListeners.splice(idx, 1);
  };
}
