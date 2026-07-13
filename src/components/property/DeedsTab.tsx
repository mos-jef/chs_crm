import React from 'react';
import { PropertyFile, Deed, generateId } from '../../db/schema';
import EditableRecordList, { FieldConfig } from './EditableRecordList';

// Covers vesting/chain-of-title documents per your call — the structured
// vesting data (owners/percentages) lives in the separate Vesting tab; this
// is the record of the actual recorded instruments.
const FIELDS: FieldConfig[] = [
  { key: 'docTitle', label: 'Document Title', type: 'text' },
  { key: 'grantor', label: 'Grantor', type: 'text' },
  { key: 'grantee', label: 'Grantee', type: 'text' },
  { key: 'instrumentDate', label: 'Dated', type: 'date', width: '140px' },
  { key: 'recordingDate', label: 'Recorded', type: 'date', width: '140px' },
  { key: 'book', label: 'Book', type: 'text', width: '80px' },
  { key: 'page', label: 'Page', type: 'text', width: '80px' },
  { key: 'instrumentNo', label: 'Instrument No.', type: 'text' },
  { key: 'notes', label: 'Notes', type: 'textarea' },
];

export default function DeedsTab({
  property,
  onChange,
}: {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}) {
  return (
    <EditableRecordList<Deed>
      records={property.deeds}
      fields={FIELDS}
      onChange={(deeds) => onChange({ deeds })}
      newRecord={() => ({ id: generateId('deed'), docTitle: '', grantor: '', grantee: '' })}
      emptyLabel="No deeds/chain-of-title entries yet."
      addLabel="+ Add Deed"
    />
  );
}
