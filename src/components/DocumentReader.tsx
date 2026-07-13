import React, { useEffect, useMemo, useState } from 'react';
import { DocumentCategory, getDocumentCategories } from '../db/documentCategories';
import { DocumentTemplate, resolveTemplate } from '../db/documentTemplates';
import { loadProperties, upsertProperty } from '../db/properties';
import { PropertyFile, DocumentRef, generateId } from '../db/schema';
import {
  applyExtractionToProperty,
  matchPropertyByAddress,
  matchPropertyByTaxAccountNumber,
} from '../db/applyExtraction';
import { mimeTypeFor } from '../util/mime';

interface FileRow {
  id: string;
  filePath: string;
  fileName: string;
  status: 'pending' | 'processing' | 'done' | 'no-match' | 'error';
  extracted?: Record<string, any>;
  resultLabel?: string; // "Created file 12-345" / "Updated file 12-345" / etc.
  error?: string;
  manualPropertyId?: string;
}

export default function DocumentReader() {
  const [categories, setCategories] = useState<DocumentCategory[]>([]);
  const [categoryKey, setCategoryKey] = useState('');
  const [state, setState] = useState('');
  const [county, setCounty] = useState('');
  const [template, setTemplate] = useState<DocumentTemplate | null>(null);
  const [properties, setProperties] = useState<PropertyFile[]>([]);
  const [files, setFiles] = useState<FileRow[]>([]);
  const [running, setRunning] = useState(false);

  useEffect(() => {
    getDocumentCategories().then((cats) => {
      setCategories(cats);
      if (cats[0]) setCategoryKey(cats[0].key);
    });
    loadProperties().then(setProperties);
  }, []);

  useEffect(() => {
    if (!categoryKey) return;
    resolveTemplate(categoryKey, state, county).then(setTemplate);
  }, [categoryKey, state, county]);

  const selectedCategory = useMemo(
    () => categories.find((c) => c.key === categoryKey),
    [categories, categoryKey]
  );

  async function handleAddFile() {
    const picked = await window.electronAPI.pickFile();
    if (!picked.success || !picked.filePath || !picked.fileName) return;
    setFiles((prev) => [
      ...prev,
      { id: generateId('row'), filePath: picked.filePath!, fileName: picked.fileName!, status: 'pending' },
    ]);
  }

  async function handleAddFolder() {
    const picked = await window.electronAPI.pickFolder();
    if (!picked.success || !picked.folderPath) return;
    const scan = await window.electronAPI.scanFolderForPdfs(picked.folderPath);
    if (!scan.success || !scan.files || scan.files.length === 0) {
      alert('No PDF files found in that folder.');
      return;
    }
    setFiles((prev) => [
      ...prev,
      ...scan.files!.map((f) => ({
        id: generateId('row'),
        filePath: f.path,
        fileName: f.name,
        status: 'pending' as const,
      })),
    ]);
  }

  function clearFiles() {
    setFiles([]);
  }

  // Uploads the source file to Drive under State/County/FileKey/Category and
  // returns a DocumentRef for it. Extraction/field-mapping still counts as a
  // success even if this fails (e.g. Drive not connected yet) — the property
  // data isn't lost, it's just not filed yet, so this only ever warns.
  async function uploadSourceFile(property: PropertyFile, filePath: string, fileName: string): Promise<DocumentRef | null> {
    if (!selectedCategory) return null;
    const fileKey = property.taxAccountNumber || property.fileNumber;
    if (!property.state || !property.county || !fileKey) return null;
    try {
      const result = await window.electronAPI.driveUploadDocument({
        state: property.state,
        county: property.county,
        fileKey,
        categoryFolderName: selectedCategory.folderName,
        filePath,
        fileName,
        mimeType: mimeTypeFor(fileName),
      });
      if (!result.success || !result.driveFileId) return null;
      return {
        id: generateId('doc'),
        driveFileId: result.driveFileId,
        fileName,
        documentCategoryKey: selectedCategory.key,
        uploadDate: Date.now(),
      };
    } catch {
      return null;
    }
  }

  async function processRow(row: FileRow): Promise<FileRow> {
    if (!template || !selectedCategory) {
      return { ...row, status: 'error', error: 'No template resolved for this category.' };
    }

    let extracted: Record<string, any>;
    try {
      const readResult = await window.electronAPI.readFileBase64(row.filePath);
      if (!readResult.success || !readResult.base64) {
        return { ...row, status: 'error', error: readResult.error || "Couldn't read file." };
      }
      const extraction = await window.electronAPI.claudeExtractDocument({
        base64: readResult.base64,
        mimeType: mimeTypeFor(row.fileName),
        fields: template.fields,
        categoryLabel: selectedCategory.label,
        county,
        state,
      });
      if (!extraction.success || !extraction.extracted) {
        return { ...row, status: 'error', error: extraction.error || 'Extraction failed.' };
      }
      extracted = extraction.extracted;
    } catch (err: any) {
      return { ...row, status: 'error', error: err.message || 'Extraction failed.' };
    }

    if (template.applyTarget === 'overview') {
      const match = matchPropertyByTaxAccountNumber(properties, extracted);
      const { property, isNew } = applyExtractionToProperty(match, 'overview', extracted, state, county);
      const docRef = await uploadSourceFile(property, row.filePath, row.fileName);
      const finalProperty = docRef ? { ...property, documents: [...property.documents, docRef] } : property;
      await upsertProperty(finalProperty);
      setProperties((prev) => {
        const idx = prev.findIndex((p) => p.id === finalProperty.id);
        if (idx >= 0) {
          const copy = [...prev];
          copy[idx] = finalProperty;
          return copy;
        }
        return [...prev, finalProperty];
      });
      return {
        ...row,
        status: 'done',
        extracted,
        resultLabel: `${isNew ? 'Created' : 'Updated'} file ${finalProperty.fileNumber}${docRef ? '' : ' (Drive upload skipped — check Drive connection)'}`,
      };
    }

    // Array targets (Deeds/Mortgages/Judgments/Easements) need an existing
    // property. Try an address match; if nothing, leave this row for manual
    // matching rather than guessing.
    const match = matchPropertyByAddress(properties, extracted);
    if (!match) {
      return { ...row, status: 'no-match', extracted };
    }
    return applyToProperty(row, extracted, match);
  }

  async function applyToProperty(row: FileRow, extracted: Record<string, any>, property: PropertyFile): Promise<FileRow> {
    if (!template) return { ...row, status: 'error', error: 'No template.' };
    try {
      const { property: updated } = applyExtractionToProperty(property, template.applyTarget, extracted, state, county);
      const docRef = await uploadSourceFile(updated, row.filePath, row.fileName);
      const finalProperty = docRef ? { ...updated, documents: [...updated.documents, docRef] } : updated;
      await upsertProperty(finalProperty);
      setProperties((prev) => prev.map((p) => (p.id === finalProperty.id ? finalProperty : p)));
      return {
        ...row,
        status: 'done',
        extracted,
        resultLabel: `Added to file ${finalProperty.fileNumber}${docRef ? '' : ' (Drive upload skipped)'}`,
      };
    } catch (err: any) {
      return { ...row, status: 'error', error: err.message };
    }
  }

  async function handleRun() {
    setRunning(true);
    for (const row of files) {
      if (row.status === 'done') continue;
      setFiles((prev) => prev.map((r) => (r.id === row.id ? { ...r, status: 'processing' } : r)));
      const result = await processRow(row);
      setFiles((prev) => prev.map((r) => (r.id === row.id ? result : r)));
    }
    setRunning(false);
  }

  async function handleManualApply(row: FileRow) {
    if (!row.manualPropertyId || !row.extracted) return;
    const property = properties.find((p) => p.id === row.manualPropertyId);
    if (!property) return;
    setFiles((prev) => prev.map((r) => (r.id === row.id ? { ...r, status: 'processing' } : r)));
    const result = await applyToProperty(row, row.extracted, property);
    setFiles((prev) => prev.map((r) => (r.id === row.id ? result : r)));
  }

  return (
    <div style={{ padding: 24, maxWidth: 900 }}>
      <h2 style={{ color: 'var(--text-primary)' }}>Document Reader</h2>
      <p style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 20 }}>
        Pick a category, tell it what state/county you're reading (so it uses the right
        template and files correctly in Drive), then add a file or a whole folder and run it.
      </p>

      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <select value={categoryKey} onChange={(e) => setCategoryKey(e.target.value)} style={{ minWidth: 160 }}>
          {categories.map((c) => (
            <option key={c.key} value={c.key}>
              {c.label}
            </option>
          ))}
        </select>
        <input placeholder="State (e.g. OR)" value={state} onChange={(e) => setState(e.target.value.toUpperCase())} style={{ width: 100 }} />
        <input placeholder="County" value={county} onChange={(e) => setCounty(e.target.value)} style={{ width: 160 }} />
      </div>

      {template && (
        <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 16 }}>
          Using {template.county ? `${template.county} County` : template.state ? `${template.state}-wide` : 'default'} template
          — fields: {template.fields.map((f) => f.label).join(', ')}
        </div>
      )}

      <div style={{ display: 'flex', gap: 10, marginBottom: 16 }}>
        <button className="btn-primary" onClick={handleAddFile}>
          + Add File
        </button>
        <button className="btn-primary" onClick={handleAddFolder}>
          + Add Folder
        </button>
        {files.length > 0 && (
          <button onClick={clearFiles} style={{ background: 'none', border: '1px solid var(--border)', color: 'var(--text-secondary)', borderRadius: 8, padding: '10px 14px', fontSize: 13 }}>
            Clear List
          </button>
        )}
        {files.length > 0 && (
          <button className="btn-primary" onClick={handleRun} disabled={running || !template}>
            {running ? 'Running...' : `Run (${files.filter((f) => f.status !== 'done').length})`}
          </button>
        )}
      </div>

      {files.length > 0 && (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ textAlign: 'left', color: 'var(--text-muted)', fontSize: 12 }}>
              <th style={{ padding: '6px 8px' }}>File</th>
              <th style={{ padding: '6px 8px' }}>Status</th>
              <th style={{ padding: '6px 8px' }}>Result</th>
            </tr>
          </thead>
          <tbody>
            {files.map((row) => (
              <tr key={row.id} style={{ borderTop: '1px solid var(--border)', color: 'var(--text-primary)' }}>
                <td style={{ padding: '8px', fontSize: 13 }}>{row.fileName}</td>
                <td style={{ padding: '8px', fontSize: 13 }}>{row.status}</td>
                <td style={{ padding: '8px', fontSize: 13 }}>
                  {row.status === 'done' && row.resultLabel}
                  {row.status === 'error' && <span style={{ color: 'var(--accent-red)' }}>{row.error}</span>}
                  {row.status === 'no-match' && (
                    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                      <span style={{ color: 'var(--text-muted)' }}>No address match —</span>
                      <select
                        value={row.manualPropertyId || ''}
                        onChange={(e) =>
                          setFiles((prev) =>
                            prev.map((r) => (r.id === row.id ? { ...r, manualPropertyId: e.target.value } : r))
                          )
                        }
                      >
                        <option value="">Pick a file...</option>
                        {properties.map((p) => (
                          <option key={p.id} value={p.id}>
                            {p.fileNumber} — {p.address}
                          </option>
                        ))}
                      </select>
                      <button
                        onClick={() => handleManualApply(row)}
                        disabled={!row.manualPropertyId}
                        style={{ background: 'none', border: '1px solid var(--border)', color: 'var(--text-secondary)', borderRadius: 6, padding: '4px 10px', fontSize: 12 }}
                      >
                        Apply
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
