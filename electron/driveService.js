// Drive folder resolution + upload/download.
//
// The key piece: resolveDocumentFolder walks State -> County -> File (tax
// account number, or file number as a fallback) -> Category, creating each
// level only if it doesn't already exist (lazy creation — adding a brand new
// category doesn't touch any existing file's folders, it just means the next
// upload under that category creates one new subfolder on demand).
//
// Every file gets referenced elsewhere by its Drive file ID, never by path —
// that's the piece that actually fixes title-crm's path-migration problem.

// Scoped package instead of the full "googleapis" meta-package — same API,
// a fraction of the install size, since it only bundles the Drive API
// instead of every Google API there is.
const { drive: createDriveClient } = require('@googleapis/drive');
const fs = require('fs');

function driveClient(auth) {
  return createDriveClient({ version: 'v3', auth });
}

function escapeForQuery(name) {
  return name.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

async function findFolder(drive, name, parentId) {
  const q = `name = '${escapeForQuery(name)}' and mimeType = 'application/vnd.google-apps.folder' and '${parentId}' in parents and trashed = false`;
  const res = await drive.files.list({
    q,
    includeItemsFromAllDrives: true,
    supportsAllDrives: true,
    corpora: 'allDrives',
    fields: 'files(id, name)',
  });
  return res.data.files && res.data.files[0];
}

async function createFolder(drive, name, parentId) {
  const res = await drive.files.create({
    requestBody: {
      name,
      mimeType: 'application/vnd.google-apps.folder',
      parents: [parentId],
    },
    supportsAllDrives: true,
    fields: 'id, name',
  });
  return res.data;
}

async function ensureFolder(drive, name, parentId) {
  const cleanName = (name || 'Unspecified').trim() || 'Unspecified';
  const existing = await findFolder(drive, cleanName, parentId);
  if (existing) return existing.id;
  const created = await createFolder(drive, cleanName, parentId);
  return created.id;
}

// segments: e.g. [state, county, fileKey, categoryFolderName]
async function resolveFolderPath(auth, sharedDriveId, segments) {
  const drive = driveClient(auth);
  let parentId = sharedDriveId;
  for (const segment of segments) {
    parentId = await ensureFolder(drive, segment, parentId);
  }
  return parentId;
}

async function uploadFile(auth, { folderId, filePath, fileName, mimeType }) {
  const drive = driveClient(auth);
  const res = await drive.files.create({
    requestBody: { name: fileName, parents: [folderId] },
    media: {
      mimeType: mimeType || 'application/octet-stream',
      body: fs.createReadStream(filePath),
    },
    supportsAllDrives: true,
    fields: 'id, name, webViewLink',
  });
  return res.data;
}

async function downloadFileToPath(auth, { fileId, destPath }) {
  const drive = driveClient(auth);
  const dest = fs.createWriteStream(destPath);
  const res = await drive.files.get(
    { fileId, alt: 'media', supportsAllDrives: true },
    { responseType: 'stream' }
  );
  return new Promise((resolve, reject) => {
    res.data
      .on('end', () => resolve(destPath))
      .on('error', reject)
      .pipe(dest);
  });
}

async function getFileMetadata(auth, fileId) {
  const drive = driveClient(auth);
  const res = await drive.files.get({
    fileId,
    supportsAllDrives: true,
    fields: 'id, name, webViewLink, mimeType',
  });
  return res.data;
}

module.exports = {
  resolveFolderPath,
  uploadFile,
  downloadFileToPath,
  getFileMetadata,
  ensureFolder,
  driveClient,
};
