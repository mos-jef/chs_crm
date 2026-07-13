// Data model for CHS-CRM (Electron/React/TS rebuild).
//
// This carries forward the Flutter chs-crm schema (richer than title-crm's
// Parcel model — has loan/arrears/auction/trustee fields the Flutter version
// needed for foreclosure work) almost field-for-field, with two changes:
//
//   1. DocumentRef now points at a Google Drive file (driveFileId) plus a
//      documentCategoryKey, instead of a Firebase Storage url. The category
//      key is what the Document Reader tab and the Drive folder-resolution
//      logic both key off of — see documentCategories.ts.
//
//   2. Nothing here hardcodes category names ("Deeds", "Taxes", etc.) —
//      those live in Firestore via documentCategories.ts so you can add new
//      ones (a new subfolder type) without touching this file or redeploying.

export function generateId(prefix: string): string {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

export interface Contact {
  id: string;
  name: string;
  phone?: string;
  email?: string;
  role: string;
}

// A reference to a file that actually lives in Google Drive. driveFileId is
// Google's permanent identifier for the file — it stays valid even if the
// file gets renamed or moved to a different folder in Drive, which is the
// whole point of moving off title-crm's local folderPath approach.
export interface DocumentRef {
  id: string;
  driveFileId: string;
  fileName: string;
  documentCategoryKey: string; // references DocumentCategory.key, not a hardcoded enum
  uploadDate: number; // epoch millis
  uploadedByUid?: string;
}

export interface Judgment {
  id: string;
  // Judgments tab also covers liens, HOA liens, etc. per your call — recordType
  // distinguishes them without needing a separate tab/collection.
  recordType: 'Judgment' | 'Lien' | 'Other';
  caseNumber?: string;
  plaintiffs?: string;
  defendants?: string;
  debtor?: string;
  grantee?: string;
  county: string;
  state: string;
  amount?: number;
  status: 'Open' | 'Closed' | 'Pending' | 'Paid' | 'Unpaid' | 'Satisfied' | 'Released' | 'Unknown';
  filedDate?: string;
  closedDate?: string;
  notes?: string;
}

export interface Note {
  id: string;
  subject: string;
  content: string;
  createdAt: number;
  updatedAt?: number;
}

export interface Trustee {
  id: string;
  name: string;
  institution: string;
  phoneNumber?: string;
  createdAt: number;
}

export interface Auction {
  id: string;
  auctionDate: number;
  place: string;
  timeHour: number;
  timeMinute: number;
  openingBid?: number;
  auctionCompleted: boolean;
  salesAmount?: number;
}

export interface Owner {
  id: string;
  name: string;
  percentage: number;
}

export interface VestingInfo {
  owners: Owner[];
  vestingType: string;
}

// Deeds tab covers vesting/chain-of-title documents (filed under the "Deeds"
// document category) — this is the structured chain-of-title data, separate
// from the PDFs themselves.
export interface Deed {
  id: string;
  docTitle: string; // "Warranty Deed", "Sheriff's Deed", "Cert. of Transfer", etc.
  grantor: string;
  grantee: string;
  instrumentDate?: string;
  recordingDate?: string;
  book?: string;
  page?: string;
  instrumentNo?: string;
  notes?: string;
}

export interface Mortgage {
  id: string;
  mortgageType: 'Mortgage' | 'Deed of Trust' | 'Other';
  borrower: string;
  beneficiary: string;
  amount?: number;
  recordingDate?: string;
  status: string;
  notes?: string;
}

export interface Easement {
  id: string;
  easementType: string;
  grantor: string;
  grantee: string;
  recordingDate?: string;
  status: 'Active' | 'Released' | 'Expired' | 'Unknown';
  notes?: string;
}

export interface PropertyFile {
  id: string;
  fileNumber: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  county?: string;
  taxAccountNumber?: string;
  mapNo?: string;

  loanAmount?: number;
  amountOwed?: number;
  arrears?: number;
  estimatedSaleValue?: number;
  taxesPaidUnpaid?: 'Paid' | 'Unpaid' | 'Unknown';
  taxesOwing?: number;

  zillowUrl?: string;

  contacts: Contact[];
  documents: DocumentRef[];
  judgments: Judgment[];
  notes: Note[];
  trustees: Trustee[];
  auctions: Auction[];
  deeds: Deed[];
  mortgages: Mortgage[];
  easements: Easement[];
  vesting?: VestingInfo;

  createdAt: number;
  updatedAt: number;
}

// Margin, matching the definition you gave for the live sheet:
// estimated value minus what's owed.
export function estimatedMargin(p: PropertyFile): number | null {
  if (p.estimatedSaleValue == null || p.amountOwed == null) return null;
  return p.estimatedSaleValue - p.amountOwed;
}

export function newPropertyFile(partial: Partial<PropertyFile>): PropertyFile {
  const now = Date.now();
  return {
    id: partial.id ?? generateId('property'),
    fileNumber: partial.fileNumber ?? '',
    address: partial.address ?? '',
    city: partial.city ?? '',
    state: partial.state ?? '',
    zipCode: partial.zipCode ?? '',
    county: partial.county ?? '',
    taxAccountNumber: partial.taxAccountNumber ?? '',
    mapNo: partial.mapNo ?? '',
    contacts: partial.contacts ?? [],
    documents: partial.documents ?? [],
    judgments: partial.judgments ?? [],
    notes: partial.notes ?? [],
    trustees: partial.trustees ?? [],
    auctions: partial.auctions ?? [],
    deeds: partial.deeds ?? [],
    mortgages: partial.mortgages ?? [],
    easements: partial.easements ?? [],
    vesting: partial.vesting,
    createdAt: partial.createdAt ?? now,
    updatedAt: partial.updatedAt ?? now,
    ...partial,
  };
}

// ── Users ──────────────────────────────────────────────────────────────────

export interface UserProfile {
  uid: string;
  email: string;
  displayName: string;
  avatarDriveFileId?: string; // profile image, stored in the shared Drive, not Storage
  role: 'admin' | 'member';
  approved: boolean; // pending-approval gate, ported from the Flutter version
  createdAt: number;
}
