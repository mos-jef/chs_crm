import React from 'react';
import { PropertyFile, Owner, VestingInfo, generateId } from '../../db/schema';
import EditableRecordList, { FieldConfig } from './EditableRecordList';

const OWNER_FIELDS: FieldConfig[] = [
  { key: 'name', label: 'Owner Name', type: 'text' },
  { key: 'percentage', label: 'Ownership %', type: 'number', width: '140px' },
];

export default function VestingTab({
  property,
  onChange,
}: {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}) {
  const vesting: VestingInfo = property.vesting ?? { owners: [], vestingType: '' };

  function updateOwners(owners: Owner[]) {
    onChange({ vesting: { ...vesting, owners } });
  }

  function updateVestingType(vestingType: string) {
    onChange({ vesting: { ...vesting, vestingType } });
  }

  return (
    <div style={{ maxWidth: 640 }}>
      <div style={{ marginBottom: 20 }}>
        <label style={{ fontSize: 12, color: 'var(--text-muted)', display: 'block', marginBottom: 4 }}>
          Vesting Type
        </label>
        <input
          value={vesting.vestingType}
          onChange={(e) => updateVestingType(e.target.value)}
          placeholder="e.g. Joint Tenants, Tenants in Common, Sole Ownership"
          style={{ width: '100%' }}
        />
      </div>

      <EditableRecordList<Owner>
        records={vesting.owners}
        fields={OWNER_FIELDS}
        onChange={updateOwners}
        newRecord={() => ({ id: generateId('owner'), name: '', percentage: 0 })}
        emptyLabel="No owners listed yet."
        addLabel="+ Add Owner"
      />
    </div>
  );
}
