import React, { useEffect, useState } from 'react';
import { applyTheme, getSavedTheme, Theme, THEMES } from '../theme';
import {
  DocumentCategory,
  addDocumentCategory,
  getDocumentCategories,
} from '../db/documentCategories';
import ExtractionTemplatesPanel from './ExtractionTemplatesPanel';
import { LiveSheetConfig, createLiveSheet, fullResync, getLiveSheetConfig } from '../db/liveSheet';
import { loadProperties } from '../db/properties';

type DriveStatus = 'unknown' | 'connecting' | 'connected' | 'error';

export default function Settings() {
  const [theme, setTheme] = useState<Theme>(getSavedTheme());
  const [categories, setCategories] = useState<DocumentCategory[]>([]);
  const [newLabel, setNewLabel] = useState('');
  const [driveStatus, setDriveStatus] = useState<DriveStatus>('unknown');
  const [driveError, setDriveError] = useState('');
  const [sheetConfig, setSheetConfig] = useState<LiveSheetConfig | null>(null);
  const [sheetBusy, setSheetBusy] = useState(false);
  const [sheetError, setSheetError] = useState('');
  const [resyncMessage, setResyncMessage] = useState('');

  useEffect(() => {
    getDocumentCategories().then(setCategories);
    getLiveSheetConfig().then(setSheetConfig);
  }, []);

  function handleThemeChange(t: Theme) {
    setTheme(t);
    applyTheme(t);
  }

  async function handleConnectDrive() {
    setDriveStatus('connecting');
    setDriveError('');
    const result = await window.electronAPI.driveAuthStart();
    if (result.success) {
      setDriveStatus('connected');
    } else {
      setDriveStatus('error');
      setDriveError(result.error || 'Could not connect to Google Drive.');
    }
  }

  async function handleDisconnectDrive() {
    await window.electronAPI.driveSignOut();
    setDriveStatus('unknown');
  }

  async function handleCreateSheet() {
    setSheetBusy(true);
    setSheetError('');
    try {
      const config = await createLiveSheet();
      setSheetConfig(config);
    } catch (err: any) {
      setSheetError(err.message || 'Could not create the sheet.');
    }
    setSheetBusy(false);
  }

  async function handleFullResync() {
    setSheetBusy(true);
    setSheetError('');
    setResyncMessage('');
    try {
      const properties = await loadProperties();
      await fullResync(properties);
      setResyncMessage(`Synced ${properties.length} files.`);
    } catch (err: any) {
      setSheetError(err.message || 'Resync failed.');
    }
    setSheetBusy(false);
  }

  async function handleAddCategory() {
    if (!newLabel.trim()) return;
    const cat = await addDocumentCategory({
      label: newLabel.trim(),
      folderName: newLabel.trim(),
      sortOrder: categories.length + 1,
    });
    setCategories((prev) => [...prev, cat]);
    setNewLabel('');
  }

  return (
    <div style={{ padding: 24, maxWidth: 720 }}>
      <h2 style={{ color: 'var(--text-primary)' }}>Settings</h2>

      <section style={{ marginBottom: 32 }}>
        <h3 style={{ color: 'var(--text-primary)', fontSize: 15 }}>Theme</h3>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          {THEMES.map((t) => (
            <button
              key={t.id}
              onClick={() => handleThemeChange(t.id)}
              style={{
                border: theme === t.id ? '2px solid var(--accent-primary)' : '1px solid var(--border)',
                borderRadius: 8,
                padding: 10,
                background: 'var(--bg-card)',
                color: 'var(--text-primary)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 6,
                width: 90,
              }}
            >
              <div style={{ display: 'flex', gap: 3 }}>
                {t.preview.map((c, i) => (
                  <div key={i} style={{ width: 14, height: 14, borderRadius: 3, background: c }} />
                ))}
              </div>
              <span style={{ fontSize: 12 }}>{t.label}</span>
            </button>
          ))}
        </div>
      </section>

      <section style={{ marginBottom: 32 }}>
        <h3 style={{ color: 'var(--text-primary)', fontSize: 15 }}>Google Drive</h3>
        <p style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 10 }}>
          Documents and profile photos are stored in the shared Google Drive,
          not on this computer. Sign in with your Workspace account once —
          it'll stay connected after that.
        </p>
        {driveStatus === 'connected' ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ color: 'var(--accent-green)', fontSize: 13 }}>● Connected</span>
            <button onClick={handleDisconnectDrive} style={{ background: 'none', border: '1px solid var(--border)', color: 'var(--text-secondary)', borderRadius: 6, padding: '6px 10px', fontSize: 12 }}>
              Disconnect
            </button>
          </div>
        ) : (
          <button className="btn-primary" onClick={handleConnectDrive} disabled={driveStatus === 'connecting'}>
            {driveStatus === 'connecting' ? 'Waiting for sign-in in your browser...' : 'Connect Google Drive'}
          </button>
        )}
        {driveError && <div style={{ color: 'var(--accent-red)', fontSize: 13, marginTop: 8 }}>{driveError}</div>}
      </section>

      <section>
        <h3 style={{ color: 'var(--text-primary)', fontSize: 15 }}>
          Document Categories
        </h3>
        <p style={{ color: 'var(--text-muted)', fontSize: 13 }}>
          These are the subfolders each file gets in Drive, and the options
          shown in the Document Reader's category dropdown. Adding one here
          makes it available everywhere immediately.
        </p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 12 }}>
          {categories.map((c) => (
            <div
              key={c.key}
              style={{
                padding: '8px 12px',
                background: 'var(--bg-card)',
                border: '1px solid var(--border)',
                borderRadius: 6,
                color: 'var(--text-primary)',
                fontSize: 14,
              }}
            >
              {c.label}
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <input
            placeholder="New category name (e.g. Surveys)"
            value={newLabel}
            onChange={(e) => setNewLabel(e.target.value)}
            style={{ flex: 1 }}
          />
          <button className="btn-primary" onClick={handleAddCategory}>
            Add
          </button>
        </div>
      </section>

      <div style={{ marginTop: 32, marginBottom: 32 }}>
        <ExtractionTemplatesPanel categories={categories} />
      </div>

      <section>
        <h3 style={{ color: 'var(--text-primary)', fontSize: 15 }}>Live Google Sheet</h3>
        <p style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 10 }}>
          A shared spreadsheet — File Number, Address, State, County, Owner, Amount Owed,
          Margin, Auction/Sale Date — that updates automatically whenever anyone saves a
          property in the app. One sheet for the whole team; create it once.
        </p>
        {sheetConfig ? (
          <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
            <a href={sheetConfig.url} target="_blank" rel="noreferrer" style={{ color: 'var(--accent-blue)', fontSize: 13 }}>
              Open the sheet
            </a>
            <button
              onClick={handleFullResync}
              disabled={sheetBusy}
              style={{ background: 'none', border: '1px solid var(--border)', color: 'var(--text-secondary)', borderRadius: 6, padding: '6px 12px', fontSize: 12 }}
            >
              {sheetBusy ? 'Working...' : 'Full Resync'}
            </button>
          </div>
        ) : (
          <button className="btn-primary" onClick={handleCreateSheet} disabled={sheetBusy}>
            {sheetBusy ? 'Creating...' : 'Create Live Sheet'}
          </button>
        )}
        {resyncMessage && <div style={{ color: 'var(--accent-green)', fontSize: 13, marginTop: 8 }}>{resyncMessage}</div>}
        {sheetError && <div style={{ color: 'var(--accent-red)', fontSize: 13, marginTop: 8 }}>{sheetError}</div>}
      </section>
    </div>
  );
}
