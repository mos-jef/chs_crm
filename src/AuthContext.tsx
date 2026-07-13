import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from 'react';
import { onAuthStateChanged, User } from 'firebase/auth';
import { auth } from './firebase';
import { getUserProfile, createPendingUserProfile } from './db/users';
import { UserProfile } from './db/schema';

interface AuthContextValue {
  user: User | null;
  profile: UserProfile | null;
  loading: boolean;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue>({
  user: null,
  profile: null,
  loading: true,
  refreshProfile: async () => {},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (firebaseUser) => {
      setUser(firebaseUser);
      if (firebaseUser) {
        let p = await getUserProfile(firebaseUser.uid);
        // Covers signing in with an Auth account that predates this app (e.g.
        // one created by the old Flutter version) — the Auth account itself
        // survived the Firestore reset, but its profile document didn't.
        // Without this, that account would be stuck on the pending-approval
        // screen forever with no document to promote to admin.
        if (!p) {
          p = await createPendingUserProfile(
            firebaseUser.uid,
            firebaseUser.email || '',
            firebaseUser.displayName || firebaseUser.email || 'New User'
          );
        }
        setProfile(p);
      } else {
        setProfile(null);
      }
      setLoading(false);
    });
    return unsub;
  }, []);

  // Re-fetches the profile without a full sign-out/sign-in — used after
  // changing the avatar or display name so the sidebar updates immediately.
  const refreshProfile = useCallback(async () => {
    if (!auth.currentUser) return;
    const p = await getUserProfile(auth.currentUser.uid);
    setProfile(p);
  }, []);

  return (
    <AuthContext.Provider value={{ user, profile, loading, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
