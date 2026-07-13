// Extraction templates for the Document Reader.
//
// Every county formats things differently, so a template is scoped to a
// category and OPTIONALLY a state+county — the Document Reader looks for a
// county-specific template first, then falls back to a state-wide one, then
// falls back to the category's plain default. That's the mechanism for "a
// template I can build out per county without confusing anything": adding a
// Multnomah County, OR override for the Taxes category doesn't touch the
// default Taxes template or any other category.
//
// applyTarget says where extracted fields land on the property record:
// 'overview' means top-level PropertyFile fields (+ a Contact for the owner),
// the rest append a record to the matching array (deeds, mortgages, etc.).
// 'none' means the file just gets filed — no field mapping attempted.

import {
  collection,
  doc,
  getDocs,
  setDoc,
  deleteDoc,
  query,
  where,
} from 'firebase/firestore';
import { db } from '../firebase';
import { generateId } from './schema';
import { DocumentCategory } from './documentCategories';

export type ApplyTarget = 'overview' | 'deeds' | 'mortgages' | 'judgments' | 'easements' | 'none';

export interface TemplateField {
  key: string;
  label: string;
  description?: string; // extra guidance for the AI — where on the document to look, alternate labels it might appear under, etc.
}

export interface DocumentTemplate {
  id: string;
  categoryKey: string;
  state?: string; // blank = applies to every state for this category
  county?: string; // blank = applies to every county in that state
  applyTarget: ApplyTarget;
  fields: TemplateField[];
}

const COLLECTION = 'documentTemplates';

function templatesCollection() {
  return collection(db, COLLECTION);
}

// Default field sets, seeded once per default category (see
// seedDefaultTemplates below). "Taxes" mirrors the nine fields you specified.
const DEFAULT_FIELDS_BY_LABEL: Record<string, { applyTarget: ApplyTarget; fields: TemplateField[] }> = {
  Taxes: {
    applyTarget: 'overview',
    fields: [
      { key: 'owner', label: 'Owner' },
      { key: 'address', label: 'Address' },
      { key: 'county', label: 'County' },
      { key: 'state', label: 'State' },
      { key: 'zipCode', label: 'Zip Code' },
      { key: 'taxAccountNumber', label: 'Tax Account No.' },
      { key: 'mapNo', label: 'Map No.' },
      { key: 'taxesPaidUnpaid', label: 'Taxes Paid/Unpaid', description: 'Answer exactly "Paid", "Unpaid", or "Unknown".' },
      { key: 'taxesOwing', label: 'Taxes Owing', description: 'Numeric dollar amount, no $ sign or commas.' },
    ],
  },
  Deeds: {
    applyTarget: 'deeds',
    fields: [
      { key: 'docTitle', label: 'Document Title', description: 'e.g. Warranty Deed, Sheriff\'s Deed, Quitclaim Deed' },
      { key: 'grantor', label: 'Grantor' },
      { key: 'grantee', label: 'Grantee' },
      { key: 'instrumentDate', label: 'Dated (instrument date)' },
      { key: 'recordingDate', label: 'Recording Date' },
      { key: 'book', label: 'Book' },
      { key: 'page', label: 'Page' },
      { key: 'instrumentNo', label: 'Instrument No.' },
    ],
  },
  Mortgages: {
    applyTarget: 'mortgages',
    fields: [
      { key: 'mortgageType', label: 'Type', description: 'Mortgage, Deed of Trust, or Other' },
      { key: 'borrower', label: 'Borrower (Grantor)' },
      { key: 'beneficiary', label: 'Beneficiary (Lender)' },
      { key: 'amount', label: 'Amount', description: 'Numeric, no $ or commas.' },
      { key: 'recordingDate', label: 'Recording Date' },
      { key: 'status', label: 'Status' },
    ],
  },
  Judgments: {
    applyTarget: 'judgments',
    fields: [
      { key: 'recordType', label: 'Type', description: 'Judgment, Lien, or Other' },
      { key: 'caseNumber', label: 'Case/Reference No.' },
      { key: 'debtor', label: 'Debtor' },
      { key: 'grantee', label: 'Grantee/Creditor' },
      { key: 'county', label: 'County' },
      { key: 'state', label: 'State' },
      { key: 'amount', label: 'Amount' },
      { key: 'status', label: 'Status' },
      { key: 'filedDate', label: 'Filed Date' },
    ],
  },
  Easements: {
    applyTarget: 'easements',
    fields: [
      { key: 'easementType', label: 'Type' },
      { key: 'grantor', label: 'Grantor' },
      { key: 'grantee', label: 'Grantee' },
      { key: 'recordingDate', label: 'Recording Date' },
      { key: 'status', label: 'Status', description: 'Active, Released, Expired, or Unknown' },
    ],
  },
};

export async function getTemplatesForCategory(categoryKey: string): Promise<DocumentTemplate[]> {
  const snap = await getDocs(query(templatesCollection(), where('categoryKey', '==', categoryKey)));
  return snap.docs.map((d) => d.data() as DocumentTemplate);
}

// The lookup: county-specific match wins, then state-wide, then plain default.
export async function resolveTemplate(
  categoryKey: string,
  state?: string,
  county?: string
): Promise<DocumentTemplate | null> {
  const all = await getTemplatesForCategory(categoryKey);
  if (all.length === 0) return null;

  const norm = (s?: string) => (s || '').trim().toLowerCase();

  const countyMatch = all.find(
    (t) => norm(t.state) === norm(state) && norm(t.county) === norm(county) && t.county
  );
  if (countyMatch) return countyMatch;

  const stateMatch = all.find((t) => norm(t.state) === norm(state) && !t.county);
  if (stateMatch) return stateMatch;

  const fallback = all.find((t) => !t.state && !t.county);
  return fallback || all[0];
}

export async function saveTemplate(template: Omit<DocumentTemplate, 'id'> & { id?: string }): Promise<DocumentTemplate> {
  const id = template.id ?? generateId('tmpl');
  const full: DocumentTemplate = { ...template, id };
  await setDoc(doc(templatesCollection(), id), full);
  return full;
}

export async function deleteTemplate(id: string): Promise<void> {
  await deleteDoc(doc(templatesCollection(), id));
}

// Called once after documentCategories.ensureSeeded() — creates one default
// (state/county-agnostic) template per default category, matched by label so
// it lines up with whatever key that category actually got.
export async function ensureDefaultTemplatesSeeded(categories: DocumentCategory[]): Promise<void> {
  for (const cat of categories) {
    const defaults = DEFAULT_FIELDS_BY_LABEL[cat.label];
    if (!defaults) continue; // custom/user-added categories don't get an auto template

    const existing = await getTemplatesForCategory(cat.key);
    if (existing.some((t) => !t.state && !t.county)) continue; // default already exists

    await saveTemplate({
      categoryKey: cat.key,
      applyTarget: defaults.applyTarget,
      fields: defaults.fields,
    });
  }
}
