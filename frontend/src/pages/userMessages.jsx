import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';

// أيقونة الإرسال
const SendIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
    <line x1="22" y1="2" x2="11" y2="13"></line>
    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
  </svg>
);

const UserMessages = () => {
  // تعريف الإدارة كجهة اتصال ثابتة (Admin ID = 1)[cite: 1]
  const adminChat = { id: 1, full_name: "الإدارة (Admin)" };
  
  // تهيئة الحالة مع وجود الإدارة كأول محادثة، وجعلها المحادثة النشطة افتراضياً
  const [chats, setChats] = useState([adminChat]);
  const [activeChat, setActiveChat] = useState(adminChat); 
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState("");
  const messagesEndRef = useRef(null);
  
  const userId = localStorage.getItem('user_id'); 

  // 1. جلب قائمة المحادثات النشطة للمستخدم باستخدام المسار الصحيح[cite: 4]
  useEffect(() => {
    if (userId) {
      axios.get(`http://127.0.0.1:8000/api/chat/active/${userId}/`)
        .then(res => {
          // فلترة قائمة المحادثات القادمة من السيرفر لمنع تكرار "الإدارة" في حال كان هناك محادثة سابقة معها
          const fetchedChats = res.data.filter(c => c.id !== 1);
          setChats([adminChat, ...fetchedChats]);
        })
        .catch(err => console.error("Error fetching chats:", err));
    }
  }, [userId]);

  // 2. جلب الرسائل عند اختيار محادثة معينة باستخدام المسار الصحيح[cite: 4]
  useEffect(() => {
    if (userId && activeChat) {
      axios.get(`http://127.0.0.1:8000/api/chat/messages/${userId}/${activeChat.id}/`)
        .then(res => setMessages(res.data))
        .catch(err => console.error("Error fetching messages:", err));
    }
  }, [userId, activeChat]);

  // التمرير التلقائي لأسفل المحادثة عند وصول رسالة جديدة
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // 3. دالة إرسال رسالة جديدة باستخدام المسار الصحيح[cite: 4]
  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || !activeChat) return;

    try {
      await axios.post('http://127.0.0.1:8000/api/chat/action/send/', {
        sender_id: userId,
        receiver_id: activeChat.id,
        message_text: newMessage,
        is_admin: false
      });
      
      // تحديث واجهة المحادثة محلياً لتجربة مستخدم أسرع
      setMessages([...messages, { sender_id: parseInt(userId), message_text: newMessage }]);
      setNewMessage("");
    } catch (err) {
      console.error("Error sending message:", err);
    }
  };

  const styles = {
    container: { 
      display: 'flex', 
      height: '80vh', 
      width: '100%', 
      maxWidth: '1000px', 
      margin: '0 auto',
      background: 'rgba(255, 255, 255, 0.1)', 
      backdropFilter: 'blur(15px)', 
      borderRadius: '25px', 
      border: '1px solid rgba(255, 255, 255, 0.1)', 
      overflow: 'hidden', 
      color: '#fff' 
    },
    sidebar: { 
      width: '30%', 
      borderRight: '1px solid rgba(255, 255, 255, 0.1)', 
      background: 'rgba(0, 0, 0, 0.2)',
      display: 'flex', 
      flexDirection: 'column' 
    },
    sidebarHeader: {
      padding: '20px',
      borderBottom: '1px solid rgba(255, 255, 255, 0.1)',
      fontSize: '18px',
      fontWeight: 'bold'
    },
    chatItem: (isActive) => ({
      padding: '15px 20px',
      cursor: 'pointer',
      background: isActive ? 'rgba(156, 39, 176, 0.4)' : 'transparent',
      borderBottom: '1px solid rgba(255, 255, 255, 0.05)',
      transition: 'background 0.3s'
    }),
    chatArea: { 
      width: '70%', 
      display: 'flex', 
      flexDirection: 'column' 
    },
    chatHeader: {
      padding: '20px',
      borderBottom: '1px solid rgba(255, 255, 255, 0.1)',
      background: 'rgba(0, 0, 0, 0.2)',
      fontSize: '18px',
      fontWeight: 'bold'
    },
    messagesContainer: {
      flex: 1,
      padding: '20px',
      overflowY: 'auto',
      display: 'flex',
      flexDirection: 'column',
      gap: '10px'
    },
    messageBubble: (isMine) => ({
      maxWidth: '70%',
      padding: '12px 16px',
      borderRadius: '15px',
      alignSelf: isMine ? 'flex-end' : 'flex-start',
      background: isMine ? 'linear-gradient(45deg, #9c27b0, #673ab7)' : 'rgba(255, 255, 255, 0.1)',
      border: isMine ? 'none' : '1px solid rgba(255, 255, 255, 0.2)',
      borderBottomRightRadius: isMine ? '0' : '15px',
      borderBottomLeftRadius: !isMine ? '0' : '15px',
    }),
    inputArea: {
      padding: '15px',
      borderTop: '1px solid rgba(255, 255, 255, 0.1)',
      display: 'flex',
      gap: '10px',
      background: 'rgba(0, 0, 0, 0.2)'
    },
    input: {
      flex: 1,
      background: 'rgba(255, 255, 255, 0.05)',
      border: '1px solid rgba(255, 255, 255, 0.1)',
      borderRadius: '15px',
      padding: '12px 18px',
      color: '#fff',
      outline: 'none',
      fontSize: '15px'
    },
    sendBtn: {
      background: 'linear-gradient(45deg, #9c27b0, #673ab7)',
      border: 'none',
      borderRadius: '15px',
      padding: '0 20px',
      color: '#fff',
      cursor: 'pointer',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.sidebar}>
        <div style={styles.sidebarHeader}>الرسائل</div>
        <div style={{ overflowY: 'auto', flex: 1 }}>
          {chats.map(chat => (
            <div 
              key={chat.id} 
              style={styles.chatItem(activeChat?.id === chat.id)}
              onClick={() => setActiveChat(chat)}
            >
              {chat.full_name}
            </div>
          ))}
        </div>
      </div>

      <div style={styles.chatArea}>
        {activeChat ? (
          <>
            <div style={styles.chatHeader}>{activeChat.full_name}</div>
            
            <div style={styles.messagesContainer}>
              {messages.map((msg, index) => {
                const isMine = msg.sender_id === parseInt(userId);
                return (
                  <div key={index} style={styles.messageBubble(isMine)}>
                    {msg.message_text}
                  </div>
                );
              })}
              <div ref={messagesEndRef} />
            </div>

            <form style={styles.inputArea} onSubmit={handleSendMessage}>
              <input 
                style={styles.input}
                type="text" 
                placeholder="اكتب رسالة..." 
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
              />
              <button type="submit" style={styles.sendBtn}>
                <SendIcon />
              </button>
            </form>
          </>
        ) : (
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0.5 }}>
            قم باختيار محادثة للبدء
          </div>
        )}
      </div>
    </div>
  );
};

export default UserMessages;