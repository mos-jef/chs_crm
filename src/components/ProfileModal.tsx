import React, { useState } from 'react';
import { useAuth } from '../AuthContext';
import { setUserAvatar, updateDisplayName } from '../db/users';
import { mimeTypeFor } from '../util/mime';
import Avatar from './Avatar';

export default function ProfileModal({ onClose }: { onClose: () => void }) {
  const { user, profile, refreshProfile } = useAuth();
  const [name, setName] = useState(profile?.displayName || '');
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  async function handleChangePhoto() {
    if (!user) return;
    setError('');
    const picked = await window.electronAPI.pickFile({
      filters: [{ name: 'Images', extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'] }],
    });
    if (!picked.success || !picked.filePath || !picked.fileName) return;

    setUploading(true);
    try {
      const result = await window.electronAPI.driveUploadAvatar({
        filePath: picked.filePath,
        fileName: picked.fileName,
        mimeType: mimeTypeFor(picked.fileName),
      });
      if (!result.success || !result.driveFileId) {
        setError(result.error || 'Upload failed — check your Drive connection in Settings.');
        setUploading(false);
        return;
      }
      await setUserAvatar(user.uid, result.driveFileId);
      await refreshProfile();
    } catch (err: any) {
      setError(err.message || 'Upload failed.');
    }
    setUploading(false);
  }

  async function handleSaveName() {
    if (!user || !name.trim()) return;
    await updateDisplayName(user.uid, name.trim());
    await refreshProfile();
  }

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.6)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
      }}
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: 'var(--bg-card)',
          border: '1px solid var(--border)',
          borderRadius: 12,
          padding: 28,
          width: 340,
        }}
      >
        <h3 style={{ color: 'var(--text-primary)', marginTop: 0 }}>My Profile</h3>

        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 20 }}>
          <Avatar driveFileId={profile?.avatarDriveFileId} name={profile?.displayName} size={64} />
          <button
            onClick={handleChangePhoto}
            disabled={uploading}
            style={{
              background: 'none',
              border: '1px dashed var(--border)',
              color: 'var(--text-secondary)',
              borderRadius: 6,
              padding: '8px 12px',
              fontSize: 12,
            }}
          >
            {uploading ? 'Uploading...' : 'Change Photo'}
          </button>
        </div>

        <label style={{ fontSize: 12, color: 'var(--text-muted)', display: 'block', marginBottom: 4 }}>
          Display Name
        </label>
        <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
          <input value={name} onChange={(e) => setName(e.target.value)} style={{ flex: 1 }} />
          <button className="btn-primary" onClick={handleSaveName}>
            Save
          </button>
        </div>

        {error && <div style={{ color: 'var(--accent-red)', fontSize: 13, marginBottom: 8 }}>{error}</div>}

        <div style={{ color: 'var(--text-muted)', fontSize: 12, marginTop: 12 }}>{profile?.email}</div>

        <button
          onClick={onClose}
          style={{
            marginTop: 16,
            width: '100%',
            background: 'none',
            border: '1px solid var(--border)',
            color: 'var(--text-secondary)',
            borderRadius: 8,
            padding: '8px 0',
            fontSize: 13,
          }}
        >
          Close
        </button>
      </div>
    </div>
  );
}
