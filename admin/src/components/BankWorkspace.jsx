import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { CBadge, CBreadcrumb, CBreadcrumbItem, CButton, CContainer, CFooter, CHeader, CHeaderToggler, CNavItem, CNavLink, CNavTitle, CSidebar, CSidebarBrand, CSidebarHeader, CSidebarNav } from '@coreui/react';
import CIcon from '@coreui/icons-react';
import { cilAccountLogout, cilDescription, cilMenu, cilX } from '@coreui/icons';
import { useAdminSession } from '../auth/AdminSessionProvider.jsx';
import { getFirebaseServices } from '../lib/firebase.js';
import { createMbtiBankRepository } from '../services/mbtiBankRepository.js';
import OverviewPage from '../pages/OverviewPage.jsx';
import BankDetailPage from '../pages/BankDetailPage.jsx';
import BankEditorPage from '../pages/BankEditorPage.jsx';

export default function BankWorkspace({ target }) {
  const { session, controller } = useAdminSession();
  const repository = useMemo(() => createMbtiBankRepository(getFirebaseServices(), session.user.uid), [session.user.uid]);
  const [previewing, setPreviewing] = useState(false);
  const [selected, setSelected] = useState(null);
  const [editing, setEditing] = useState(false);
  const guard = useRef(null);
  const registerGuard = useCallback((value) => { guard.current = value; }, []);
  const open = (id, editor = false) => {
    if (guard.current && !guard.current()) return;
    setSelected(id); setEditing(editor);
  };
  useEffect(() => {
    const main = document.getElementById('main-content');
    let heading;
    const focusHeading = () => {
      const next = main?.querySelector('h1');
      if (next && next !== heading) { heading = next; next.tabIndex = -1; next.focus(); }
    };
    const observer = new MutationObserver(focusHeading);
    observer.observe(main, { childList: true, subtree: true });
    focusHeading();
    return () => observer.disconnect();
  }, [selected, editing]);
  const logout = () => { if (!guard.current || guard.current()) controller.logout(); };
  const [sidebarVisible, setSidebarVisible] = useState(undefined);
  return <div className="admin-layout"><a className="skip-link" href="#main-content">Langsung ke konten</a>
    <CSidebar className="admin-sidebar border-end" colorScheme="dark" position="fixed" visible={sidebarVisible} onVisibleChange={setSidebarVisible}>
      <CSidebarHeader className="border-bottom"><CSidebarBrand className="teencu-sidebar-brand">Teencu <small>ADMIN</small></CSidebarBrand><CButton color="light" variant="ghost" className="d-lg-none" aria-label="Tutup menu" onClick={() => setSidebarVisible(false)}><CIcon icon={cilX} /></CButton></CSidebarHeader>
      <CSidebarNav as="nav" aria-label="Navigasi admin">
        <CNavTitle>Pengelolaan konten</CNavTitle>
        <CNavItem><CNavLink as="button" type="button" active onClick={() => { open(null); setSidebarVisible(false); }}><CIcon customClassName="nav-icon" icon={cilDescription} />Bank soal MBTI</CNavLink></CNavItem>
      </CSidebarNav>
      <div className="sidebar-note">Ruang admin Teencu<br /><small>Curhat tanpa takut dihakimi.</small></div>
    </CSidebar>
    <div className="admin-wrapper">
      <CHeader className="border-bottom sticky-top"><CContainer fluid className="gap-3">
        <CHeaderToggler className="d-lg-none" aria-label="Buka menu" onClick={() => setSidebarVisible(true)}><CIcon icon={cilMenu} /></CHeaderToggler>
        <span className="fw-semibold">Pengelolaan bank soal</span>
        <div className="header-account ms-auto"><CBadge color={target === 'emulator' ? 'warning' : 'info'} textBgColor={target === 'emulator' ? 'warning' : 'info'}>{target === 'emulator' ? 'Emulator' : 'Cloud'}</CBadge><details className="account-menu"><summary>Akun</summary><span>{session.user.email || session.user.uid}</span></details><span className="account-email">{session.user.email || session.user.uid}</span><CButton color="secondary" variant="outline" size="sm" onClick={logout}><CIcon icon={cilAccountLogout} className="me-1" />Keluar</CButton></div>
      </CContainer></CHeader>
      <main tabIndex={-1} id="main-content" className="workspace"><CContainer fluid>
        <CBreadcrumb><CBreadcrumbItem>Admin</CBreadcrumbItem><CBreadcrumbItem active={!selected && !editing}>{(selected || editing) ? <button className="breadcrumb-button" onClick={() => open(null)}>Bank soal</button> : 'Bank soal'}</CBreadcrumbItem>{(selected || editing) && <CBreadcrumbItem active>{previewing ? 'Pratinjau tes' : editing ? 'Editor draft' : 'Detail paket'}</CBreadcrumbItem>}</CBreadcrumb>
        {editing ? <BankEditorPage key={selected || 'new-draft'} id={selected} repository={repository} onPreviewChange={setPreviewing} registerGuard={registerGuard} onBack={() => open(selected)} onCreated={(id) => { setSelected(id); setEditing(false); }} />
          : selected ? <BankDetailPage key={selected} id={selected} repository={repository} onPreviewChange={setPreviewing} registerGuard={registerGuard} onBack={() => open(null)} onSelect={(id) => open(id)} onEdit={() => open(selected, true)} />
          : <OverviewPage repository={repository} onSelect={(id) => open(id)} onCreate={() => open(null, true)} />}
      </CContainer></main>
      <CFooter><span>Teencu · Admin konten</span><span>UI dengan <a href="https://coreui.io/product/free-react-admin-template/" target="_blank" rel="noreferrer">CoreUI Free React</a></span></CFooter>
    </div>
  </div>;
}
