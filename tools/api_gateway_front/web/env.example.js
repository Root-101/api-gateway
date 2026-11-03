// Copy to web/env.js (git-ignored) to run the console locally.
// In Docker, env.js is generated on container start from the env vars with the same names.
window.env = {
  GATEWAY_SERVICE_URL: 'http://localhost:8080',
  ADMIN_PATH: '_admin',
  //optional: minutes of inactivity before logout, 0 = disabled
  SESSION_TIMEOUT_MINUTES: 0
};
