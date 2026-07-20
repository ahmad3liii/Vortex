import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { MapContainer, TileLayer, Marker, Popup, Circle, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import StationDashboard from './stationDashboard';

// مكون فرعي لالتقاط النقرات على الخريطة وتسجيل الإحداثيات
function LocationSelector({ position, setPosition }) {
    useMapEvents({
        click(e) {
            setPosition([e.latlng.lat, e.latlng.lng]);
        },
    });
    return position ? <Marker position={position}><Popup>Station Location</Popup></Marker> : null;
}

function StationAdminDashboard() {
    const [stations, setStations] = useState([]);
    const [isProcessing, setIsProcessing] = useState(false);
    const [toast, setToast] = useState({ show: false, message: '', type: 'success' });
    const [isDarkMode, setIsDarkMode] = useState(true);
    const currentStyles = getStyles(isDarkMode);
    
    const [newPos, setNewPos] = useState(null);
    const [formData, setFormData] = useState({ name: '', city: '', location_details: '', coverage_radius: 50 });

    const [selectedStationId, setSelectedStationId] = useState(null);
    
    // 💡 إضافة ميزة البحث
    const [searchTerm, setSearchTerm] = useState('');

    const showToast = (message, type = 'success') => {
        setToast({ show: true, message, type });
        setTimeout(() => setToast({ show: false, message: '', type: 'success' }), 4000);
    };

    // 💡 إضافة التحديث الحي التلقائي (Polling)
    useEffect(() => {
        fetchStations();
        const intervalId = setInterval(() => {
            fetchStations(false); // جلب بصمت بدون تغيير حالة التحميل
        }, 10000); // تحديث كل 10 ثواني
        
        return () => clearInterval(intervalId); // تنظيف عند الخروج
    }, []);

    const fetchStations = async (showLoading = true) => {
        try {
            const res = await axios.get('http://127.0.0.1:8000/api/admin/stations/');
            setStations(res.data || []);
        } catch (err) {
            if(showLoading) showToast("فشل في جلب بيانات الشبكة", "error");
        }
    };

    const handleCreateStation = async (e) => {
        e.preventDefault();
        if (!newPos) return showToast("الرجاء تحديد موقع المحطة على الخريطة أولاً", "error");
        
        setIsProcessing(true);
        try {
            await axios.post('http://127.0.0.1:8000/api/admin/stations/', {
                action: 'create',
                ...formData,
                latitude: newPos[0],
                longitude: newPos[1]
            });
            showToast("تم إضافة المحطة إلى الشبكة بنجاح");
            setFormData({ name: '', city: '', location_details: '', coverage_radius: 50 });
            setNewPos(null);
            fetchStations();
        } catch (err) {
            showToast("خطأ في إنشاء المحطة", "error");
        } finally {
            setIsProcessing(false);
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm("هل أنت متأكد من إزالة هذه المحطة بشكل نهائي؟")) return;
        setIsProcessing(true);
        try {
            await axios.post('http://127.0.0.1:8000/api/admin/stations/', { action: 'delete', station_id: id });
            showToast("تمت الإزالة بنجاح");
            fetchStations();
        } catch (err) {
            showToast(err.response?.data?.error || "فشل الحذف", "error");
        } finally {
            setIsProcessing(false);
        }
    };

    const toggleStatus = async (id, currentStatus) => {
        setIsProcessing(true);
        try {
            await axios.post('http://127.0.0.1:8000/api/admin/stations/', { action: 'toggle_status', station_id: id, current_status: currentStatus });
            fetchStations();
            showToast("تم تحديث حالة المحطة");
        } catch (err) {
            showToast("خطأ في التحديث", "error");
        } finally {
            setIsProcessing(false);
        }
    };

    if (selectedStationId) {
        return (
            <StationDashboard 
                stationId={selectedStationId} 
                onBack={() => {
                    setSelectedStationId(null);
                    fetchStations(); 
                }} 
            />
        );
    }

    // 💡 تصفية المحطات بناءً على البحث
    const filteredStations = stations.filter(s => 
        s.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
        s.city.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
    <div style={currentStyles.layout} dir="rtl">
        {toast.show && <div style={{...currentStyles.toast, backgroundColor: toast.type === 'error' ? '#EF4444' : '#7C3AED'}}>{toast.message}</div>}

        <header style={currentStyles.header}>
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                <h2 style={{color: isDarkMode ? '#FFFFFF' : '#1F2937'}}>🌐 الإدارة المركزية للشبكة اللوجستية (Station Admin)</h2>
                
                <div style={{display: 'flex', alignItems: 'center', gap: '15px'}}>
                    {/* 💡 زر التبديل بين الليل والنهار */}
                    <button 
                        onClick={() => setIsDarkMode(!isDarkMode)} 
                        style={currentStyles.themeBtn}
                    >
                        {isDarkMode ? '☀️ وضع النهار' : '🌙 وضع الليل'}
                    </button>
                    
                    {/* 💡 مؤشر التحديث الحي */}
                    <div style={{display: 'flex', alignItems: 'center', gap: '8px', color: '#10B981', fontSize: '0.9rem', fontWeight: 'bold'}}>
                        <span style={currentStyles.pulseDot}></span> متصل وتحديث تلقائي
                    </div>
                </div>
            </div>
        </header>

        <div style={currentStyles.grid}>
            <div style={currentStyles.card}>
                <h3 style={currentStyles.cardTitle}>تأسيس محطة جديدة</h3>
                <form onSubmit={handleCreateStation} style={currentStyles.form}>
                    <input type="text" placeholder="اسم المحطة (مثال: مركز توزيع حلب)" required style={currentStyles.input} 
                        value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} />
                    <div style={{display: 'flex', gap: '10px'}}>
                        <input type="text" placeholder="المدينة" required style={currentStyles.input} 
                            value={formData.city} onChange={e => setFormData({...formData, city: e.target.value})} />
                        <input type="number" placeholder="نطاق التغطية (كم)" required style={currentStyles.input} 
                            value={formData.coverage_radius} onChange={e => setFormData({...formData, coverage_radius: e.target.value})} />
                    </div>
                    <input type="text" placeholder="تفاصيل العنوان" required style={currentStyles.input} 
                        value={formData.location_details} onChange={e => setFormData({...formData, location_details: e.target.value})} />
                    
                    <p style={{color: isDarkMode ? '#A78BFA' : '#6D28D9', fontSize: '0.9rem', marginBottom: '5px'}}>📍 انقر على الخريطة لتحديد الإحداثيات الجغرافية بدقة:</p>
                    <div style={currentStyles.mapWrapper}>
                        <MapContainer center={[34.8, 38.9]} zoom={6} style={{ height: '100%', width: '100%', borderRadius: '8px' }}>
                            <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                            <LocationSelector position={newPos} setPosition={setNewPos} />
                        </MapContainer>
                    </div>
                    <button type="submit" style={currentStyles.primaryBtn} disabled={isProcessing}>➕ اعتماد المحطة في الشبكة</button>
                </form>
            </div>

            <div style={currentStyles.card}>
                <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', borderBottom: `2px solid ${isDarkMode ? '#4C1D95' : '#DDD6FE'}`, paddingBottom: '10px'}}>
                    <h3 style={{margin: 0, color: currentStyles.cardTitle.color}}>الشبكة الحالية</h3>
                    <input 
                        type="text" 
                        placeholder="🔍 بحث عن محطة أو مدينة..." 
                        style={{...currentStyles.input, width: '50%', padding: '8px', marginBottom: 0}}
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>

                <div style={{...currentStyles.mapWrapper, height: '300px', marginBottom: '20px'}}>
                    <MapContainer center={[34.8, 38.9]} zoom={6} style={{ height: '100%', width: '100%', borderRadius: '8px' }}>
                        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                        {filteredStations.filter(s => s.latitude && s.longitude).map(s => (
                            <React.Fragment key={s.id}>
                                <Marker position={[s.latitude, s.longitude]}>
                                    <Popup>
                                        <strong style={{color: '#121A2F'}}>{s.name}</strong><br/>
                                        الطرود: {s.current_load} | الشاحنات: {s.active_trucks}
                                    </Popup>
                                </Marker>
                                <Circle 
                                    center={[s.latitude, s.longitude]} 
                                    radius={s.coverage_radius * 1000} 
                                    pathOptions={{ 
                                        color: s.status === 'Active' ? '#7C3AED' : '#EF4444', 
                                        fillColor: s.status === 'Active' ? '#8B5CF6' : '#F87171', 
                                        fillOpacity: 0.2 
                                    }} 
                                />
                            </React.Fragment>
                        ))}
                    </MapContainer>
                </div>

                <div className={`custom-scrollbar ${isDarkMode ? 'dark-scroll' : 'light-scroll'}`} style={currentStyles.stationList}>
                    {filteredStations.map(s => (
                        <div key={s.id} style={{...currentStyles.stationItem, cursor: 'pointer'}} onClick={() => setSelectedStationId(s.id)}>
                            <div>
                                <h4 style={{margin: '0 0 5px 0', color: isDarkMode ? '#E9D5FF' : '#4C1D95'}}>{s.name} - {s.city}</h4>
                                <p style={{margin: '0', fontSize: '0.85rem', color: isDarkMode ? '#9CA3AF' : '#4B5563'}}>
                                    📦 حمولة: {s.current_load} | 🚛 أسطول: {s.active_trucks} | 📡 تغطية: {s.coverage_radius}كم
                                </p>
                                <span style={{
                                    display: 'inline-block', marginTop: '8px', padding: '3px 8px', borderRadius: '12px', fontSize: '0.75rem',
                                    backgroundColor: s.status === 'Active' ? 'rgba(16, 185, 129, 0.2)' : 'rgba(239, 68, 68, 0.2)',
                                    color: s.status === 'Active' ? (isDarkMode ? '#34D399' : '#059669') : (isDarkMode ? '#F87171' : '#DC2626')
                                }}>
                                    {s.status === 'Active' ? '🟢 تعمل بكفاءة' : '🔴 قيد الصيانة'}
                                </span>
                            </div>
                            <div style={{display: 'flex', gap: '10px', flexDirection: 'column'}}>
                                <button onClick={(e) => { e.stopPropagation(); toggleStatus(s.id, s.status); }} style={currentStyles.secondaryBtn} disabled={isProcessing}>
                                    {s.status === 'Active' ? 'إيقاف للصيانة' : 'تفعيل'}
                                </button>
                                <button onClick={(e) => { e.stopPropagation(); handleDelete(s.id); }} style={currentStyles.dangerBtn} disabled={isProcessing}>
                                    إزالة
                                </button>
                            </div>
                        </div>
                    ))}
                    {filteredStations.length === 0 && <p style={{textAlign: 'center', color: isDarkMode ? '#9CA3AF' : '#6B7280'}}>لم يتم العثور على محطات.</p>}
                </div>
            </div>
        </div>
        
        <style>
            {`
            @keyframes pulse-green {
                0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7); }
                70% { transform: scale(1); box-shadow: 0 0 0 6px rgba(16, 185, 129, 0); }
                100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); }
            }
            .custom-scrollbar::-webkit-scrollbar { width: 6px; }
            
            /* ألوان شريط التمرير للوضع الليلي */
            .dark-scroll::-webkit-scrollbar-track { background: #121A2F; }
            .dark-scroll::-webkit-scrollbar-thumb { background: #4C1D95; border-radius: 10px; }
            .dark-scroll::-webkit-scrollbar-thumb:hover { background: #7C3AED; }

            /* ألوان شريط التمرير للوضع النهاري */
            .light-scroll::-webkit-scrollbar-track { background: #F3F4F6; }
            .light-scroll::-webkit-scrollbar-thumb { background: #C4B5FD; border-radius: 10px; }
            .light-scroll::-webkit-scrollbar-thumb:hover { background: #8B5CF6; }
            `}
        </style>
    </div>
);
}

