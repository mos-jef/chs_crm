import React from 'react';
import { PropertyFile, Note, generateId } from '../../db/schema';
import EditableRecordList, { FieldConfig } from './EditableRecordList';

const FIELDS: FieldConfig[] = [
  { key: 'subject', label: 'Subject', type: 'text', width: '220px' },
  { key: 'content', label: 'Note', type: 'textarea' },
];

export default function NotesTab({
  property,
  onChange,
}: {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}) {
  return (
    <EditableRecordList<Note>
      records={property.notes}
      fields={FIELDS}
      onChange={(notes) =>
        onChange({
          notes: notes.map((n) => ({ ...n, updatedAt: Date.now() })),
        })
      }
      newRecord={() => ({
        id: generateId('note'),
        subject: '',
        content: '',
        createdAt: Date.now(),
      })}
      emptyLabel="No notes yet."
      addLabel="+ Add Note"
    />
  );
}
