import React, { useEffect, useState } from 'react';
import { UserProfile } from '../db/schema';
import { listAllUsers, approveUser } from '../db/users';
import Avatar from './Avatar';

// The screen that was missing: approveUser() and the "Admin" nav link
// existed, but nothing actually rendered a list to approve people from —
// which meant every new sign-up needed a manual Firestore edit. This is
// what makes the pending-approval system actually usable day to day.
export default function AdminDashboard() {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);

  function refresh() {
    setLoading(true);
    listAllUsers().then((u) => {
      setUsers(u);
      setLoading(false);
    });
  }

  useEffect(() => {
    refresh();
  }, []);

  async function handleApprove(uid: string) {
    await approveUser(uid);
    refresh();
  }

  const pending = users.filter((u) => !u.approved);
  const approved = users.filter((u) => u.approved);

  if (loading) {
    return <div style={{ padding: 24, color: 'var(--text-muted)' }}>Loading...</div>;
  }

  return (
    <div style={{ padding: 24, maxWidth: 640 }}>
      <h2 style={{ color: 'var(--text-primary)' }}>Admin</h2>

      <section style={{ marginBottom: 32 }}>
        <h3 style={{ color: 'var(--text-primary)', fontSize: 15 }}>
          Pending Approval {pending.length > 0 && `(${pending.length})`}
        </h3>
        {pending.length === 0 ? (
          <div style={{ color: 'var(--text-muted)', fontSize: 13 }}>No one is waiting.</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {pending.map((u) => (
              <div
                key={u.uid}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 12,
                  padding: '10px 14px',
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  borderRadius: 8,
                }}
              >
                <Avatar driveFileId={u.avatarDriveFileId} name={u.displayName} size={32} />
                <div style={{ flex: 1 }}>
                  <div style={{ color: 'var(--text-primary)', fontSize: 14 }}>{u.displayName}</div>
                  <div style={{ color: 'var(--text-muted)', fontSize: 12 }}>{u.email}</div>
                </div>
                <button className="btn-primary" onClick={() => handleApprove(u.uid)}>
                  Approve
                </button>
              </div>
            ))}
          </div>
        )}
      </section>

      <section>
        <h3 style={{ color: 'var(--text-primary)', fontSize: 15 }}>Approved Users</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {approved.map((u) => (
            <div
              key={u.uid}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                padding: '10px 14px',
                background: 'var(--bg-card)',
                border: '1px solid var(--border)',
                borderRadius: 8,
              }}
            >
              <Avatar driveFileId={u.avatarDriveFileId} name={u.displayName} size={32} />
              <div style={{ flex: 1 }}>
                <div style={{ color: 'var(--text-primary)', fontSize: 14 }}>{u.displayName}</div>
                <div style={{ color: 'var(--text-muted)', fontSize: 12 }}>{u.email}</div>
              </div>
              {u.role === 'admin' && (
                <span style={{ color: 'var(--accent-primary)', fontSize: 12, fontWeight: 600 }}>Admin</span>
              )}
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
