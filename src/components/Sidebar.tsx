import React, { useState } from 'react';
import { NavLink } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from '../firebase';
import { useAuth } from '../AuthContext';
import Avatar from './Avatar';
import ProfileModal from './ProfileModal';

const linkStyle: React.CSSProperties = {
  display: 'block',
  padding: '10px 16px',
  borderRadius: 8,
  color: 'var(--text-primary)',
  textDecoration: 'none',
  fontSize: 14,
  marginBottom: 4,
};

export default function Sidebar() {
  const { profile } = useAuth();
  const [showProfile, setShowProfile] = useState(false);

  return (
    <div
      style={{
        width: 220,
        background: 'var(--bg-secondary)',
        borderRight: '1px solid var(--border)',
        display: 'flex',
        flexDirection: 'column',
        padding: 16,
        height: '100%',
      }}
    >
      <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 24, color: 'var(--text-primary)' }}>
        CHS CRM
      </div>

      <NavLink
        to="/properties"
        style={({ isActive }) => ({
          ...linkStyle,
          background: isActive ? 'var(--bg-tertiary)' : 'transparent',
        })}
      >
        Properties
      </NavLink>
      <NavLink
        to="/document-reader"
        style={({ isActive }) => ({
          ...linkStyle,
          background: isActive ? 'var(--bg-tertiary)' : 'transparent',
        })}
      >
        Document Reader
      </NavLink>
      <NavLink
        to="/settings"
        style={({ isActive }) => ({
          ...linkStyle,
          background: isActive ? 'var(--bg-tertiary)' : 'transparent',
        })}
      >
        Settings
      </NavLink>
      {profile?.role === 'admin' && (
        <NavLink
          to="/admin"
          style={({ isActive }) => ({
            ...linkStyle,
            background: isActive ? 'var(--bg-tertiary)' : 'transparent',
          })}
        >
          Admin
        </NavLink>
      )}

      <div style={{ flex: 1 }} />

      <button
        onClick={() => setShowProfile(true)}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 10,
          background: 'none',
          border: 'none',
          padding: '6px 4px',
          marginBottom: 8,
          cursor: 'pointer',
          textAlign: 'left',
        }}
      >
        <Avatar driveFileId={profile?.avatarDriveFileId} name={profile?.displayName} size={32} />
        <span style={{ fontSize: 12, color: 'var(--text-muted)', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {profile?.displayName || profile?.email}
        </span>
      </button>

      <button
        onClick={() => signOut(auth)}
        style={{
          background: 'none',
          border: '1px solid var(--border)',
          color: 'var(--text-secondary)',
          borderRadius: 6,
          padding: '8px 10px',
          fontSize: 13,
        }}
      >
        Sign out
      </button>

      {showProfile && <ProfileModal onClose={() => setShowProfile(false)} />}
    </div>
  );
}
