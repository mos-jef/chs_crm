import React from 'react';
import { PropertyFile, Easement, generateId } from '../../db/schema';
import EditableRecordList, { FieldConfig } from './EditableRecordList';

const FIELDS: FieldConfig[] = [
  { key: 'easementType', label: 'Type', type: 'text', width: '160px' },
  { key: 'grantor', label: 'Grantor', type: 'text' },
  { key: 'grantee', label: 'Grantee', type: 'text' },
  { key: 'recordingDate', label: 'Recorded', type: 'date', width: '140px' },
  { key: 'status', label: 'Status', type: 'select', options: ['Active', 'Released', 'Expired', 'Unknown'], width: '120px' },
  { key: 'notes', label: 'Notes', type: 'textarea' },
];

export default function EasementsTab({
  property,
  onChange,
}: {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}) {
  return (
    <EditableRecordList<Easement>
      records={property.easements}
      fields={FIELDS}
      onChange={(easements) => onChange({ easements })}
      newRecord={() => ({
        id: generateId('easement'),
        easementType: '',
        grantor: '',
        grantee: '',
        status: 'Unknown',
      })}
      emptyLabel="No easements yet."
      addLabel="+ Add Easement"
    />
  );
}
