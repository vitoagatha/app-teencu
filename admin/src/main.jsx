import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import '@coreui/coreui/dist/css/coreui.min.css';
import './styles.css';

createRoot(document.getElementById('root')).render(
  <StrictMode><App /></StrictMode>,
);
