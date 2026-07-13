import React, { useEffect } from 'react';
import {
  HashRouter,
  Routes,
  Route,
  Navigate,
} from 'react-router-dom';
import { AuthProvider, useAuth } from './AuthContext';
import { applyTheme, getSavedTheme } from './theme';
import { ensureSeeded } from './db/documentCategories';
import { ensureDefaultTemplatesSeeded } from './db/documentTemplates';
import LoginScreen from './components/LoginScreen';
import PendingApprovalScreen from './components/PendingApprovalScreen';
import Sidebar from './components/Sidebar';
import PropertyList from './components/PropertyList';
import PropertyDetail from './components/property/PropertyDetail';
import DocumentReader from './components/DocumentReader';
import Settings from './components/Settings';
import AdminDashboard from './components/AdminDashboard';

function AuthGate() {
  const { user, profile, loading } = useAuth();

  useEffect(() => {
    if (profile?.approved) {
      ensureSeeded().then((categories) => ensureDefaultTemplatesSeeded(categories));
    }
  }, [profile?.approved]);

  if (loading) {
    return (
      <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <span style={{ color: 'var(--text-muted)' }}>Loading...</span>
      </div>
    );
  }

  if (!user) return <LoginScreen />;
  if (!profile?.approved) return <PendingApprovalScreen />;

  return (
    <div style={{ display: 'flex', height: '100%' }}>
      <Sidebar />
      <div style={{ flex: 1, overflow: 'auto' }}>
        <Routes>
          <Route path="/properties" element={<PropertyList />} />
          <Route path="/properties/:id" element={<PropertyDetail />} />
          <Route path="/document-reader" element={<DocumentReader />} />
          <Route path="/settings" element={<Settings />} />
          {profile?.role === 'admin' && <Route path="/admin" element={<AdminDashboard />} />}
          <Route path="*" element={<Navigate to="/properties" replace />} />
        </Routes>
      </div>
    </div>
  );
}

export default function App() {
  useEffect(() => {
    applyTheme(getSavedTheme());
  }, []);

  return (
    <HashRouter>
      <AuthProvider>
        <AuthGate />
      </AuthProvider>
    </HashRouter>
  );
}
