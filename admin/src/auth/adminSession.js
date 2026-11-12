// Framework-independent session controller. Generation invalidates callbacks from
// previous users, retries, and stopped subscriptions, even if they arrive late.
export function createAdminSession(access, { timeoutMs = 15000 } = {}) {
  let state = { status: 'restoring', user: null };
  const listeners = new Set();
  let stopAuth;
  let stopRole;
  let timer;
  let generation = 0;
  let active = false;
  let authGeneration = 0;
  const emit = (value) => { state = value; listeners.forEach((listener) => listener()); };
  const clearRole = () => {
    generation++;
    clearTimeout(timer);
    stopRole?.();
    stopRole = undefined;
  };
  function check(user) {
    clearRole();
    emit({ status: 'checking', user });
    const current = generation;
    const fail = () => {
      if (!active || generation !== current) return;
      clearRole();
      emit({ status: 'access-error', user });
    };
    timer = setTimeout(fail, timeoutMs);
    stopRole = access.watchAccess(user.uid, (role) => {
      if (!active || generation !== current) return;
      if (!role.confirmed) {
        // Cached grants never unlock the dashboard, including after disconnect.
        emit({ status: 'checking', user });
        clearTimeout(timer);
        timer = setTimeout(fail, timeoutMs);
        return;
      }
      clearTimeout(timer);
      emit({ status: role.enabled ? 'authorized' : 'denied', user });
    }, fail);
  }
  const controller = {
    subscribe(listener) { listeners.add(listener); return () => listeners.delete(listener); },
    getSnapshot: () => state,
    start() {
      if (active) return;
      active = true;
      const currentAuth = ++authGeneration;
      emit({ status: 'restoring', user: null });
      timer = setTimeout(() => {
        if (active && currentAuth === authGeneration && state.status === 'restoring') {
          emit({ status: 'session-error', user: null });
        }
      }, timeoutMs);
      stopAuth = access.watchSession((user) => {
        if (!active || currentAuth !== authGeneration) return;
        clearRole();
        if (user) check({ uid: user.uid, email: user.email ?? '' });
        else emit({ status: 'signed-out', user: null });
      }, () => {
        if (!active || currentAuth !== authGeneration) return;
        clearRole();
        emit({ status: 'session-error', user: null });
      });
    },
    stop() { active = false; authGeneration++; stopAuth?.(); stopAuth = undefined; clearRole(); },
    retry() {
      if (state.user) check(state.user);
      else { controller.stop(); controller.start(); }
    },
    async logout() {
      const user = state.user;
      clearRole();
      emit({ status: 'signing-out', user });
      const current = generation;
      try { await access.logout(); }
      catch {
        // Never restore an old authorized state after a failed sign-out.
        if (active && generation === current) emit({ status: 'logout-error', user });
      }
    },
  };
  return controller;
}
