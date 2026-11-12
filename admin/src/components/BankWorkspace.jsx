import { useMemo, useState } from 'react';
import { CBadge, CBreadcrumb, CBreadcrumbItem, CButton, CContainer, CFooter, CHeader, CHeaderToggler, CNavItem, CNavLink, CNavTitle, CSidebar, CSidebarBrand, CSidebarHeader, CSidebarNav } from '@coreui/react';
import CIcon from '@coreui/icons-react';
import { cilAccountLogout, cilDescription, cilMenu, cilX } from '@coreui/icons';
import { useAdminSession } from '../auth/AdminSessionProvider.jsx';
import { getFirebaseServices } from '../lib/firebase.js';
import { createMbtiBankRepository } from '../services/mbtiBankRepository.js';
import OverviewPage from '../pages/OverviewPage.jsx';
import BankDetailPage from '../pages/BankDetailPage.jsx';

export default function BankWorkspace({ target }) {
  const { session, controller } = useAdminSession();
  const repository = useMemo(() => createMbtiBankRepository(getFirebaseServices(), session.user.uid), [session.user.uid]);
  const [selected, setSelected] = useState(null);
  const [sidebarVisible, setSidebarVisible] = useState(undefined);
  return <div className="admin-layout">
    <CSidebar className="admin-sidebar border-end" colorScheme="dark" position="fixed" visible={sidebarVisible} onVisibleChange={setSidebarVisible}>
      <CSidebarHeader className="border-bottom"><CSidebarBrand className="teencu-sidebar-brand">Teencu <small>ADMIN</small></CSidebarBrand><CButton color="light" variant="ghost" className="d-lg-none" aria-label="Tutup menu" onClick={() => setSidebarVisible(false)}><CIcon icon={cilX} /></CButton></CSidebarHeader>
      <CSidebarNav as="nav" aria-label="Navigasi admin">
        <CNavTitle>Pengelolaan konten</CNavTitle>
        <CNavItem><CNavLink as="button" type="button" active onClick={() => { setSelected(null); setSidebarVisible(false); }}><CIcon customClassName="nav-icon" icon={cilDescription} />Bank soal MBTI</CNavLink></CNavItem>
      </CSidebarNav>
      <div className="sidebar-note">Ruang admin Teencu<br /><small>Curhat tanpa takut dihakimi.</small></div>
    </CSidebar>
    <div className="admin-wrapper">
      <CHeader className="border-bottom sticky-top"><CContainer fluid className="gap-3">
        <CHeaderToggler className="d-lg-none" aria-label="Buka menu" onClick={() => setSidebarVisible(true)}><CIcon icon={cilMenu} /></CHeaderToggler>
        <span className="fw-semibold">Pengelolaan bank soal</span>
        <div className="header-account ms-auto"><CBadge color={target === 'emulator' ? 'warning' : 'info'} textBgColor={target === 'emulator' ? 'warning' : 'info'}>{target === 'emulator' ? 'Emulator' : 'Cloud'}</CBadge><span className="account-email">{session.user.email || session.user.uid}</span><CButton color="secondary" variant="outline" size="sm" onClick={() => controller.logout()}><CIcon icon={cilAccountLogout} className="me-1" />Keluar</CButton></div>
      </CContainer></CHeader>
      <main id="main-content" className="workspace"><CContainer fluid>
        <CBreadcrumb><CBreadcrumbItem>Admin</CBreadcrumbItem><CBreadcrumbItem active={!selected}>{selected ? <button className="breadcrumb-button" onClick={() => setSelected(null)}>Bank soal</button> : 'Bank soal'}</CBreadcrumbItem>{selected && <CBreadcrumbItem active>Detail paket</CBreadcrumbItem>}</CBreadcrumb>
        {selected ? <BankDetailPage key={selected} id={selected} repository={repository} onBack={() => setSelected(null)} onSelect={setSelected} /> : <OverviewPage repository={repository} onSelect={setSelected} />}
      </CContainer></main>
      <CFooter><span>Teencu · Admin konten</span><span>UI dengan <a href="https://coreui.io/product/free-react-admin-template/" target="_blank" rel="noreferrer">CoreUI Free React</a></span></CFooter>
    </div>
  </div>;
}
