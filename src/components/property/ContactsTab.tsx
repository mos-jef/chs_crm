import React from 'react';
import { PropertyFile, Contact, generateId } from '../../db/schema';
import EditableRecordList, { FieldConfig } from './EditableRecordList';

const FIELDS: FieldConfig[] = [
  { key: 'name', label: 'Name', type: 'text' },
  { key: 'role', label: 'Role', type: 'text', width: '160px' },
  { key: 'phone', label: 'Phone', type: 'text', width: '160px' },
  { key: 'email', label: 'Email', type: 'text' },
];

export default function ContactsTab({
  property,
  onChange,
}: {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}) {
  return (
    <EditableRecordList<Contact>
      records={property.contacts}
      fields={FIELDS}
      onChange={(contacts) => onChange({ contacts })}
      newRecord={() => ({ id: generateId('contact'), name: '', role: '' })}
      emptyLabel="No contacts yet."
      addLabel="+ Add Contact"
    />
  );
}
