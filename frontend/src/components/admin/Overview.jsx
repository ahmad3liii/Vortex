// src/components/admin/Overview.jsx
import React from 'react';
import { 
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  BarChart, Bar, Legend, PieChart, Pie, Cell
} from 'recharts';

const Overview = ({ finances, users, products, qrRequests }) => {
  // ألوان المنصة الأساسية (Deep Navy & Vibrant Purple)
  const colors = {
    bgCard: '#1a1a32',
    primary: '#6b4ce6',
    vibrantPurple: '#9c27b0',
    textLight: '#e2e8f0',
    textDim: '#94a3b8',
    success: '#10b981',
    warning: '#f59e0b'
  };

  // بيانات افتراضية توضيحية للأرباح والمبيعات الشهرية للمنصة
  const financialData = [
    { month: 'يناير', 'إجمالي العمليات': 2400, 'صافي أرباح المنصة': 400 },
    { month: 'فبراير', 'إجمالي العمليات': 1398, 'صافي أرباح المنصة': 300 },
    { month: 'مارس', 'إجمالي العمليات': 9800, 'صافي أرباح المنصة': 2000 },
    { month: 'أبريل', 'إجمالي العمليات': 3908, 'صافي أرباح المنصة': 1100 },
    { month: 'مايو', 'إجمالي العمليات': 4800, 'صافي أرباح المنصة': 1400 },
    { month: 'يونيو', 'إجمالي العمليات': 8500, 'صافي أرباح المنصة': 2300 },
  ];

  // توزيع المستخدمين حسب الأدوار (Roles) بناءً على بيانات قاعدة البيانات المحدثة
  const buyersCount = users?.filter(u => u.role === 'buyer').length || 0;
  const sellersCount = users?.filter(u => u.role === 'seller').length || 0;
  const adminsCount = users?.filter(u => u.role === 'admin').length || 0;

  const userDistData = [
    { name: 'مشترين', value: buyersCount || 5 }, // قيم احتياطية للعرض في حال كانت المصفوفة فارغة مؤقتاً
    { name: 'بائعين', value: sellersCount || 2 },
    { name: 'مدراء', value: adminsCount || 1 },
  ];

  const PIE_COLORS = [colors.primary, colors.vibrantPurple, colors.warning];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '30px' }}>
      
      {/* 1. بطاقات الإحصائيات السريعة */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '20px' }}>
        <div style={cardStyle(colors.bgCard, colors.primary)}>
          <h4 style={{ margin: '0 0 10px 0', color: colors.textDim }}>💰 السيولة المحجوزة (Escrow)</h4>
          <p style={{ fontSize: '28px', fontWeight: 'bold', margin: 0, color: '#fff' }}>{finances?.total_held || "0 $"}</p>
        </div>
        <div style={cardStyle(colors.bgCard, colors.vibrantPurple)}>
          <h4 style={{ margin: '0 0 10px 0', color: colors.textDim }}>📦 إجمالي المنتجات بالنظام</h4>
          <p style={{ fontSize: '28px', fontWeight: 'bold', margin: 0, color: '#fff' }}>{products?.length || 0}</p>
        </div>
        <div style={cardStyle(colors.bgCard, colors.success)}>
          <h4 style={{ margin: '0 0 10px 0', color: colors.textDim }}>👥 إجمالي المستخدمين</h4>
          <p style={{ fontSize: '28px', fontWeight: 'bold', margin: 0, color: '#fff' }}>{users?.length || 0}</p>
        </div>
        <div style={cardStyle(colors.bgCard, colors.warning)}>
          <h4 style={{ margin: '0 0 10px 0', color: colors.textDim }}>🛡️ طلبات الشحن والسحب المعلقة</h4>
          <p style={{ fontSize: '28px', fontWeight: 'bold', margin: 0, color: '#fff' }}>{qrRequests?.filter(r => r.status === 'Pending').length || 0}</p>
        </div>
      </div>

      {/* 2. قسم المخططات البيانية الكبرى */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(450px, 1fr))', gap: '25px' }}>
        
        {/* مخطط حركة الأرباح والسيولة */}
        <div style={chartContainerStyle(colors.bgCard)}>
          <h3 style={{ color: colors.textLight, marginTop: 0, marginBottom: '20px', fontSize: '18px' }}>📈 تحليل الأرباح والتدفقات المالية للمنصة</h3>
          <div style={{ height: '300px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={financialData} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorProfit" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor={colors.vibrantPurple} stopOpacity={0.4}/>
                    <stop offset="95%" stopColor={colors.vibrantPurple} stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#2d2d44" />
                <XAxis dataKey="month" stroke={colors.textDim} />
                <YAxis stroke={colors.textDim} />
                <Tooltip contentStyle={{ backgroundColor: '#151528', border: 'none', borderRadius: '8px', color: '#fff' }} />
                <Legend />
                <Area type="monotone" dataKey="إجمالي العمليات" stroke={colors.primary} fill="none" strokeWidth={2} />
                <Area type="monotone" dataKey="صافي أرباح المنصة" stroke={colors.vibrantPurple} fillOpacity={1} fill="url(#colorProfit)" strokeWidth={3} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* مخطط توزيع رتب المستخدمين المعزز */}
        <div style={chartContainerStyle(colors.bgCard)}>
          <h3 style={{ color: colors.textLight, marginTop: 0, marginBottom: '20px', fontSize: '18px' }}>👥 توزيع حسابات المستخدمين ومجتمع Vortex</h3>
          <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={userDistData} cx="50%" cy="50%" innerRadius={60} outerRadius={90} paddingAngle={5} dataKey="value">
                  {userDistData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={PIE_COLORS[index % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ backgroundColor: '#151528', border: 'none', borderRadius: '8px', color: '#fff' }} />
                <Legend verticalAlign="bottom" height={36}/>
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

      </div>

    </div>
  );
};

// تنسيقات مدمجة لضمان استقرار التصميم وضمان عدم تداخل الـ CSS
const cardStyle = (bg, borderLeftColor) => ({
  background: bg,
  padding: '20px',
  borderRadius: '12px',
  borderLeft: `5px solid ${borderLeftColor}`,
  boxShadow: '0 4px 15px rgba(0,0,0,0.2)',
});

const chartContainerStyle = (bg) => ({
  background: bg,
  padding: '20px',
  borderRadius: '12px',
  boxShadow: '0 4px 15px rgba(0,0,0,0.2)',
  border: '1px solid #2d2d44'
});

export default Overview;