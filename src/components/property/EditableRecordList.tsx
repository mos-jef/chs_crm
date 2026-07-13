import React from 'react';

// Shared editor for the array-shaped tabs (Deeds, Mortgages, Judgments,
// Easements, Contacts, Notes, Auctions). One generic table instead of seven
// near-identical hand-built ones — each tab just supplies its column config
// and a factory for a blank record. Keeps the tabs themselves short and
// keeps the add/edit/delete behavior consistent across all of them.

export interface FieldConfig {
  key: string;
  label: string;
  type: 'text' | 'number' | 'date' | 'select' | 'textarea' | 'checkbox';
  options?: string[];
  width?: string;
}

interface Props<T extends { id: string }> {
  records: T[];
  fields: FieldConfig[];
  onChange: (records: T[]) => void;
  newRecord: () => T;
  emptyLabel?: string;
  addLabel?: string;
}

export default function EditableRecordList<T extends { id: string }>({
  records,
  fields,
  onChange,
  newRecord,
  emptyLabel = 'None yet.',
  addLabel = '+ Add',
}: Props<T>) {
  function updateField(id: string, key: string, value: any) {
    onChange(records.map((r) => (r.id === id ? { ...r, [key]: value } : r)));
  }

  function addRecord() {
    onChange([...records, newRecord()]);
  }

  function deleteRecord(id: string) {
    if (!window.confirm('Remove this entry?')) return;
    onChange(records.filter((r) => r.id !== id));
  }

  return (
    <div>
      <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: 12 }}>
        <thead>
          <tr style={{ textAlign: 'left', color: 'var(--text-muted)', fontSize: 12 }}>
            {fields.map((f) => (
              <th key={f.key} style={{ padding: '6px 8px', width: f.width }}>
                {f.label}
              </th>
            ))}
            <th style={{ width: 32 }} />
          </tr>
        </thead>
        <tbody>
          {records.map((r) => (
            <tr key={r.id} style={{ borderTop: '1px solid var(--border)' }}>
              {fields.map((f) => {
                const value = (r as any)[f.key] ?? '';
                return (
                  <td key={f.key} style={{ padding: '6px 8px' }}>
                    {f.type === 'select' ? (
                      <select
                        value={value}
                        onChange={(e) => updateField(r.id, f.key, e.target.value)}
                        style={{ width: '100%' }}
                      >
                        <option value="" />
                        {f.options?.map((o) => (
                          <option key={o} value={o}>
                            {o}
                          </option>
                        ))}
                      </select>
                    ) : f.type === 'textarea' ? (
                      <textarea
                        value={value}
                        onChange={(e) => updateField(r.id, f.key, e.target.value)}
                        rows={2}
                        style={{ width: '100%', resize: 'vertical' }}
                      />
                    ) : f.type === 'checkbox' ? (
                      <input
                        type="checkbox"
                        checked={!!value}
                        onChange={(e) => updateField(r.id, f.key, e.target.checked)}
                      />
                    ) : (
                      <input
                        type={f.type === 'number' ? 'number' : f.type === 'date' ? 'date' : 'text'}
                        value={value}
                        onChange={(e) =>
                          updateField(
                            r.id,
                            f.key,
                            f.type === 'number'
                              ? e.target.value === ''
                                ? undefined
                                : parseFloat(e.target.value)
                              : e.target.value
                          )
                        }
                        style={{ width: '100%' }}
                      />
                    )}
                  </td>
                );
              })}
              <td style={{ padding: '6px 8px' }}>
                <button
                  onClick={() => deleteRecord(r.id)}
                  title="Remove"
                  style={{
                    background: 'none',
                    border: 'none',
                    color: 'var(--accent-red)',
                    fontSize: 16,
                    cursor: 'pointer',
                  }}
                >
                  ×
                </button>
              </td>
            </tr>
          ))}
          {records.length === 0 && (
            <tr>
              <td
                colSpan={fields.length + 1}
                style={{ padding: 16, textAlign: 'center', color: 'var(--text-muted)' }}
              >
                {emptyLabel}
              </td>
            </tr>
          )}
        </tbody>
      </table>
      <button
        onClick={addRecord}
        style={{
          background: 'none',
          border: '1px dashed var(--border)',
          color: 'var(--text-secondary)',
          borderRadius: 6,
          padding: '8px 14px',
          fontSize: 13,
        }}
      >
        {addLabel}
      </button>
    </div>
  );
}
