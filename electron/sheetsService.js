// Live Google Sheet export.
//
// "Live" here means: every time anyone saves a property in the app, that
// property's row gets pushed to the Sheet right then — not a scheduled job,
// not a manual export. There's no always-on server in this architecture (it's
// a desktop app, not a hosted backend), so true push-on-every-Firestore-write
// via a Cloud Function isn't in scope — but since every edit already goes
// through the app's save path, syncing from there gets you the same result
// in practice for a small team, with none of the Cloud Functions/Blaze-plan
// overhead.
//
// Rows are matched by File Number (assumed unique — it already is, it's the
// CRM's primary lookup key). A Full Resync (clear + rewrite everything) is
// available for backfilling existing data or recovering if the sheet and
// Firestore ever drift apart.

// Scoped packages instead of the full "googleapis" meta-package — same API,
// a fraction of the install size. This file needs both: Sheets for the rows,
// Drive just for the one-time move into the Shared Drive after creating a
// new spreadsheet.
const { sheets: createSheetsClient } = require('@googleapis/sheets');
const { drive: createDriveClient } = require('@googleapis/drive');

const HEADER = ['File Number', 'Address', 'State', 'County', 'Owner', 'Amount Owed', 'Margin', 'Auction/Sale Date'];
const SHEET_NAME = 'Properties';

function sheetsClient(auth) {
  return createSheetsClient({ version: 'v4', auth });
}

async function createSpreadsheet(auth, title) {
  const sheets = sheetsClient(auth);
  const res = await sheets.spreadsheets.create({
    requestBody: {
      properties: { title },
      sheets: [{ properties: { title: SHEET_NAME } }],
    },
  });
  const spreadsheetId = res.data.spreadsheetId;
  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: `${SHEET_NAME}!A1`,
    valueInputOption: 'RAW',
    requestBody: { values: [HEADER] },
  });
  return { spreadsheetId, url: res.data.spreadsheetUrl };
}

// Optionally moves the new spreadsheet into the Shared Drive so it's owned
// by the team, not by whoever happened to click "Create".
async function moveToSharedDrive(auth, fileId, sharedDriveId) {
  if (!sharedDriveId) return;
  const drive = createDriveClient({ version: 'v3', auth });
  const file = await drive.files.get({ fileId, fields: 'parents', supportsAllDrives: true });
  const previousParents = (file.data.parents || []).join(',');
  await drive.files.update({
    fileId,
    addParents: sharedDriveId,
    removeParents: previousParents,
    supportsAllDrives: true,
    fields: 'id, parents',
  });
}

async function readFileNumberColumn(auth, spreadsheetId) {
  const sheets = sheetsClient(auth);
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId,
    range: `${SHEET_NAME}!A2:A`,
  });
  return (res.data.values || []).map((row) => row[0] || '');
}

async function upsertRow(auth, spreadsheetId, rowValues) {
  const sheets = sheetsClient(auth);
  const fileNumbers = await readFileNumberColumn(auth, spreadsheetId);
  const idx = fileNumbers.findIndex((f) => f === rowValues[0]);

  if (idx >= 0) {
    const rowNum = idx + 2; // +2: 1-indexed, plus header row
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `${SHEET_NAME}!A${rowNum}:H${rowNum}`,
      valueInputOption: 'RAW',
      requestBody: { values: [rowValues] },
    });
  } else {
    await sheets.spreadsheets.values.append({
      spreadsheetId,
      range: `${SHEET_NAME}!A2`,
      valueInputOption: 'RAW',
      insertDataOption: 'INSERT_ROWS',
      requestBody: { values: [rowValues] },
    });
  }
}

async function deleteRowByFileNumber(auth, spreadsheetId, fileNumber) {
  const sheets = sheetsClient(auth);
  const fileNumbers = await readFileNumberColumn(auth, spreadsheetId);
  const idx = fileNumbers.findIndex((f) => f === fileNumber);
  if (idx < 0) return;

  const meta = await sheets.spreadsheets.get({ spreadsheetId });
  const sheet = meta.data.sheets.find((s) => s.properties.title === SHEET_NAME);
  const sheetId = sheet.properties.sheetId;
  const rowIndex = idx + 1; // 0-indexed, +1 to skip header

  await sheets.spreadsheets.batchUpdate({
    spreadsheetId,
    requestBody: {
      requests: [
        {
          deleteDimension: {
            range: {
              sheetId,
              dimension: 'ROWS',
              startIndex: rowIndex,
              endIndex: rowIndex + 1,
            },
          },
        },
      ],
    },
  });
}

async function fullResync(auth, spreadsheetId, rows) {
  const sheets = sheetsClient(auth);
  await sheets.spreadsheets.values.clear({ spreadsheetId, range: `${SHEET_NAME}!A2:H` });
  if (rows.length > 0) {
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `${SHEET_NAME}!A2`,
      valueInputOption: 'RAW',
      requestBody: { values: rows },
    });
  }
}

module.exports = { createSpreadsheet, moveToSharedDrive, upsertRow, deleteRowByFileNumber, fullResync };
