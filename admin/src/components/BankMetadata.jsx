import { CBadge } from '@coreui/react';

export function formatDate(value) {
  const date = typeof value?.toDate === 'function' ? value.toDate() : null;
  return date && !Number.isNaN(date.getTime()) ? new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short' }).format(date) : '—';
}
export function BankStatus({ bank, active }) {
  return <span className="badges"><CBadge textBgColor={bank.status === 'draft' ? 'warning' : 'secondary'}>{bank.status === 'draft' ? 'Draft' : 'Terbit'}</CBadge>{active && <CBadge textBgColor="success">Aktif</CBadge>}</span>;
}
