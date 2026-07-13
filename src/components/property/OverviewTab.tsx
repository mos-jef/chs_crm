import React from 'react';
import { PropertyFile, estimatedMargin } from '../../db/schema';

interface Props {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}

const US_STATES = ['OR', 'WA', 'ID']; // the three you're mostly working, plus you can type any 2-letter code

function field(label: string, input: React.ReactNode) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <label style={{ fontSize: 12, color: 'var(--text-muted)' }}>{label}</label>
      {input}
    </div>
  );
}

export default function OverviewTab({ property, onChange }: Props) {
  const margin = estimatedMargin(property);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20, maxWidth: 640 }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
        {field(
          'File Number',
          <input
            value={property.fileNumber}
            onChange={(e) => onChange({ fileNumber: e.target.value })}
          />
        )}
        {field(
          'Address',
          <input
            value={property.address}
            onChange={(e) => onChange({ address: e.target.value })}
          />
        )}
        {field(
          'City',
          <input value={property.city} onChange={(e) => onChange({ city: e.target.value })} />
        )}
        {field(
          'State',
          <input
            list="state-options"
            value={property.state}
            onChange={(e) => onChange({ state: e.target.value.toUpperCase() })}
          />
        )}
        <datalist id="state-options">
          {US_STATES.map((s) => (
            <option key={s} value={s} />
          ))}
        </datalist>
        {field(
          'Zip Code',
          <input value={property.zipCode} onChange={(e) => onChange({ zipCode: e.target.value })} />
        )}
        {field(
          'County',
          <input value={property.county ?? ''} onChange={(e) => onChange({ county: e.target.value })} />
        )}
        {field(
          'Tax Account No.',
          <input
            value={property.taxAccountNumber ?? ''}
            onChange={(e) => onChange({ taxAccountNumber: e.target.value })}
          />
        )}
        {field(
          'Map No.',
          <input value={property.mapNo ?? ''} onChange={(e) => onChange({ mapNo: e.target.value })} />
        )}
      </div>

      <div>
        <h4 style={{ color: 'var(--text-primary)', marginBottom: 10 }}>Financials</h4>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
          {field(
            'Loan Amount',
            <input
              type="number"
              value={property.loanAmount ?? ''}
              onChange={(e) => onChange({ loanAmount: e.target.value ? parseFloat(e.target.value) : undefined })}
            />
          )}
          {field(
            'Amount Owed',
            <input
              type="number"
              value={property.amountOwed ?? ''}
              onChange={(e) => onChange({ amountOwed: e.target.value ? parseFloat(e.target.value) : undefined })}
            />
          )}
          {field(
            'Arrears',
            <input
              type="number"
              value={property.arrears ?? ''}
              onChange={(e) => onChange({ arrears: e.target.value ? parseFloat(e.target.value) : undefined })}
            />
          )}
          {field(
            'Estimated Sale Value',
            <input
              type="number"
              value={property.estimatedSaleValue ?? ''}
              onChange={(e) =>
                onChange({ estimatedSaleValue: e.target.value ? parseFloat(e.target.value) : undefined })
              }
            />
          )}
        </div>
        <div style={{ marginTop: 10, fontSize: 14, color: 'var(--text-secondary)' }}>
          Margin (est. value − amount owed):{' '}
          <strong style={{ color: 'var(--text-primary)' }}>
            {margin == null ? '—' : `$${margin.toLocaleString()}`}
          </strong>
        </div>
      </div>

      <div>
        <h4 style={{ color: 'var(--text-primary)', marginBottom: 10 }}>Taxes</h4>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
          {field(
            'Taxes Paid/Unpaid',
            <select
              value={property.taxesPaidUnpaid ?? ''}
              onChange={(e) => onChange({ taxesPaidUnpaid: e.target.value as any })}
            >
              <option value="" />
              <option value="Paid">Paid</option>
              <option value="Unpaid">Unpaid</option>
              <option value="Unknown">Unknown</option>
            </select>
          )}
          {field(
            'Taxes Owing',
            <input
              type="number"
              value={property.taxesOwing ?? ''}
              onChange={(e) => onChange({ taxesOwing: e.target.value ? parseFloat(e.target.value) : undefined })}
            />
          )}
        </div>
      </div>

      <div>
        {field(
          'Zillow URL',
          <input
            value={property.zillowUrl ?? ''}
            onChange={(e) => onChange({ zillowUrl: e.target.value })}
          />
        )}
      </div>
    </div>
  );
}
