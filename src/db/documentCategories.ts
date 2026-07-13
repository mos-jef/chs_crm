// The extensible document-category system.
//
// This is the piece that answers "how do I add new subfolders without
// confusing Firestore/the CRM/Drive": category definitions live here, in
// Firestore, not hardcoded as an enum in the app. The Document Reader's
// dropdown, the Drive folder-resolution logic, and each property's document
// list all read from this same collection. Adding "Surveys" as a new
// category later is a data change (one new doc in this collection via the
// Settings screen), not a code change.
//
// `key` is permanent once created — it's what gets stored on DocumentRef
// and used to resolve the Drive folder path. `folderName` can be renamed
// later without breaking existing document references, because lookups
// always go through `key`, never through the folder name directly.

import {
  collection,
  doc,
  getDocs,
  setDoc,
  deleteDoc,
  orderBy,
  query,
} from 'firebase/firestore';
import { db } from '../firebase';
import { generateId } from './schema';

export interface DocumentCategory {
  key: string;
  label: string;
  folderName: string; // Drive subfolder name — usually same as label, kept separate
                        // so a rename doesn't require renaming the actual Drive folder
  sortOrder: number;
  extractionTemplateId?: string; // optional — which AI extraction template the
                                   // Document Reader defaults to for this category
}

const COLLECTION = 'documentCategories';

// Seeded on first run (see ensureSeeded below). Deeds absorbs vesting/chain-of-
// title docs, Judgments absorbs liens/HOA liens — per your call, not split
// into separate categories.
const DEFAULT_CATEGORIES: Omit<DocumentCategory, 'key'>[] = [
  { label: 'Deeds', folderName: 'Deeds', sortOrder: 1 },
  { label: 'Mortgages', folderName: 'Mortgages', sortOrder: 2 },
  { label: 'Judgments', folderName: 'Judgments', sortOrder: 3 },
  { label: 'Easements', folderName: 'Easements', sortOrder: 4 },
  { label: 'Taxes', folderName: 'Taxes', sortOrder: 5 },
];

function categoriesCollection() {
  return collection(db, COLLECTION);
}

export async function getDocumentCategories(): Promise<DocumentCategory[]> {
  const snap = await getDocs(query(categoriesCollection(), orderBy('sortOrder')));
  return snap.docs.map((d) => d.data() as DocumentCategory);
}

export async function addDocumentCategory(
  input: Omit<DocumentCategory, 'key'>
): Promise<DocumentCategory> {
  const key = generateId('cat');
  const category: DocumentCategory = { ...input, key };
  await setDoc(doc(categoriesCollection(), key), category);
  return category;
}

export async function updateDocumentCategoryLabel(
  key: string,
  label: string,
  folderName: string
): Promise<void> {
  await setDoc(
    doc(categoriesCollection(), key),
    { label, folderName },
    { merge: true }
  );
}

export async function deleteDocumentCategory(key: string): Promise<void> {
  // Note: this only removes the category from the picker/list. It does NOT
  // touch documents already filed under it or their Drive folder — deleting
  // a category should never delete files. Existing DocumentRefs keep their
  // documentCategoryKey; they just won't show up as an option for new uploads.
  await deleteDoc(doc(categoriesCollection(), key));
}

// Call once on app startup (cheap no-op after the first run — checks if the
// collection is empty before writing anything). Returns the full category
// list either way, so callers (documentTemplates.ts's seeding) can key
// default templates off the actual generated keys without a second read.
export async function ensureSeeded(): Promise<DocumentCategory[]> {
  const existing = await getDocumentCategories();
  if (existing.length > 0) return existing;

  const created: DocumentCategory[] = [];
  for (const cat of DEFAULT_CATEGORIES) {
    const key = generateId('cat');
    const full = { ...cat, key };
    await setDoc(doc(categoriesCollection(), key), full);
    created.push(full);
  }
  return created;
}
