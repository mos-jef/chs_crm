// Electron main process.
//
// Google Drive OAuth and API calls live in electron/driveAuth.js and
// electron/driveService.js — that code has to run here (Node, main process),
// not in the renderer, since it needs local token storage and a loopback
// HTTP server for the OAuth redirect. The renderer talks to it through the
// IPC handlers below, exposed via preload.js as window.electronAPI.

const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');

// In dev, .env sits next to this file as normal. In a packaged build, this
// file runs from inside app.asar, so .env can't live alongside it — it's
// copied out to the app's resources folder instead (see extraResources in
// package.json). app.isPackaged is how you tell which situation you're in.
require('dotenv').config({
  path: app.isPackaged ? path.join(process.resourcesPath, '.env') : path.join(__dirname, '.env'),
});

const { getAuthenticatedClient, signOut } = require('./electron/driveAuth');
const driveService = require('./electron/driveService');
const sheetsService = require('./electron/sheetsService');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  const startUrl =
    process.env.ELECTRON_START_URL ||
    `file://${path.join(__dirname, 'build', 'index.html')}`;

  mainWindow.loadURL(startUrl);
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});

// ── Local file picking (still useful even though documents end up in Drive —
//    the user picks a local PDF/image first, then it gets uploaded) ──────────

ipcMain.handle('pick-file', async (_event, options = {}) => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
    filters: options.filters || [
      { name: 'Documents', extensions: ['pdf', 'jpg', 'jpeg', 'png'] },
    ],
  });
  if (result.canceled || result.filePaths.length === 0) {
    return { success: false };
  }
  const filePath = result.filePaths[0];
  return { success: true, filePath, fileName: path.basename(filePath) };
});

ipcMain.handle('pick-folder', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openDirectory'],
  });
  if (result.canceled || result.filePaths.length === 0) {
    return { success: false };
  }
  return { success: true, folderPath: result.filePaths[0] };
});

