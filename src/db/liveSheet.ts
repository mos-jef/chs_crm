// The live Google Sheet export. One spreadsheet, shared by the whole team —
// its ID is stored in a single Firestore config doc so everyone's app points
// at the same sheet without any per-user setup beyond the one-time "Create
// Live Sheet" click in Settings.
//
// Sync happens from properties.ts's upsertProperty/deleteProperty, so every
// save in the app pushes to the sheet — see the note in
// electron/sheetsService.js about what "live" means in a desktop-app
// architecture with no always-on server.

import { doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { PropertyFile, estimatedMargin } from './schema';

export interface LiveSheetConfig {
  spreadsheetId: string;
  url: string;
}

function configDoc() {
  return doc(db, 'appConfig', 'liveSheet');
}

export async function getLiveSheetConfig(): Promise<LiveSheetConfig | null> {
  const snap = await getDoc(configDoc());
  return snap.exists() ? (snap.data() as LiveSheetConfig) : null;
}

export async function createLiveSheet(): Promise<LiveSheetConfig> {
  const result = await window.electronAPI.sheetsCreate({ title: 'CHS CRM — Properties' });
  if (!result.success || !result.spreadsheetId || !result.url) {
    throw new Error(result.error || 'Could not create the sheet.');
  }
  const config: LiveSheetConfig = { spreadsheetId: result.spreadsheetId, url: result.url };
  await setDoc(configDoc(), config);
  return config;
}

function nextOrLastAuctionDate(property: PropertyFile): number | undefined {
  if (!property.auctions || property.auctions.length === 0) return undefined;
  const upcoming = property.auctions
    .filter((a) => !a.auctionCompleted)
    .sort((a, b) => a.auctionDate - b.auctionDate)[0];
  if (upcoming) return upcoming.auctionDate;
  const past = [...property.auctions].sort((a, b) => b.auctionDate - a.auctionDate)[0];
  return past?.auctionDate;
}

function formatDate(ms?: number): string {
  return ms ? new Date(ms).toLocaleDateString() : '';
}

// Column order matches the columns you asked for, with File Number added as
// the leading column since it's what rows get matched/updated by.
export function propertyToRow(property: PropertyFile): string[] {
  const owner = property.contacts.find((c) => c.role === 'Owner')?.name || property.contacts[0]?.name || '';
  const margin = estimatedMargin(property);
  return [
    property.fileNumber,
    property.address,
    property.state,
    property.county || '',
    owner,
    property.amountOwed != null ? String(property.amountOwed) : '',
    margin != null ? String(margin) : '',
    formatDate(nextOrLastAuctionDate(property)),
  ];
}

// Silently no-ops if the live sheet hasn't been created yet, or if the sync
// call fails (e.g. Drive not connected) — a sheet sync problem should never
// block or roll back the actual property save.
export async function syncPropertyToSheet(property: PropertyFile): Promise<void> {
  try {
    const config = await getLiveSheetConfig();
    if (!config) return;
    await window.electronAPI.sheetsUpsertRow({
      spreadsheetId: config.spreadsheetId,
      rowValues: propertyToRow(property),
    });
  } catch (err) {
    console.warn('Live sheet sync failed (non-fatal):', err);
  }
}

export async function removePropertyFromSheet(fileNumber: string): Promise<void> {
  try {
    const config = await getLiveSheetConfig();
    if (!config) return;
    await window.electronAPI.sheetsDeleteRow({ spreadsheetId: config.spreadsheetId, fileNumber });
  } catch (err) {
    console.warn('Live sheet row removal failed (non-fatal):', err);
  }
}

export async function fullResync(properties: PropertyFile[]): Promise<void> {
  const config = await getLiveSheetConfig();
  if (!config) throw new Error('No live sheet set up yet — create one first.');
  await window.electronAPI.sheetsFullResync({
    spreadsheetId: config.spreadsheetId,
    rows: properties.map(propertyToRow),
  });
}
