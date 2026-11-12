export function resolveFirebaseConfig(env) {
  const target = env.VITE_FIREBASE_TARGET || 'emulator';
  if (target === 'emulator') {
    return {
      target,
      config: {
        apiKey: 'demo-teencu-local-key',
        authDomain: 'demo-teencu.firebaseapp.com',
        projectId: 'demo-teencu',
        appId: 'demo-teencu-admin',
      },
    };
  }
  if (target !== 'cloud') {
    throw new Error('VITE_FIREBASE_TARGET harus emulator atau cloud.');
  }
  const fields = {
    apiKey: 'VITE_FIREBASE_API_KEY',
    authDomain: 'VITE_FIREBASE_AUTH_DOMAIN',
    projectId: 'VITE_FIREBASE_PROJECT_ID',
    appId: 'VITE_FIREBASE_APP_ID',
  };
  const config = {};
  for (const [field, key] of Object.entries(fields)) {
    const value = env[key]?.trim();
    if (!value) throw new Error(`Konfigurasi web belum lengkap: ${key}.`);
    config[field] = value;
  }
  if (config.projectId !== 'teencu-dev') {
    throw new Error('Dashboard cloud harus memakai project teencu-dev.');
  }
  if (!/^1:\d+:web:[a-zA-Z0-9]+$/.test(config.appId)) {
    throw new Error('Gunakan appId Firebase Web, bukan appId Android.');
  }
  return { target, config };
}
