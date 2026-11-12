import { createContext, useContext, useEffect, useMemo, useSyncExternalStore } from 'react';
import { createAdminSession } from './adminSession.js';

const AdminSessionContext = createContext(null);

export function AdminSessionProvider({ access, children }) {
  const controller = useMemo(() => createAdminSession(access), [access]);
  const session = useSyncExternalStore(controller.subscribe, controller.getSnapshot);
  useEffect(() => {
    controller.start();
    return () => controller.stop();
  }, [controller]);
  return <AdminSessionContext.Provider value={{ session, controller, access }}>
    {children}
  </AdminSessionContext.Provider>;
}

export function useAdminSession() {
  return useContext(AdminSessionContext);
}
