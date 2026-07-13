import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// This is the SAME Firebase project the Flutter version of chs-crm used
// (project id "chs-crm"), per your call to keep it and start fresh within it
// rather than spin up a new project. The old Flutter-era Firestore data gets
// cleared by scripts/reset-firestore.js, not by anything in the app itself —
// the app never deletes collections wholesale on its own.
//
// Firebase web config values are safe to keep in client code (they identify
// the project, they don't authorize access on their own — Firestore/Auth
// security rules do that job) so there's no secret-handling concern here.
const firebaseConfig = {
  apiKey: 'AIzaSyBsBvZn4RAOQkTJ82GzU2bTYzzYSUXODxQ',
  authDomain: 'chs-crm.firebaseapp.com',
  projectId: 'chs-crm',
  messagingSenderId: '507014107846',
  appId: '1:507014107846:web:ec01bc2cdb9982287a3dc7',
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
