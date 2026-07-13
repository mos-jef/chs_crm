// Turns a raw extracted-fields object (whatever the AI returned, matching a
// template's field keys) into an actual property update — either merging
// onto an existing file or creating a new one (Taxes/overview only), or
// appending a record to the right array (Deeds/Mortgages/Judgments/
// Easements). Kept separate from DocumentReader.tsx so the matching/mapping
// logic is testable and reusable between the automatic batch path and the
// manual "apply to this property" path for no-match rows.

import {
  PropertyFile,
  Deed,
  Mortgage,
  Judgment,
  Easement,
  generateId,
  newPropertyFile,
} from './schema';
import { ApplyTarget } from './documentTemplates';

function normalize(s?: string): string {
  return (s || '').replace(/[\s\-.,#]/g, '').toLowerCase();
}

export function matchPropertyByTaxAccountNumber(
  properties: PropertyFile[],
  extracted: Record<string, any>
): PropertyFile | undefined {
  const key = normalize(extracted.taxAccountNumber);
  if (!key) return undefined;
  return properties.find((p) => normalize(p.taxAccountNumber) === key);
}

export function matchPropertyByAddress(
  properties: PropertyFile[],
  extracted: Record<string, any>
): PropertyFile | undefined {
  const addr = normalize(extracted.address);
  if (!addr || addr.length < 5) return undefined;
  return properties.find((p) => {
    const pAddr = normalize(p.address);
    return pAddr && (pAddr === addr || pAddr.includes(addr) || addr.includes(pAddr));
  });
}

function buildOverviewPatch(
  existing: PropertyFile | undefined,
  extracted: Record<string, any>
): Partial<PropertyFile> {
  const patch: Partial<PropertyFile> = {};
  if (extracted.address) patch.address = extracted.address;
  if (extracted.county) patch.county = extracted.county;
  if (extracted.state) patch.state = extracted.state;
  if (extracted.zipCode) patch.zipCode = extracted.zipCode;
  if (extracted.taxAccountNumber) patch.taxAccountNumber = extracted.taxAccountNumber;
  if (extracted.mapNo) patch.mapNo = extracted.mapNo;
  if (extracted.taxesPaidUnpaid) patch.taxesPaidUnpaid = extracted.taxesPaidUnpaid;
  if (extracted.taxesOwing) {
    const n = parseFloat(String(extracted.taxesOwing).replace(/[^0-9.]/g, ''));
    if (!isNaN(n)) patch.taxesOwing = n;
  }

  const contacts = existing ? [...existing.contacts] : [];
  if (extracted.owner) {
    const idx = contacts.findIndex((c) => c.role === 'Owner');
    if (idx >= 0) contacts[idx] = { ...contacts[idx], name: extracted.owner };
    else contacts.push({ id: generateId('contact'), name: extracted.owner, role: 'Owner' });
  }
  patch.contacts = contacts;

  return patch;
}

function appendArrayRecord(
  existing: PropertyFile,
  target: ApplyTarget,
  extracted: Record<string, any>
): Partial<PropertyFile> {
  const num = (v: any) => {
    if (v == null || v === '') return undefined;
    const n = parseFloat(String(v).replace(/[^0-9.]/g, ''));
    return isNaN(n) ? undefined : n;
  };

  switch (target) {
    case 'deeds': {
      const rec: Deed = {
        id: generateId('deed'),
        docTitle: extracted.docTitle || '',
        grantor: extracted.grantor || '',
        grantee: extracted.grantee || '',
        instrumentDate: extracted.instrumentDate || undefined,
        recordingDate: extracted.recordingDate || undefined,
        book: extracted.book || undefined,
        page: extracted.page || undefined,
        instrumentNo: extracted.instrumentNo || undefined,
      };
      return { deeds: [...existing.deeds, rec] };
    }
    case 'mortgages': {
      const rec: Mortgage = {
        id: generateId('mortgage'),
        mortgageType: (['Mortgage', 'Deed of Trust'].includes(extracted.mortgageType) ? extracted.mortgageType : 'Other'),
        borrower: extracted.borrower || '',
        beneficiary: extracted.beneficiary || '',
        amount: num(extracted.amount),
        recordingDate: extracted.recordingDate || undefined,
        status: extracted.status || '',
      };
      return { mortgages: [...existing.mortgages, rec] };
    }
    case 'judgments': {
      const rec: Judgment = {
        id: generateId('judgment'),
        recordType: extracted.recordType === 'Lien' ? 'Lien' : extracted.recordType === 'Other' ? 'Other' : 'Judgment',
        caseNumber: extracted.caseNumber || undefined,
        debtor: extracted.debtor || undefined,
        grantee: extracted.grantee || undefined,
        county: extracted.county || existing.county || '',
        state: extracted.state || existing.state || '',
        amount: num(extracted.amount),
        status: (extracted.status as Judgment['status']) || 'Open',
        filedDate: extracted.filedDate || undefined,
      };
      return { judgments: [...existing.judgments, rec] };
    }
    case 'easements': {
      const rec: Easement = {
        id: generateId('easement'),
        easementType: extracted.easementType || '',
        grantor: extracted.grantor || '',
        grantee: extracted.grantee || '',
        recordingDate: extracted.recordingDate || undefined,
        status: (extracted.status as Easement['status']) || 'Unknown',
      };
      return { easements: [...existing.easements, rec] };
    }
    default:
      return {};
  }
}

// Returns the full property record ready to save. For 'overview' with no
// existing match, this creates a brand new file — fileNumber defaults to the
// tax account number, per the "new files created from the tax account
// number" requirement. For array targets, an existing property is required;
// this throws if none was given (the caller is expected to have already
// checked for a match and routed to the manual "pick a property" flow if not).
export function applyExtractionToProperty(
  existing: PropertyFile | undefined,
  target: ApplyTarget,
  extracted: Record<string, any>,
  fallbackState: string,
  fallbackCounty: string
): { property: PropertyFile; isNew: boolean } {
  if (target === 'overview') {
    const patch = buildOverviewPatch(existing, extracted);
    if (existing) return { property: { ...existing, ...patch }, isNew: false };
    return {
      property: newPropertyFile({
        fileNumber: extracted.taxAccountNumber || extracted.address || generateId('file'),
        address: extracted.address || '',
        city: '',
        state: extracted.state || fallbackState || '',
        county: extracted.county || fallbackCounty || '',
        zipCode: extracted.zipCode || '',
        ...patch,
      }),
      isNew: true,
    };
  }

  if (!existing) {
    throw new Error('No matching property — pick one manually before applying.');
  }
  const patch = appendArrayRecord(existing, target, extracted);
  return { property: { ...existing, ...patch }, isNew: false };
}