ipcMain.handle('scan-folder-for-pdfs', async (_event, folderPath) => {
  try {
    const entries = fs.readdirSync(folderPath);
    const files = entries
      .filter((f) => f.toLowerCase().endsWith('.pdf'))
      .map((f) => ({ name: f, path: path.join(folderPath, f) }));
    return { success: true, files };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('read-file-base64', async (_event, filePath) => {
  try {
    const buffer = fs.readFileSync(filePath);
    return { success: true, base64: buffer.toString('base64') };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

// ── Google Drive ───────────────────────────────────────────────────────────

function requireSharedDriveId() {
  const id = process.env.GOOGLE_SHARED_DRIVE_ID;
  if (!id) {
    throw new Error('GOOGLE_SHARED_DRIVE_ID is not set in .env — see README.');
  }
  return id;
}

ipcMain.handle('drive-auth-start', async () => {
  try {
    await getAuthenticatedClient(app);
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('drive-sign-out', async () => {
  signOut(app);
  return { success: true };
});

// Uploads a document under State/County/FileKey/Category, creating any
// folder in that chain that doesn't exist yet. fileKey is the tax account
// number if there is one, otherwise the file number — resolved on the
// renderer side and passed in here.
ipcMain.handle('drive-upload-document', async (_event, args) => {
  try {
    const auth = await getAuthenticatedClient(app);
    const sharedDriveId = requireSharedDriveId();
    const folderId = await driveService.resolveFolderPath(auth, sharedDriveId, [
      args.state,
      args.county,
      args.fileKey,
      args.categoryFolderName,
    ]);
    const result = await driveService.uploadFile(auth, {
      folderId,
      filePath: args.filePath,
      fileName: args.fileName,
      mimeType: args.mimeType,
    });
    return { success: true, driveFileId: result.id, webViewLink: result.webViewLink };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

// Avatars go in a single flat "User Avatars" folder at the Shared Drive root
// rather than the state/county/file tree — they're not tied to a property.
ipcMain.handle('drive-upload-avatar', async (_event, args) => {
  try {
    const auth = await getAuthenticatedClient(app);
    const sharedDriveId = requireSharedDriveId();
    const folderId = await driveService.resolveFolderPath(auth, sharedDriveId, ['User Avatars']);
    const result = await driveService.uploadFile(auth, {
      folderId,
      filePath: args.filePath,
      fileName: args.fileName,
      mimeType: args.mimeType,
    });
    return { success: true, driveFileId: result.id };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('drive-download-file', async (_event, args) => {
  try {
    const auth = await getAuthenticatedClient(app);
    const destPath = path.join(os.tmpdir(), `chscrm_${args.fileId}_${args.fileName || 'file'}`);
    await driveService.downloadFileToPath(auth, { fileId: args.fileId, destPath });
    return { success: true, path: destPath };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('drive-get-file-metadata', async (_event, args) => {
  try {
    const auth = await getAuthenticatedClient(app);
    const meta = await driveService.getFileMetadata(auth, args.fileId);
    return { success: true, meta };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

// ── Live Google Sheet export ─────────────────────────────────────────────────

ipcMain.handle('sheets-create', async (_event, args) => {
  try {
    const auth = await getAuthenticatedClient(app);
    const result = await sheetsService.createSpreadsheet(auth, args.title || 'CHS CRM — Properties');
    const sharedDriveId = process.env.GOOGLE_SHARED_DRIVE_ID;
    if (sharedDriveId) {
      await sheetsService.moveToSharedDrive(auth, result.spreadsheetId, sharedDriveId);
    }
    return { success: true, spreadsheetId: result.spreadsheetId, url: result.url };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('sheets-upsert-row', async (_event, args) => {
  try {
    const auth = await getAuthenticatedClient(app);
    await sheetsService.upsertRow(auth, args.spreadsheetId, args.rowValues);
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('sheets-delete-row', async (_event, args) => {
  try {
    const auth = await getAuthenticatedClient(app);
    await sheetsService.deleteRowByFileNumber(auth, args.spreadsheetId, args.fileNumber);
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('sheets-full-resync', async (_event, args) => {
  try {
    const auth = await getAuthenticatedClient(app);
    await sheetsService.fullResync(auth, args.spreadsheetId, args.rows);
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

// ── Document Reader — AI extraction ─────────────────────────────────────────
//
// Generalized across categories: the renderer passes the field list from the
// resolved template (see src/db/documentTemplates.ts — already picked for
// the right county/state before this is called), not this file. This code
// doesn't know or care whether it's reading a tax card or a deed; it just
// asks for whatever fields it's given.

ipcMain.handle('claude-extract-document', async (_event, args) => {
  try {
    if (!process.env.CLAUDE_API_KEY) {
      throw new Error('CLAUDE_API_KEY is not set in .env — see README.');
    }
    if (!args.fields || args.fields.length === 0) {
      throw new Error('No template fields provided.');
    }

    const fieldList = args.fields
      .map((f) => `- ${f.key}: ${f.label}${f.description ? ' — ' + f.description : ''}`)
      .join('\n');

    const locationBits = [args.county && `${args.county} County`, args.state].filter(Boolean).join(', ');
    const prompt = `You are extracting structured data from a scanned ${args.categoryLabel || 'property'} document${locationBits ? ` (${locationBits})` : ''}.

Extract exactly these fields and return ONLY a JSON object with these keys (use "" for anything you can't find — never omit a key, never add extra keys):
${fieldList}

Return nothing but the JSON object. No markdown fences, no commentary.`;

    const mimeType = args.mimeType || 'application/pdf';
    const isImage = mimeType.startsWith('image/');
    const contentBlock = isImage
      ? { type: 'image', source: { type: 'base64', media_type: mimeType, data: args.base64 } }
      : { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: args.base64 } };

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': process.env.CLAUDE_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-5',
        max_tokens: 1024,
        messages: [{ role: 'user', content: [contentBlock, { type: 'text', text: prompt }] }],
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Claude API error (${response.status}): ${text.slice(0, 300)}`);
    }

    const data = await response.json();
    const textBlock = (data.content || []).find((b) => b.type === 'text');
    if (!textBlock) throw new Error('No text content in the response.');

    let jsonStr = textBlock.text.trim();
    jsonStr = jsonStr.replace(/^```(json)?/i, '').replace(/```$/, '').trim();

    let extracted;
    try {
      extracted = JSON.parse(jsonStr);
    } catch {
      throw new Error(`Couldn't parse extraction result as JSON: ${jsonStr.slice(0, 200)}`);
    }

    return { success: true, extracted };
  } catch (err) {
    return { success: false, error: err.message };
  }
});
