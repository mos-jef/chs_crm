import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { PropertyFile } from '../../db/schema';
import { deleteProperty, getProperty, upsertProperty } from '../../db/properties';
import OverviewTab from './OverviewTab';
import ContactsTab from './ContactsTab';
import DeedsTab from './DeedsTab';
import MortgagesTab from './MortgagesTab';
import JudgmentsTab from './JudgmentsTab';
import EasementsTab from './EasementsTab';
import VestingTab from './VestingTab';
import NotesTab from './NotesTab';
import AuctionsTab from './AuctionsTab';
import DocumentsTab from './DocumentsTab';

type TabKey =
  | 'overview'
  | 'contacts'
  | 'deeds'
  | 'mortgages'
  | 'judgments'
  | 'easements'
  | 'vesting'
  | 'notes'
  | 'auctions'
  | 'documents';

const TABS: { key: TabKey; label: string }[] = [
  { key: 'overview', label: 'Overview' },
  { key: 'contacts', label: 'Contacts' },
  { key: 'deeds', label: 'Deeds' },
  { key: 'mortgages', label: 'Mortgages' },
  { key: 'judgments', label: 'Judgments' },
  { key: 'easements', label: 'Easements' },
  { key: 'vesting', label: 'Vesting' },
  { key: 'notes', label: 'Notes' },
  { key: 'auctions', label: 'Auctions' },
  { key: 'documents', label: 'Documents' },
];

export default function PropertyDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [property, setProperty] = useState<PropertyFile | null>(null);
  const [loading, setLoading] = useState(true);
  const [dirty, setDirty] = useState(false);
  const [saving, setSaving] = useState(false);
  const [tab, setTab] = useState<TabKey>('overview');

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    getProperty(id).then((p) => {
      setProperty(p);
      setLoading(false);
    });
  }, [id]);

  function handleChange(patch: Partial<PropertyFile>) {
    setProperty((prev) => (prev ? { ...prev, ...patch } : prev));
    setDirty(true);
  }

  async function handleSave() {
    if (!property) return;
    setSaving(true);
    await upsertProperty(property);
    setDirty(false);
    setSaving(false);
  }

  async function handleDelete() {
    if (!property) return;
    if (!window.confirm(`Delete file ${property.fileNumber}? This can't be undone.`)) return;
    await deleteProperty(property.id);
    navigate('/properties');
  }

  if (loading) {
    return <div style={{ padding: 24, color: 'var(--text-muted)' }}>Loading...</div>;
  }

  if (!property) {
    return (
      <div style={{ padding: 24, color: 'var(--text-muted)' }}>
        File not found.{' '}
        <button onClick={() => navigate('/properties')} style={{ color: 'var(--text-secondary)' }}>
          Back to properties
        </button>
      </div>
    );
  }

  return (
    <div style={{ padding: 24 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
        <div>
          <h2 style={{ margin: 0, color: 'var(--text-primary)' }}>
            {property.fileNumber || 'Untitled File'}
          </h2>
          <div style={{ color: 'var(--text-muted)', fontSize: 13 }}>{property.address}</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button
            className="btn-primary"
            onClick={handleSave}
            disabled={!dirty || saving}
          >
            {saving ? 'Saving...' : dirty ? 'Save Changes' : 'Saved'}
          </button>
          <button
            onClick={handleDelete}
            style={{
              background: 'none',
              border: '1px solid var(--accent-red)',
              color: 'var(--accent-red)',
              borderRadius: 8,
              padding: '10px 14px',
              fontSize: 13,
            }}
          >
            Delete File
          </button>
        </div>
      </div>

      <div
        style={{
          display: 'flex',
          gap: 4,
          borderBottom: '1px solid var(--border)',
          margin: '20px 0',
          flexWrap: 'wrap',
        }}
      >
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            style={{
              background: 'none',
              border: 'none',
              borderBottom: tab === t.key ? '2px solid var(--accent-primary)' : '2px solid transparent',
              color: tab === t.key ? 'var(--text-primary)' : 'var(--text-muted)',
              padding: '10px 14px',
              fontSize: 13,
              fontWeight: tab === t.key ? 600 : 400,
            }}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'overview' && <OverviewTab property={property} onChange={handleChange} />}
      {tab === 'contacts' && <ContactsTab property={property} onChange={handleChange} />}
      {tab === 'deeds' && <DeedsTab property={property} onChange={handleChange} />}
      {tab === 'mortgages' && <MortgagesTab property={property} onChange={handleChange} />}
      {tab === 'judgments' && <JudgmentsTab property={property} onChange={handleChange} />}
      {tab === 'easements' && <EasementsTab property={property} onChange={handleChange} />}
      {tab === 'vesting' && <VestingTab property={property} onChange={handleChange} />}
      {tab === 'notes' && <NotesTab property={property} onChange={handleChange} />}
      {tab === 'auctions' && <AuctionsTab property={property} onChange={handleChange} />}
      {tab === 'documents' && <DocumentsTab property={property} onChange={handleChange} />}
    </div>
  );
}
