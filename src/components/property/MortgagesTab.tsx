import React from 'react';
import { PropertyFile, Mortgage, generateId } from '../../db/schema';
import EditableRecordList, { FieldConfig } from './EditableRecordList';

const FIELDS: FieldConfig[] = [
  { key: 'mortgageType', label: 'Type', type: 'select', options: ['Mortgage', 'Deed of Trust', 'Other'], width: '140px' },
  { key: 'borrower', label: 'Borrower', type: 'text' },
  { key: 'beneficiary', label: 'Beneficiary (Lender)', type: 'text' },
  { key: 'amount', label: 'Amount', type: 'number', width: '120px' },
  { key: 'recordingDate', label: 'Recorded', type: 'date', width: '140px' },
  { key: 'status', label: 'Status', type: 'text', width: '120px' },
  { key: 'notes', label: 'Notes', type: 'textarea' },
];

export default function MortgagesTab({
  property,
  onChange,
}: {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}) {
  return (
    <EditableRecordList<Mortgage>
      records={property.mortgages}
      fields={FIELDS}
      onChange={(mortgages) => onChange({ mortgages })}
      newRecord={() => ({
        id: generateId('mortgage'),
        mortgageType: 'Mortgage',
        borrower: '',
        beneficiary: '',
        status: '',
      })}
      emptyLabel="No mortgages/deeds of trust yet."
      addLabel="+ Add Mortgage"
    />
  );
}
