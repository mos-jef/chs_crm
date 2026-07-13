import React from 'react';
import { PropertyFile, Judgment, generateId } from '../../db/schema';
import EditableRecordList, { FieldConfig } from './EditableRecordList';

// Covers judgments, liens, and HOA liens in one list per your call —
// recordType is what distinguishes them without needing separate tabs.
const FIELDS: FieldConfig[] = [
  { key: 'recordType', label: 'Type', type: 'select', options: ['Judgment', 'Lien', 'Other'], width: '110px' },
  { key: 'caseNumber', label: 'Case/Reference No.', type: 'text', width: '160px' },
  { key: 'debtor', label: 'Debtor', type: 'text' },
  { key: 'grantee', label: 'Grantee/Creditor', type: 'text' },
  { key: 'county', label: 'County', type: 'text', width: '120px' },
  { key: 'state', label: 'State', type: 'text', width: '70px' },
  { key: 'amount', label: 'Amount', type: 'number', width: '110px' },
  { key: 'status', label: 'Status', type: 'select', options: ['Open', 'Closed', 'Pending', 'Paid', 'Unpaid', 'Satisfied', 'Released', 'Unknown'], width: '110px' },
  { key: 'filedDate', label: 'Filed', type: 'date', width: '130px' },
  { key: 'notes', label: 'Notes', type: 'textarea' },
];

export default function JudgmentsTab({
  property,
  onChange,
}: {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}) {
  return (
    <EditableRecordList<Judgment>
      records={property.judgments}
      fields={FIELDS}
      onChange={(judgments) => onChange({ judgments })}
      newRecord={() => ({
        id: generateId('judgment'),
        recordType: 'Judgment',
        county: property.county ?? '',
        state: property.state ?? '',
        status: 'Open',
      })}
      emptyLabel="No judgments or liens yet."
      addLabel="+ Add Judgment / Lien"
    />
  );
}