const getStyles = (isDarkMode) => ({
    layout: { 
        backgroundColor: isDarkMode ? '#0A1128' : '#F9FAFB', 
        color: isDarkMode ? '#FFFFFF' : '#1F2937', 
        fontFamily: 'sans-serif', 
        padding: '20px', 
        minHeight: '100vh',
        transition: 'all 0.3s ease'
    },
    header: { 
        backgroundColor: isDarkMode ? '#16203B' : '#FFFFFF', 
        padding: '20px', 
        borderRadius: '8px', 
        marginBottom: '20px', 
        borderRight: '5px solid #7C3AED',
        boxShadow: isDarkMode ? 'none' : '0 2px 4px rgba(0,0,0,0.05)',
        transition: 'all 0.3s ease'
    },
    grid: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' },
    card: { 
        backgroundColor: isDarkMode ? '#121A2F' : '#FFFFFF', 
        border: `1px solid ${isDarkMode ? '#2E1065' : '#E5E7EB'}`, 
        borderRadius: '8px', 
        padding: '20px', 
        boxShadow: isDarkMode ? '0 4px 6px rgba(0,0,0,0.4)' : '0 4px 6px rgba(0,0,0,0.05)',
        transition: 'all 0.3s ease'
    },
    cardTitle: { 
        color: isDarkMode ? '#D8B4FE' : '#6D28D9', 
        borderBottom: `2px solid ${isDarkMode ? '#4C1D95' : '#DDD6FE'}`, 
        paddingBottom: '10px', 
        marginTop: '0', 
        marginBottom: '20px' 
    },
    form: { display: 'flex', flexDirection: 'column', gap: '15px' },
    input: { 
        padding: '12px', 
        borderRadius: '5px', 
        border: `1px solid ${isDarkMode ? '#4B5563' : '#D1D5DB'}`, 
        backgroundColor: isDarkMode ? '#1E293B' : '#F3F4F6', 
        color: isDarkMode ? 'white' : '#111827', 
        outline: 'none', 
        width: '100%', 
        boxSizing: 'border-box', 
        transition: '0.3s' 
    },
    mapWrapper: { 
        height: '250px', 
        border: `2px solid ${isDarkMode ? '#4C1D95' : '#8B5CF6'}`, 
        borderRadius: '8px', 
        overflow: 'hidden', 
        marginBottom: '10px' 
    },
    themeBtn: {
        backgroundColor: isDarkMode ? '#374151' : '#EDE9FE',
        color: isDarkMode ? '#F3F4F6' : '#5B21B6',
        border: `1px solid ${isDarkMode ? '#4B5563' : '#C4B5FD'}`,
        padding: '8px 16px',
        borderRadius: '20px',
        cursor: 'pointer',
        fontWeight: 'bold',
        transition: '0.3s',
        display: 'flex',
        alignItems: 'center',
        gap: '5px'
    },
    primaryBtn: { backgroundColor: '#7C3AED', color: 'white', border: 'none', padding: '12px', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold', transition: '0.3s' },
    secondaryBtn: { backgroundColor: isDarkMode ? '#4B5563' : '#E5E7EB', color: isDarkMode ? 'white' : '#374151', border: 'none', padding: '8px 12px', borderRadius: '5px', cursor: 'pointer', fontSize: '0.85rem', fontWeight: 'bold' },
    dangerBtn: { backgroundColor: '#EF4444', color: 'white', border: 'none', padding: '8px 12px', borderRadius: '5px', cursor: 'pointer', fontSize: '0.85rem', fontWeight: 'bold' },
    stationList: { display: 'flex', flexDirection: 'column', gap: '15px', maxHeight: '400px', overflowY: 'auto', paddingRight: '10px' },
    stationItem: { 
        backgroundColor: isDarkMode ? '#1E293B' : '#F9FAFB', 
        padding: '15px', 
        borderRadius: '6px', 
        borderLeft: '4px solid #7C3AED', 
        border: isDarkMode ? 'none' : '1px solid #E5E7EB',
        borderLeftWidth: '4px',
        borderLeftColor: '#7C3AED',
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center', 
        transition: '0.2s' 
    },
    toast: { position: 'fixed', top: '20px', right: '20px', color: 'white', padding: '15px 25px', borderRadius: '5px', zIndex: 1000, fontWeight: 'bold', boxShadow: '0 4px 10px rgba(0,0,0,0.5)' },
    pulseDot: { display: 'inline-block', width: '10px', height: '10px', backgroundColor: '#10B981', borderRadius: '50%', animation: 'pulse-green 2s infinite' }
});

export default StationAdminDashboard;