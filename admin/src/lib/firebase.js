import { initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth } from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore } from 'firebase/firestore';
import { resolveFirebaseConfig } from './firebaseConfig.js';

let services = import.meta.hot?.data.firebaseServices;
if (import.meta.hot) {
  import.meta.hot.dispose((data) => { data.firebaseServices = services; });
}

// Lazy initialization: the setup page does not log in or read/write cloud data.
export function getFirebaseServices() {
  if (services) return services;
  const { target, config } = resolveFirebaseConfig(import.meta.env);
  const app = initializeApp(config, `teencu-admin-${target}`);
  const auth = getAuth(app);
  const firestore = getFirestore(app);
  if (target === 'emulator') {
    connectAuthEmulator(auth, 'http://127.0.0.1:9099');
    connectFirestoreEmulator(firestore, '127.0.0.1', 8080);
  }
  services = { app, auth, firestore, target };
  return services;
}
