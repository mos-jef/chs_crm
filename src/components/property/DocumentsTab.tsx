import React, { useEffect, useState } from 'react';
import { PropertyFile, DocumentRef, generateId } from '../../db/schema';
import { DocumentCategory, getDocumentCategories } from '../../db/documentCategories';
import { upsertProperty } from '../../db/properties';
import { mimeTypeFor } from '../../util/mime';

interface Props {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}

// Real upload now: picks a local file, uploads it into
// State/County/FileKey/Category in the Shared Drive (creating any of those
// folders that don't exist yet), and adds a DocumentRef pointing at the
// resulting Drive file ID — not a path, so this survives files getting
// moved/renamed in Drive later.
//
// This tab saves the updated document list to Firestore immediately after
// each upload, rather than waiting for the page's manual Save button — the
// file is already sitting in Drive at that point, so the link to it should
// never depend on someone remembering to click Save afterward.
export default function DocumentsTab({ property, onChange }: Props) {
  const [categories, setCategories] = useState<DocumentCategory[]>([]);
  const [uploadingKey, setUploadingKey] = useState<string | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    getDocumentCategories().then(setCategories);
  }, []);

  const fileKey = property.taxAccountNumber || property.fileNumber;

  async function handleUpload(cat: DocumentCategory) {
    setError('');
    if (!property.state || !property.county || !fileKey) {
      setError('Set State, County, and a Tax Account No. (or File Number) on the Overview tab first — that\'s what determines where this gets filed in Drive.');
      return;
    }

    const picked = await window.electronAPI.pickFile();
    if (!picked.success || !picked.filePath || !picked.fileName) return;

    setUploadingKey(cat.key);
    try {
      const result = await window.electronAPI.driveUploadDocument({
        state: property.state,
        county: property.county,
        fileKey,
        categoryFolderName: cat.folderName,
        filePath: picked.filePath,
        fileName: picked.fileName,
        mimeType: mimeTypeFor(picked.fileName),
      });

      if (!result.success || !result.driveFileId) {
        setError(result.error || 'Upload failed.');
        setUploadingKey(null);
        return;
      }

      const newDoc: DocumentRef = {
        id: generateId('doc'),
        driveFileId: result.driveFileId,
        fileName: picked.fileName,
        documentCategoryKey: cat.key,
        uploadDate: Date.now(),
      };
      const documents = [...property.documents, newDoc];
      onChange({ documents }); // updates the on-screen list immediately
      await upsertProperty({ ...property, documents }); // and persists right away, not on next manual Save
    } catch (err: any) {
      setError(err.message || 'Upload failed.');
    }
    setUploadingKey(null);
  }

  async function handleOpen(doc: DocumentRef) {
    const result = await window.electronAPI.driveGetFileMetadata({ fileId: doc.driveFileId });
    if (result.success && result.meta?.webViewLink) {
      window.open(result.meta.webViewLink, '_blank');
    } else {
      setError(result.error || "Couldn't open that file.");
    }
  }

  return (
    <div style={{ maxWidth: 640 }}>
      <p style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 16 }}>
        Files are stored in Google Drive under{' '}
        <code>
          {property.state || 'State'}/{property.county || 'County'}/{fileKey || 'File'}/&lt;Category&gt;
        </code>
        . The first upload for this file creates that folder chain automatically.
      </p>

      {error && (
        <div style={{ color: 'var(--accent-red)', fontSize: 13, marginBottom: 12 }}>{error}</div>
      )}

      {categories.map((cat) => {
        const docs = property.documents.filter((d) => d.documentCategoryKey === cat.key);
        return (
          <div key={cat.key} style={{ marginBottom: 16 }}>
            <div style={{ fontWeight: 600, color: 'var(--text-primary)', fontSize: 14, marginBottom: 6 }}>
              {cat.label} ({docs.length})
            </div>
            {docs.length === 0 ? (
              <div style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 6 }}>No files.</div>
            ) : (
              <ul style={{ margin: '0 0 6px', paddingLeft: 18 }}>
                {docs.map((d) => (
                  <li key={d.id} style={{ fontSize: 13 }}>
                    <button
                      onClick={() => handleOpen(d)}
                      style={{
                        background: 'none',
                        border: 'none',
                        color: 'var(--text-secondary)',
                        textDecoration: 'underline',
                        cursor: 'pointer',
                        padding: 0,
                        fontSize: 13,
                      }}
                    >
                      {d.fileName}
                    </button>
                  </li>
                ))}
              </ul>
            )}
            <button
              onClick={() => handleUpload(cat)}
              disabled={uploadingKey === cat.key}
              style={{
                background: 'none',
                border: '1px dashed var(--border)',
                color: 'var(--text-secondary)',
                borderRadius: 6,
                padding: '6px 12px',
                fontSize: 12,
              }}
            >
              {uploadingKey === cat.key ? 'Uploading...' : `+ Upload to ${cat.label}`}
            </button>
          </div>
        );
      })}
    </div>
  );
}
