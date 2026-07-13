// Google Drive OAuth — the "Loopback IP address" flow Google recommends for
// installed/desktop apps. No fixed redirect port needs pre-registering in
// Cloud Console when the OAuth client is type "Desktop app" — Google accepts
// any localhost port for that client type, so we just spin up a throwaway
// local server, catch the redirect, and tear it down.
//
// Scopes are drive.file (the app can only see/touch files and folders it
// creates itself — never a general browse of the whole Shared Drive) plus
// spreadsheets, needed later for the live Sheet export phase. Least-privilege
// on purpose: since this app always creates its own State/County/File/
// Category folder tree, it never needs broader Drive access.

const { OAuth2Client } = require('google-auth-library');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { shell } = require('electron');

const SCOPES = [
  'https://www.googleapis.com/auth/drive.file',
  'https://www.googleapis.com/auth/spreadsheets',
];

let cachedClient = null;

function tokenPath(app) {
  return path.join(app.getPath('userData'), 'drive-token.json');
}

function loadSavedTokens(app) {
  try {
    return JSON.parse(fs.readFileSync(tokenPath(app), 'utf8'));
  } catch {
    return null;
  }
}

function saveTokens(app, tokens) {
  fs.writeFileSync(tokenPath(app), JSON.stringify(tokens), 'utf8');
}

function requireEnv() {
  if (!process.env.GOOGLE_CLIENT_ID || !process.env.GOOGLE_CLIENT_SECRET) {
    throw new Error(
      'GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET are not set — copy .env.example to .env and fill them in (see README).'
    );
  }
}

async function getAuthenticatedClient(app) {
  requireEnv();
  if (cachedClient) return cachedClient;

  const saved = loadSavedTokens(app);
  if (saved) {
    const client = new OAuth2Client({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    });
    client.setCredentials(saved);
    client.on('tokens', (tokens) => saveTokens(app, { ...saved, ...tokens }));
    cachedClient = client;
    return client;
  }

  return startInteractiveAuth(app);
}

function startInteractiveAuth(app) {
  return new Promise((resolve, reject) => {
    let port;

    const server = http.createServer(async (req, res) => {
      try {
        const reqUrl = new URL(req.url, 'http://127.0.0.1');
        const code = reqUrl.searchParams.get('code');
        const error = reqUrl.searchParams.get('error');

        if (error) {
          res.end(`Sign-in was cancelled (${error}). You can close this tab.`);
          server.close();
          reject(new Error(error));
          return;
        }
        if (!code) {
          res.end('No authorization code received — you can close this tab.');
          return;
        }

        res.end('Signed in to Google Drive — you can close this tab and go back to CHS CRM.');
        server.close();

        const redirectUri = `http://127.0.0.1:${port}/oauth2callback`;
        const client = new OAuth2Client({
          clientId: process.env.GOOGLE_CLIENT_ID,
          clientSecret: process.env.GOOGLE_CLIENT_SECRET,
          redirectUri,
        });
        const { tokens } = await client.getToken(code);
        client.setCredentials(tokens);
        saveTokens(app, tokens);
        client.on('tokens', (newTokens) => saveTokens(app, { ...tokens, ...newTokens }));
        cachedClient = client;
        resolve(client);
      } catch (err) {
        reject(err);
      }
    });

    server.listen(0, '127.0.0.1', () => {
      port = server.address().port;
      const redirectUri = `http://127.0.0.1:${port}/oauth2callback`;
      const authClient = new OAuth2Client({
        clientId: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        redirectUri,
      });
      const authUrl = authClient.generateAuthUrl({
        access_type: 'offline', // required to get a refresh_token back
        prompt: 'consent', // forces a refresh_token even on repeat sign-ins
        scope: SCOPES,
      });
      shell.openExternal(authUrl);
    });
  });
}

function signOut(app) {
  cachedClient = null;
  try {
    fs.unlinkSync(tokenPath(app));
  } catch {}
}

module.exports = { getAuthenticatedClient, signOut };
