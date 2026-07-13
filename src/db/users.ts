// User profiles + the pending-approval gate, ported from the Flutter version's
// concept (AuthWrapper -> PendingApprovalScreen -> AdminDashboard). Built in
// from day one even though it's just the two of you right now, per your call
// that this needs to scale to more people if business grows — this way
// adding someone later is "approve their request," not a re-architecture.

import { collection, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { UserProfile } from './schema';

const COLLECTION = 'users';

function usersCollection() {
  return collection(db, COLLECTION);
}

// Some accounts still carry a Firestore document created by the old Flutter
// app, which used isAdmin/isApproved instead of this app's role/approved.
// Rather than requiring anyone with a pre-existing account to manually patch
// their document in the Firebase console, honor the old fields as a
// fallback when the new ones aren't present.
function normalizeUserProfile(uid: string, data: any): UserProfile {
  return {
    uid: data.uid ?? uid,
    email: data.email ?? '',
    displayName: data.displayName ?? data.email ?? 'User',
    avatarDriveFileId: data.avatarDriveFileId,
    role: data.role ?? (data.isAdmin ? 'admin' : 'member'),
    approved: data.approved ?? data.isApproved ?? false,
    createdAt: data.createdAt ?? Date.now(),
  };
}

export async function getUserProfile(uid: string): Promise<UserProfile | null> {
  const snap = await getDoc(doc(usersCollection(), uid));
  return snap.exists() ? normalizeUserProfile(uid, snap.data()) : null;
}

// Called right after Firebase Auth sign-up. New users land as unapproved —
// the first admin has to be promoted manually once (directly in the Firebase
// console, one time), after that admins approve everyone else from the app.
export async function createPendingUserProfile(
  uid: string,
  email: string,
  displayName: string
): Promise<UserProfile> {
  const profile: UserProfile = {
    uid,
    email,
    displayName,
    role: 'member',
    approved: false,
    createdAt: Date.now(),
  };
  await setDoc(doc(usersCollection(), uid), profile);
  return profile;
}

export async function listAllUsers(): Promise<UserProfile[]> {
  const snap = await getDocs(usersCollection());
  return snap.docs.map((d) => normalizeUserProfile(d.id, d.data()));
}

export async function approveUser(uid: string): Promise<void> {
  await setDoc(doc(usersCollection(), uid), { approved: true }, { merge: true });
}

export async function setUserAvatar(
  uid: string,
  avatarDriveFileId: string
): Promise<void> {
  await setDoc(doc(usersCollection(), uid), { avatarDriveFileId }, { merge: true });
}

export async function updateDisplayName(uid: string, displayName: string): Promise<void> {
  await setDoc(doc(usersCollection(), uid), { displayName }, { merge: true });
}
