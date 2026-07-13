// Firestore CRUD for the `properties` collection.
//
// Deliberately does NOT mirror title-crm's database.ts pattern of also
// syncing every write to a local file on disk via electronAPI.saveParcels —
// that local-file mirror is exactly the mechanism that caused the path-
// migration pain in title-crm. Firestore is the single source of truth here;
// the localStorage cache below is purely for instant UI reads/offline
// resilience, not a second copy anything else depends on.

import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  deleteDoc,
} from 'firebase/firestore';
import { db } from '../firebase';
import { PropertyFile } from './schema';
import { syncPropertyToSheet, removePropertyFromSheet } from './liveSheet';

const COLLECTION = 'properties';
const CACHE_KEY = 'chscrm_properties_cache';

function propertiesCollection() {
  return collection(db, COLLECTION);
}

function cacheGet(): PropertyFile[] {
  const raw = localStorage.getItem(CACHE_KEY);
  if (!raw) return [];
  try {
    return JSON.parse(raw) as PropertyFile[];
  } catch {
    return [];
  }
}

function cacheSet(properties: PropertyFile[]): void {
  localStorage.setItem(CACHE_KEY, JSON.stringify(properties));
}

export async function loadProperties(): Promise<PropertyFile[]> {
  try {
    const snap = await getDocs(propertiesCollection());
    const properties = snap.docs.map((d) => d.data() as PropertyFile);
    cacheSet(properties);
    return properties;
  } catch (err) {
    console.error('Firestore load failed, falling back to cache', err);
    return cacheGet();
  }
}

// Single-property fetch for the detail view — goes straight to Firestore
// rather than filtering the full cached list, so opening one file doesn't
// depend on having loaded everything else first.
export async function getProperty(id: string): Promise<PropertyFile | null> {
  try {
    const snap = await getDoc(doc(propertiesCollection(), id));
    if (snap.exists()) return snap.data() as PropertyFile;
  } catch (err) {
    console.error('Firestore getProperty failed, falling back to cache', err);
  }
  return cacheGet().find((p) => p.id === id) ?? null;
}

export async function upsertProperty(property: PropertyFile): Promise<void> {
  const updated = { ...property, updatedAt: Date.now() };
  await setDoc(doc(propertiesCollection(), updated.id), updated);

  const all = cacheGet();
  const idx = all.findIndex((p) => p.id === updated.id);
  if (idx >= 0) all[idx] = updated;
  else all.push(updated);
  cacheSet(all);

  // Fire-and-forget — see liveSheet.ts for why a sync failure here should
  // never block or roll back the actual save.
  syncPropertyToSheet(updated);
}

export async function deleteProperty(id: string): Promise<void> {
  const existing = cacheGet().find((p) => p.id === id);
  await deleteDoc(doc(propertiesCollection(), id));
  cacheSet(cacheGet().filter((p) => p.id !== id));
  if (existing) removePropertyFromSheet(existing.fileNumber);
}

// Search by name (across contacts), address, file number, or tax account
// number — per the original spec plus the tax-account-number lookup you
// asked for with the county tax-card workflow.
export function searchProperties(
  properties: PropertyFile[],
  query: string
): PropertyFile[] {
  const q = query.trim().toLowerCase();
  if (!q) return properties;
  return properties.filter((p) => {
    return (
      p.fileNumber.toLowerCase().includes(q) ||
      p.address.toLowerCase().includes(q) ||
      (p.taxAccountNumber ?? '').toLowerCase().includes(q) ||
      (p.mapNo ?? '').toLowerCase().includes(q) ||
      p.contacts.some((c) => c.name.toLowerCase().includes(q))
    );
  });
}
