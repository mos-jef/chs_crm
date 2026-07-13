import React from 'react';
import { signOut } from 'firebase/auth';
import { auth } from '../firebase';

export default function PendingApprovalScreen() {
  return (
    <div
      style={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 12,
        color: 'var(--text-primary)',
      }}
    >
      <h2>Waiting on approval</h2>
      <p style={{ color: 'var(--text-muted)', maxWidth: 360, textAlign: 'center' }}>
        Your account was created but hasn't been approved yet. Once an admin
        approves it, sign back in and you'll have access.
      </p>
      <button className="btn-primary" onClick={() => signOut(auth)}>
        Sign out
      </button>
    </div>
  );
}
