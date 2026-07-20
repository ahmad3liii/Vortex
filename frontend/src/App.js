import React, { useState } from 'react';
import axios from 'axios';
import { Routes, Route, useNavigate, Navigate } from 'react-router-dom';
import StationAdminDashboard from './pages/stationAdmin';
import AdminDashboard from './pages/AdminDashboard'; 
import vortexBackground from './Vortex.jpg'; 
import "./App.css";
import UserMessages from './pages/userMessages';

// Login Icons
const MailIcon = () => ( <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg> );
const LockIcon = () => ( <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg> );
const EyeIcon = () => ( <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg> );
const EyeOffIcon = () => ( <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg> );

function App() {
  return (
    <div className="vortex-bg">
      <Routes>
        <Route path="/" element={<LoginPage />} />
        <Route path="/dashboard/*" element={<MainSwitch />} />
        <Route path="/station-dashboard" element={<StationAdminDashboard />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </div>
  );
}

function MainSwitch() {
  const userType = localStorage.getItem('user_type');

  if (userType === 'admin') {
    return <AdminDashboard />;
  } else if (userType === 'buyer') {
    return <UserMessages />; 
  } else {
    alert("Unauthorized access. Please login first.");
    localStorage.clear();
    return <Navigate to="/" replace />;
  }
}

function LoginPage() {
  const [view, setView] = useState('login'); 
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();

  const handleAuth = async (e) => {
    if (e) e.preventDefault();
    try {
      if (view === 'login') {
        const res = await axios.post('http://127.0.0.1:8000/api/auth/login/', { email, password });
        if (res.data.message === 'success') {
            localStorage.setItem('user_type', res.data.user_type); 
            localStorage.setItem('full_name', res.data.full_name);
            localStorage.setItem('user_id', res.data.user_id);
            localStorage.setItem('user', JSON.stringify(res.data));
            navigate('/dashboard');
            window.location.reload(); 
        }
      } else if (view === 'signup') {
        await axios.post('http://127.0.0.1:8000/api/auth/register/', { full_name: fullName, email, password });
        alert("Account Created!"); setView('login');
      } else if (view === 'forgot') {
        await axios.post('http://127.0.0.1:8000/api/auth/forgot-password/', { email });
        alert("Reset link sent."); setView('login');
      }
    } catch (err) { 
      alert("Action Failed: " + (err.response?.data?.error || "Check Server")); 
    }
  };

  const isMobile = window.innerWidth <= 768;
  const styles = {
    container: { minHeight: isMobile ? '100dvh' : '100vh', width: '100vw', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', backgroundImage: `url(${vortexBackground})`, backgroundSize: 'cover', backgroundPosition: 'center', position: 'relative' },
    overlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(30,0,60,0.4)', zIndex: 1 },
    content: { position: 'relative', zIndex: 2, display: 'flex', flexDirection: 'column', alignItems: 'center', width: '90%', maxWidth: '380px' },
    card: { width: '100%', background: 'rgba(255, 255, 255, 0.1)', backdropFilter: 'blur(15px)', borderRadius: '25px', padding: '40px 30px', border: '1px solid rgba(255, 255, 255, 0.1)' },
    inputGroup: { display: 'flex', alignItems: 'center', background: 'rgba(255, 255, 255, 0.05)', borderRadius: '15px', marginBottom: '18px', padding: '12px 18px', border: '1px solid rgba(255, 255, 255, 0.1)' },
    input: { background: 'transparent', border: 'none', color: '#fff', outline: 'none', width: '100%', fontSize: '15px', marginLeft: '5px' },
    loginBtn: { width: '100%', background: 'linear-gradient(45deg, #9c27b0, #673ab7)', color: 'white', border: 'none', padding: '14px', borderRadius: '12px', fontSize: '16px', fontWeight: 'bold', cursor: 'pointer' }
  };

  return (
    <div style={styles.container}>
      <div style={styles.overlay}></div>
      <div style={styles.content}>
        <div style={{ textAlign: 'center', marginBottom: '30px' }}>
          <h1 style={{ fontSize: '28px', fontWeight: '600', color: '#fff' }}>Vortex Market</h1>
        </div>
        <div style={styles.card}>
          <form onSubmit={handleAuth}>
            {view === 'signup' && (
              <div style={styles.inputGroup}>
                <input style={styles.input} type="text" placeholder="Full Name" onChange={e => setFullName(e.target.value)} required />
              </div>
            )}
            <div style={styles.inputGroup}><MailIcon /><input style={styles.input} type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} required /></div>
            {view !== 'forgot' && (
              <div style={styles.inputGroup}>
                <LockIcon />
                <input style={styles.input} type={showPassword ? 'text' : 'password'} placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} required />
                <button type="button" onClick={() => setShowPassword(!showPassword)} style={{ background: 'none', border: 'none', color: '#fff', cursor: 'pointer' }}>{showPassword ? <EyeOffIcon /> : <EyeIcon />}</button>
              </div>
            )}
            <button type="submit" style={styles.loginBtn}>{view === 'login' ? 'LOGIN' : view === 'signup' ? 'SIGN UP' : 'SEND RESET LINK'}</button>
          </form>
          <div style={{ marginTop: '20px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '10px', fontSize: '14px', cursor: 'pointer' }}>
            {view === 'login' && (
              <>
                <span onClick={() => setView('forgot')}>Forgot Password?</span>
                <span onClick={() => setView('signup')}>Create New Account</span>
              </>
            )}
            {view !== 'login' && <span onClick={() => setView('login')}>Back to Login</span>}
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;