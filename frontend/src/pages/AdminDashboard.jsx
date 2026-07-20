import React, { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import Overview from '../components/admin/Overview';

function AdminDashboard() {
  const navigate = useNavigate();
  const userId = localStorage.getItem('user_id');
  const userType = localStorage.getItem('user_type');
  const [activeTab, setActiveTab] = useState('statistics'); 
  const [users, setUsers] = useState([]);
  const [qrRequests, setQrRequests] = useState([]);
  const [pendingProds, setPendingProds] = useState([]);
  const [finances, setFinances] = useState({ total_held: "0 $", pending_payouts: "0 $" });
  const [chats, setChats] = useState([]); 
  const [activeChat, setActiveChat] = useState(null); 
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState("");
  const [productFilter, setProductFilter] = useState('all');
  const [isDarkMode, setIsDarkMode] = useState(() => localStorage.getItem('theme') !== 'light');


  useEffect(() => {
    if (userType !== 'admin') navigate('/');
  }, [userType, navigate]);

  const fetchUsers = useCallback(() => {
    axios.get('http://127.0.0.1:8000/api/users/')
      .then(res => setUsers(res.data))
      .catch(err => console.error(err));
  }, []);

  const fetchFinances = useCallback(() => {
    axios.get('http://127.0.0.1:8000/api/finance/data/admin_summary/')
      .then(res => setFinances(res.data))
      .catch(err => console.error(err));
  }, []);

  const fetchQrRequests = useCallback(() => { 
    axios.get('http://127.0.0.1:8000/api/finance/data/qr_requests/')
      .then(res => setQrRequests(res.data))
      .catch(err => console.error(err));
  }, []);

  const fetchAllProducts = useCallback(() => {
    axios.get('http://127.0.0.1:8000/api/products/?status=all')
      .then(res => setPendingProds(res.data))
      .catch(err => console.error(err));
  }, []);

  const fetchMyChats = useCallback(async () => {
    if (!userId) return;
    try {
      const res = await axios.get(`http://127.0.0.1:8000/api/chat/active/${userId}/`);
      setChats(res.data);
    } catch (err) { console.error(err); }
  }, [userId]); 

  useEffect(() => {
    fetchAllProducts();
    fetchMyChats();
  }, [fetchAllProducts, fetchMyChats]);

  useEffect(() => {
    if (activeTab === 'users') fetchUsers();
    if (activeTab === 'qr') fetchQrRequests();
    if (activeTab === 'products') fetchAllProducts();
    if (activeTab === 'messages') fetchMyChats();
    fetchFinances();
  }, [activeTab, fetchUsers, fetchQrRequests, fetchAllProducts, fetchMyChats, fetchFinances]);

  const fetchMessages = useCallback(async () => {
    if (!activeChat || !userId) return;
    try {
      const res = await axios.get(`http://127.0.0.1:8000/api/chat/messages/${userId}/${activeChat.id}/`);
      setMessages(res.data);
    } catch (err) { console.error(err); }
  }, [userId, activeChat]);

  useEffect(() => {
    let interval;
    if (activeTab === 'messages' && activeChat) {
      fetchMessages();
      interval = setInterval(fetchMessages, 3000);
    }
    return () => clearInterval(interval);
  }, [activeTab, activeChat, fetchMessages]);

  const sendMessage = async () => {
    if (!newMessage.trim() || !activeChat) return;
    try {
      await axios.post('http://127.0.0.1:8000/api/chat/action/send/', {
        sender_id: userId, 
        receiver_id: activeChat.id, 
        message_text: newMessage,
        is_admin: true
      });
      setNewMessage("");
      fetchMessages();
    } catch (err) { console.error(err); }
  };

  const startChatWithUser = (user) => {
    const targetId = user.id;
    const targetName = user.name;
    const exists = chats.some(c => String(c.id) === String(targetId));
    if (!exists) setChats(prev => [{ id: targetId, full_name: targetName }, ...prev]);
    setActiveChat({ id: targetId, full_name: targetName });
    setActiveTab('messages');
  };

  const handleSendFunds = async (user) => {
    const val = prompt(`Send Funds to ${user.name}:`);
    if (val && !isNaN(val) && parseFloat(val) > 0) {
      try {
        await axios.post('http://127.0.0.1:8000/api/wallet/deposit/', { user_id: user.id, amount: parseFloat(val) });
        fetchUsers();
        alert("Done !!");
      } catch (err) { alert("Error"); }
    }
  };

  const handleWithdrawalAction = async (transactionId, actionType) => {
    if (window.confirm("Are you sure about the withdrawal ?")) {
      try {
        await axios.post('http://127.0.0.1:8000/api/wallet/withdraw_handle/', { transaction_id: transactionId, status_action: actionType });
        fetchQrRequests();
      } catch (err) { alert("Error"); }
    }
  };

  const handleRoleChange = async (id) => {
    const role = prompt("Enter the new rank (buyer, admin):");
    if (role) {
      try {
        await axios.post('http://127.0.0.1:8000/api/users/update/role/', { user_id: id, role: role.toLowerCase().trim() });
        fetchUsers();
      } catch (err) { alert("Failed to update the rank"); }
    }
  };

  const handleProductAction = async (id, status) => {
    try {
      await axios.post('http://127.0.0.1:8000/api/products/update/status/', { product_id: id, status });
      fetchAllProducts(); 
    } catch (err) { alert("Failed to Update"); }
  };

  const handleDeleteProduct = async (productId) => {
    if (window.confirm("Delete the product permanently?")) {
      try {
        await axios.delete(`http://127.0.0.1:8000/api/products/delete/${productId}/`);
        setPendingProds(prev => prev.filter(p => p.id !== productId));
      } catch (error) { alert("Error in Deleting"); }
    }
  };

  const handleReleaseFunds = async (transaction) => {
    if (window.confirm(`Unblocking the financial hold and sending the amount?`)) {
      try {
        await axios.post('http://127.0.0.1:8000/api/finance/transaction/release/', { transaction_id: transaction.id, amount: parseFloat(transaction.amount) });
        fetchQrRequests(); fetchFinances();
      } catch (err) { alert("Error!"); }
    }
  };

  useEffect(() => {
    localStorage.setItem('theme', isDarkMode ? 'dark' : 'light');
  }, [isDarkMode]);

  const colors = isDarkMode ? {
    bgMain: '#0f0f1b', bgSidebar: '#151528', bgCard: '#1a1a32', primary: '#6b4ce6', textLight: '#e2e8f0', textDim: '#94a3b8', border: '#2d2d44', danger: '#ef4444', success: '#10b981'
  } : {
    bgMain: '#f8fafc', bgSidebar: '#ffffff', bgCard: '#ffffff', primary: '#6b4ce6', textLight: '#1e293b', textDim: '#64748b', border: '#747474', danger: '#ef4444', success: '#10b981'
  };

  const tableHeaderStyle = { padding: '15px', textAlign: 'left', fontWeight: 'bold' };
  const tableCellStyle = { padding: '15px', borderBottom: `1px solid ${colors.border}` };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: colors.bgMain, color: colors.textLight, fontFamily: 'sans-serif' }}>
      
      {/*The Left Sidebar */}
      <div style={{ width: '260px', background: colors.bgSidebar, borderRight: `1px solid ${colors.border}`, display: 'flex', flexDirection: 'column' }}>
        <h2 style={{ padding: '25px', margin: 0, color: colors.primary, fontSize: '22px', borderBottom: `1px solid ${colors.border}` }}>VORTEX Admin</h2>
        <ul style={{ listStyle: 'none', padding: '15px', margin: 0, display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {[
            { id: 'statistics', label: '📊 Overview ' },
            { id: 'users', label: '👥 Users And Roles' },
            { id: 'products', label: '📦 Approving on products' },
            { id: 'messages', label: '💬 Chats' },
            { id: 'qr', label: '🛡️ QR & Wallet activity' }
          ].map(tab => (
            <li key={tab.id} onClick={() => setActiveTab(tab.id)}
                style={{
                  padding: '12px 15px', borderRadius: '8px', cursor: 'pointer', transition: '0.2s',
                  background: activeTab === tab.id ? colors.primary : 'transparent',
                  color: activeTab === tab.id ? '#fff' : colors.textDim,
                  fontWeight: activeTab === tab.id ? 'bold' : 'normal'
                }}>
              {tab.label}
            </li>
          ))}
          <li onClick={() => navigate('/station-dashboard')} style={{ marginTop: '20px', padding: '12px 15px', borderRadius: '8px', background: 'rgba(16, 185, 129, 0.1)', color: colors.success, cursor: 'pointer', fontWeight: 'bold' }}>
            🚚 Logistic Control Dashboard
          </li>
        </ul>
        <div style={{ marginTop: 'auto', padding: '15px' }}>
          <button onClick={() => setIsDarkMode(!isDarkMode)} style={{ width: '100%', padding: '10px', borderRadius: '8px', background: colors.bgMain, color: colors.textLight, border: `1px solid ${colors.border}`, cursor: 'pointer', fontWeight: 'bold' }}>
            {isDarkMode ? '☀️ Light Mode' : '🌙 Dark mode'}
          </button>
          <div onClick={() => { localStorage.clear(); navigate('/'); }} style={{ padding: '15px 0 0 0', color: colors.danger, cursor: 'pointer', fontWeight: 'bold', textAlign: 'center' }}>Log out</div>
        </div>
      </div>

      {/* Actual Content */}
      <div style={{ flex: 1, padding: '30px', overflowY: 'auto' }}>
        
        {/*Statistics & OverView*/}
        {activeTab === 'statistics' && (
          <Overview finances={finances} users={users} products={pendingProds} qrRequests={qrRequests} />
        )}
        {activeTab === 'products' && (
          <div>
            <div style={{ display: 'flex', gap: '15px', marginBottom: '25px' }}>
              <button onClick={() => setProductFilter('all')} style={{ padding: '10px 20px', borderRadius: '8px', cursor: 'pointer', background: productFilter === 'all' ? colors.primary : 'transparent', color: '#3e3d3d', border: `1px solid ${colors.border}` }}>All Products ({pendingProds.length})</button>
              <button onClick={() => setProductFilter('pending')} style={{ padding: '10px 20px', borderRadius: '8px', cursor: 'pointer', background: productFilter === 'pending' ? '#f59e0b' : 'transparent', color: '#3e3d3d', border: `1px solid ${colors.border}` }}>Pending Products ({pendingProds.filter(p => p.status === 'pending').length})</button>
            </div>
            <div style={{ background: colors.bgCard, borderRadius: '12px', overflow: 'hidden', border: `1px solid ${colors.border}` }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead style={{ background: colors.primary, color: '#fff' }}>
                  <tr><th style={tableHeaderStyle}>Image</th><th style={tableHeaderStyle}>The Product</th><th style={tableHeaderStyle}>Seller</th><th style={tableHeaderStyle}>The Price</th><th style={tableHeaderStyle}>Status</th><th style={tableHeaderStyle}>Action</th></tr>
                </thead>
                <tbody>
                  {pendingProds.filter(p => productFilter === 'all' ? true : p.status === 'pending').map(p => (
                    <tr key={p.id}>
                      <td style={tableCellStyle}><img src={p.image_url} alt="" style={{ width: '45px', height: '45px', borderRadius: '8px', objectFit: 'cover' }} /></td>
                      <td style={tableCellStyle}>{p.name}</td>
                      <td style={tableCellStyle}>{p.seller_name || "Not specified"}</td>
                      <td style={tableCellStyle}>{p.price} $</td>
                      <td style={tableCellStyle}>{p.status}</td>
                      <td style={tableCellStyle}>
                        {p.status === 'pending' ? (
                          <div style={{ display: 'flex', gap: '5px' }}>
                            <button onClick={() => handleProductAction(p.id, 'approved')} style={{ background: colors.success, color: '#fff', border: 'none', padding: '5px 10px', borderRadius: '4px', cursor: 'pointer' }}>Accept</button>
                            <button onClick={() => handleProductAction(p.id, 'rejected')} style={{ background: colors.danger, color: '#fff', border: 'none', padding: '5px 10px', borderRadius: '4px', cursor: 'pointer' }}>Reject</button>
                          </div>
                        ) : <button onClick={() => handleDeleteProduct(p.id)} style={{ color: colors.danger, background: 'none', border: 'none', cursor: 'pointer' }}>Delete</button>}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {activeTab === 'users' && (
          <div style={{ background: colors.bgCard, borderRadius: '12px', overflow: 'hidden', border: `1px solid ${colors.border}` }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead style={{ background: colors.primary, color: '#fff' }}>
                <tr><th style={tableHeaderStyle}>Name</th><th style={tableHeaderStyle}>Validity</th><th style={tableHeaderStyle}>Wallet</th><th style={tableHeaderStyle}>Address & Actions</th></tr>
              </thead>
              <tbody>
                {users.map(u => (
                  <tr key={u.id}>
                    <td style={tableCellStyle}>{u.name}</td>
                    <td style={tableCellStyle}>{u.role}</td>
                    <td style={tableCellStyle}>{u.balance} </td>
                    <td style={tableCellStyle, { display: 'flex', gap: '8px', padding: '15px' }}>
                      <button onClick={() => startChatWithUser(u)} style={{ background: '#0ea5e9', color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer' }}>💬 Chat</button>
                      <button onClick={() => handleSendFunds(u)} style={{ background: '#f59e0b', color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer' }}>💸 Send Balance</button>
                      <button onClick={() => handleRoleChange(u.id)} style={{ background: colors.primary, color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer' }}>🎭 Role</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {activeTab === 'qr' && (
          <div style={{ background: colors.bgCard, borderRadius: '12px', overflow: 'hidden', border: `1px solid ${colors.border}` }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }} dir="ltr">
              <thead style={{ background: colors.primary, color: '#fff' }}>
                <tr>
                  <th style={tableHeaderStyle}>Account / Store</th>
                  <th style={tableHeaderStyle}>Amount</th>
                  <th style={tableHeaderStyle}>Transaction Type</th>
                  <th style={tableHeaderStyle}>Status</th>
                  <th style={tableHeaderStyle}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {qrRequests.map(q => {
                  // 1. Accurately determine the transaction type
                  const txType = q.qr_type || q.type || 'Unknown';
                  const isDeposit = txType === 'Admin Deposit';
                  const isWithdrawal = txType === 'Withdrawal';
                  const isQR = !isDeposit && !isWithdrawal; // If it's neither deposit nor withdrawal, it's a QR transaction

                  // 2. Format the display text based on the type
                  let displayType = "📱 QR Scan (Payment/Purchase)";
                  let typeColor = colors.primary;

                  if (isDeposit) {
                    displayType = "📥 Admin Deposit (Top-up)";
                    typeColor = colors.success;
                  } else if (isWithdrawal) {
                    displayType = "📤 Withdrawal Request";
                    typeColor = colors.danger;
                  } else if (txType.includes('Chat')) {
                    displayType = "💬 Chat Purchase";
                  }

                  return (
                    <tr key={q.id} style={{ borderBottom: `1px solid ${colors.border}` }}>
                      <td style={tableCellStyle}><strong>{q.store || q.store_name}</strong></td>
                      <td style={tableCellStyle, {textAlign: 'left', fontWeight: 'bold' }}>{q.amount} $</td>
                      
                      <td style={tableCellStyle}>
                        <span style={{ color: typeColor, fontWeight: 'bold', fontSize: '0.9rem' }}>
                          {displayType}
                        </span>
                      </td>

                      {/* Improved Status Column (Badges) */}
                      <td style={tableCellStyle}>
                        <span style={{
                          padding: '4px 10px', 
                          borderRadius: '12px', 
                          fontSize: '0.8rem',
                          fontWeight: 'bold',
                          background: q.status === 'Pending' ? '#F59E0B' : (q.status === 'Completed' ? '#10B981' : '#EF4444'),
                          color: '#fff'
                        }}>
                          {q.status === 'Pending' ? '⏳ Pending' : (q.status === 'Completed' ? '✅ Completed' : '❌ Rejected')}
                        </span>
                      </td>

                      {/* Organized Actions Column */}
                      <td style={tableCellStyle}>
                        {q.status === 'Pending' && (
                          <div style={{ display: 'flex', gap: '8px' }}>
                            
                            {/* Withdrawal Buttons: Only show if the type is Withdrawal */}
                            {isWithdrawal && (
                              <>
                                <button onClick={() => handleWithdrawalAction(q.id, 'approve')} style={{ background: colors.success, color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' }}>
                                  Approve
                                </button>
                                <button onClick={() => handleWithdrawalAction(q.id, 'reject')} style={{ background: colors.danger, color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' }}>
                                  Reject
                                </button>
                              </>
                            )}

                            {/* Release Funds Button: Only show for QR transactions */}
                            {isQR && (
                              <button onClick={() => handleReleaseFunds(q)} style={{ background: colors.primary, color: '#fff', border: 'none', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' }}>
                                🔓 Release Funds
                              </button>
                            )}

                          </div>
                        )}
                        
                        {/* Clarification message for completed transactions */}
                        {q.status === 'Completed' && (
                          <span style={{ color: colors.textMuted, fontSize: '0.85rem' }}>No action required</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
                
                {/* Empty state when there is no data */}
                {qrRequests.length === 0 && (
                  <tr>
                    <td colSpan="5" style={{ textAlign: 'center', padding: '20px', color: colors.textMuted }}>
                      No financial transactions available.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

{activeTab === 'messages' && (
  <div style={{ display: 'flex', height: '70vh', gap: '20px' }}>
    <div style={{ width: '250px', background: colors.bgCard, borderRadius: '12px', border: `1px solid ${colors.border}`, overflowY: 'auto' }}>
      <h4 style={{ padding: '15px', margin: 0, borderBottom: `1px solid ${colors.border}`, color: colors.primary }}>Active Chats</h4>
      {chats.map(chat => {
        const isActive = String(activeChat?.id) === String(chat.id);
        return (
          <div 
            key={chat.id} 
            onClick={() => setActiveChat(chat)} 
            style={{ 
              padding: '12px 15px', 
              cursor: 'pointer', 
              background: isActive ? colors.primary : 'transparent',
              color: isActive ? '#fff' : 'inherit', 
              fontWeight: isActive ? 'bold' : 'normal',
              borderBottom: `1px solid ${colors.border}`
            }}
          >
            {chat.full_name}
          </div>
        );
      })}
    </div>
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: colors.bgCard, borderRadius: '12px', border: `1px solid ${colors.border}` }}>
      {activeChat ? (
        <>
          <div style={{ padding: '15px', background: colors.bgSidebar, fontWeight: 'bold', borderBottom: `1px solid ${colors.border}`, borderTopLeftRadius: '12px', borderTopRightRadius: '12px' }}>
            {activeChat.full_name}
          </div>
          
          <div style={{ flex: 1, overflowY: 'auto', padding: '20px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {messages.map((m, i) => {
              const isMe = String(m.sender_id) === String(userId);
              return (
                <div 
                  key={i} 
                  style={{ 
                    alignSelf: isMe ? 'flex-end' : 'flex-start', 
                    background: isMe ? colors.primary : colors.bgSidebar, 
                    color: isMe ? '#fff' : 'inherit', 
                    padding: '12px 16px', 
                    borderRadius: isMe ? '16px 16px 0 16px' : '16px 16px 16px 0', 
                    maxWidth: '70%',
                    boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
                  }}
                >
                  {m.message_text || m.message}
                </div>
              );
            })}
          </div>

          <div style={{ padding: '15px', display: 'flex', gap: '10px', borderTop: `1px solid ${colors.border}` }}>
            <input 
              type="text" 
              value={newMessage} 
              onChange={e => setNewMessage(e.target.value)} 
              onKeyDown={e => e.key === 'Enter' && sendMessage()} 
              style={{ 
                flex: 1, 
                padding: '12px', 
                borderRadius: '8px', 
                background: colors.bgMain, 
                color: 'inherit', 
                border: `1px solid ${colors.border}`,
                outline: 'none'
              }} 
              placeholder="Write Your message..." 
            />
            <button onClick={sendMessage} style={{ padding: '0 20px', background: colors.success, color: '#fff', border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold' }}>
             Send
            </button>
          </div>
        </>
      ) : (
        <div style={{ margin: 'auto', color: colors.textDim }}>Choose Chat</div>
      )}
    </div>
  </div>
)}

      </div>
    </div>
  );
}

export default AdminDashboard;