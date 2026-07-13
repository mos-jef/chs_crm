import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PropertyFile, newPropertyFile } from '../db/schema';
import { loadProperties, searchProperties, upsertProperty } from '../db/properties';

export default function PropertyList() {
  const [properties, setProperties] = useState<PropertyFile[]>([]);
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    loadProperties().then((p) => {
      setProperties(p);
      setLoading(false);
    });
  }, []);

  const filtered = searchProperties(properties, query);

  async function handleNewFile() {
    const fileNumber = prompt('File number:');
    if (!fileNumber) return;
    const property = newPropertyFile({ fileNumber });
    await upsertProperty(property);
    setProperties((prev) => [...prev, property]);
    navigate(`/properties/${property.id}`);
  }

  return (
    <div style={{ padding: 24 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <h2 style={{ margin: 0, color: 'var(--text-primary)' }}>Properties</h2>
        <button className="btn-primary" onClick={handleNewFile}>
          + New File
        </button>
      </div>

      <input
        placeholder="Search by name, address, file number, or tax account number..."
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        style={{ width: '100%', maxWidth: 480, marginBottom: 16 }}
      />

      {loading ? (
        <div style={{ color: 'var(--text-muted)' }}>Loading...</div>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ textAlign: 'left', color: 'var(--text-muted)', fontSize: 12 }}>
              <th style={{ padding: '8px 12px' }}>File #</th>
              <th style={{ padding: '8px 12px' }}>Address</th>
              <th style={{ padding: '8px 12px' }}>State</th>
              <th style={{ padding: '8px 12px' }}>County</th>
              <th style={{ padding: '8px 12px' }}>Tax Account No.</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((p) => (
              <tr
                key={p.id}
                onClick={() => navigate(`/properties/${p.id}`)}
                style={{
                  cursor: 'pointer',
                  borderTop: '1px solid var(--border)',
                  color: 'var(--text-primary)',
                }}
              >
                <td style={{ padding: '10px 12px' }}>{p.fileNumber}</td>
                <td style={{ padding: '10px 12px' }}>{p.address}</td>
                <td style={{ padding: '10px 12px' }}>{p.state}</td>
                <td style={{ padding: '10px 12px' }}>{p.county}</td>
                <td style={{ padding: '10px 12px' }}>{p.taxAccountNumber}</td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr>
                <td colSpan={5} style={{ padding: 24, textAlign: 'center', color: 'var(--text-muted)' }}>
                  No files yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
