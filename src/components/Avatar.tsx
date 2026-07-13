import React, { useEffect, useState } from 'react';

// A Shared Drive file isn't reachable by a plain <img src="https://..."> —
// it needs the app's authenticated Drive session to fetch it, which only the
// Electron main process has. So this downloads it to a local temp file via
// driveDownloadFile and points the <img> at that instead. Small in-memory
// cache (module-level, survives across mounts/unmounts in the same session)
// so switching screens doesn't re-download the same avatar repeatedly.

const pathCache = new Map<string, string>();

interface Props {
  driveFileId?: string;
  name?: string;
  size?: number;
}

export default function Avatar({ driveFileId, name, size = 36 }: Props) {
  const [localPath, setLocalPath] = useState<string | null>(
    driveFileId ? pathCache.get(driveFileId) || null : null
  );

  useEffect(() => {
    if (!driveFileId) {
      setLocalPath(null);
      return;
    }
    const cached = pathCache.get(driveFileId);
    if (cached) {
      setLocalPath(cached);
      return;
    }
    let cancelled = false;
    window.electronAPI.driveDownloadFile({ fileId: driveFileId }).then((result) => {
      if (cancelled) return;
      if (result.success && result.path) {
        pathCache.set(driveFileId, result.path);
        setLocalPath(result.path);
      }
    });
    return () => {
      cancelled = true;
    };
  }, [driveFileId]);

  const initials = (name || '?')
    .trim()
    .split(/\s+/)
    .map((s) => s[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();

  const style: React.CSSProperties = {
    width: size,
    height: size,
    borderRadius: '50%',
    objectFit: 'cover',
    background: 'var(--bg-tertiary)',
    border: '1px solid var(--border)',
  };

  if (localPath) {
    return <img src={`file://${localPath}`} alt={name || 'avatar'} style={style} />;
  }

  return (
    <div
      style={{
        ...style,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'var(--text-muted)',
        fontSize: size * 0.4,
        fontWeight: 600,
      }}
    >
      {initials}
    </div>
  );
}
