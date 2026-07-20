import React, { useState, useEffect } from 'react';
import axios from 'axios';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import '../css/station.css';
import TrackingMap from './TrackingMap';

delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
    iconUrl: require('leaflet/dist/images/marker-icon.png'),
    shadowUrl: require('leaflet/dist/images/marker-shadow.png')
});

function StationDashboard({ stationId, onBack }) {
    const STATION_ID = stationId || 1;

    const [warehouse, setWarehouse] = useState([]);
    const [fleet, setFleet] = useState([]);
    const [inTransitShipments, setInTransitShipments] = useState([]);
    
    const [activeTab, setActiveTab] = useState('warehouse');
    const [activeVehicleId, setActiveVehicleId] = useState(null);
    const [newProductId, setNewProductId] = useState('');
    const [forceTransfer, setForceTransfer] = useState(false);
    const [incomingVehiclePlate, setIncomingVehiclePlate] = useState('');
    
    const [isProcessing, setIsProcessing] = useState(false);
    const [toast, setToast] = useState({ show: false, message: '', type: 'success' });
    const [trackingInfo, setTrackingInfo] = useState({ isTracking: false, vehicle: null });
    const [stats, setStats] = useState({ total_shipments: 0, in_transit: 0, delivered: 0, available_trucks: 0 });
    const [isDarkMode, setIsDarkMode] = useState(true);

    // نافذة التحقق من الـ QR Code وتسليم الطرد
    const [handoverModal, setHandoverModal] = useState({ show: false, shipmentId: null, qrCodeInput: '' });

    const stationCoords = [33.5138, 36.2765];

    const showToast = (message, type = 'success') => {
        setToast({ show: true, message, type });
        setTimeout(() => setToast({ show: false, message: '', type: 'success' }), 4000);
    };

    useEffect(() => {
        fetchStationData();
        fetchShipments();
        fetchStats();
        fetchInTransitShipments();
    }, [stationId]);

    const fetchStats = async () => {
        try {
            const response = await axios.get(`http://127.0.0.1:8000/api/logistics/stats/${STATION_ID}/`);
            setStats(response.data);
        } catch (err) {
            showToast("حدث خطأ أثناء جلب إحصائيات المحطة", "error");
        }
    };

    const fetchStationData = async () => {
        try {
            const response = await axios.get(`http://127.0.0.1:8000/api/stations/${STATION_ID}/`);
            if (response.data) {
                const loadedTrucks = (response.data.trucks || []).map(t => ({
                    id: t.id,
                    name: t.plate_number,
                    type: t.type || 'truck',
                    load: t.load || [],
                    status: t.status ? t.status.toLowerCase() : 'available'
                }));
                setFleet(loadedTrucks);
                if (loadedTrucks.length > 0 && !activeVehicleId) setActiveVehicleId(loadedTrucks[0].id);
            }
        } catch (err) {
            showToast("فشل في جلب بيانات أسطول المحطة", "error");
        }
    };

    const fetchShipments = async () => {
        try {
            const res = await axios.get(`http://127.0.0.1:8000/api/logistics/shipments/${STATION_ID}/`);
            setWarehouse(res.data || []);
        } catch(err) {
            showToast("فشل في جلب طرود المستودع", "error");
        }
    };

    const fetchInTransitShipments = async () => {
        try {
            const res = await axios.get(`http://127.0.0.1:8000/api/logistics/in_transit_to/${STATION_ID}/`);
            setInTransitShipments(res.data || []);
        } catch (err) {
            setInTransitShipments([]);
        }
    };

    const addNewVehicle = async (type) => {
        const typeLabel = type === 'truck' ? 'الشاحنة' : type === 'car' ? 'السيارة' : 'المندوب';
        const plateNumber = window.prompt(`الرجاء إدخال رقم اللوحة أو معرّف ${typeLabel}:`);
        if (!plateNumber) return;

        setIsProcessing(true);
        try {
            const res = await axios.post('http://127.0.0.1:8000/api/logistics/trucks/', {
                station_id: STATION_ID,
                plate_number: plateNumber,
                type: type
            });
            setFleet([...fleet, { id: res.data.id, name: res.data.plate_number, type: type, load: [], status: 'available' }]);
            fetchStats();
            showToast(`تم إضافة ${typeLabel} [${plateNumber}] بنجاح`);
        } catch (err) {
            showToast(err.response?.data?.error || "رقم اللوحة مسجل مسبقاً أو غير صالح", "error");
        } finally {
            setIsProcessing(false);
        }
    };

    const receiveProduct = async (e) => {
        if (e) e.preventDefault();
        if (!newProductId) return;
        setIsProcessing(true);
        try {
            const response = await axios.post('http://127.0.0.1:8000/api/logistics/receive/', {
                shipment_id: newProductId,
                station_id: STATION_ID,
                force_transfer: forceTransfer 
            });
            await fetchShipments();
            fetchStats();
            setNewProductId('');
            setForceTransfer(false);
            showToast(response.data.message || `تم استلام الشحنة #${newProductId} بنجاح`);
        } catch (err) {
            if (err.response?.status === 400 && err.response?.data?.error) {
                showToast(err.response.data.error + " - يمكنك تفعيل النقل القسري لإجبار إدخالها", "error");
                setForceTransfer(true);
            } else {
                showToast("الشحنة غير موجودة في النظام الكلي", "error");
            }
        } finally {
            setIsProcessing(false);
        }
    };

    const confirmInTransitArrival = async (shipmentId) => {
        setIsProcessing(true);
        try {
            await axios.post('http://127.0.0.1:8000/api/logistics/receive/', {
                shipment_id: shipmentId,
                station_id: STATION_ID,
                force_transfer: true
            });
            setInTransitShipments(inTransitShipments.filter(s => s.id !== shipmentId));
            await fetchShipments();
            fetchStats();
            showToast(`تم إدخال الشحنة إلى مستودع المحطة.`);
        } catch (err) {
            showToast("فشل تحديث حالة الشحنة", "error");
        } finally {
            setIsProcessing(false);
        }
    };

    const receiveVehicle = async () => {
        if (!incomingVehiclePlate) return showToast("الرجاء إدخال رقم اللوحة", "error");
        setIsProcessing(true);
        try {
            const res = await axios.post('http://127.0.0.1:8000/api/logistics/arrive_truck/', {
                station_id: STATION_ID,
                plate_number: incomingVehiclePlate
            });
            await fetchStationData(); 
            await fetchShipments(); 
            fetchStats();
            setIncomingVehiclePlate('');
            showToast(res.data.message || `تم تسجيل وصول المركبة للمحطة.`);
        } catch (err) {
            showToast(err.response?.data?.error || "المركبة غير مسجلة", "error");
        } finally {
            setIsProcessing(false);
        }
    };

    const loadToActiveVehicle = async (product) => {
        const vehicle = fleet.find(v => v.id === activeVehicleId);
        if (!vehicle) return showToast("الرجاء تحديد مركبة من القائمة أولاً", "error");
        setIsProcessing(true);
        try {
            await axios.post('http://127.0.0.1:8000/api/logistics/load/', { shipment_id: product.id, truck_id: vehicle.id });
            setWarehouse(warehouse.filter(p => p.id !== product.id));
            setFleet(fleet.map(v => v.id === activeVehicleId ? { ...v, load: [...v.load, product] } : v));
            showToast(`تم تحميل الشحنة في ${vehicle.name}`);
        } catch (err) {
            showToast("فشل في عملية التحميل", "error");
        } finally {
            setIsProcessing(false);
        }
    };

    const unloadFromVehicle = async (vehicleId, product) => {
        setIsProcessing(true);
        try {
            await axios.post('http://127.0.0.1:8000/api/logistics/unload/', { shipment_id: product.id, station_id: STATION_ID });
            setFleet(fleet.map(v => v.id === vehicleId ? { ...v, load: v.load.filter(p => p.id !== product.id) } : v));
            setWarehouse([...warehouse, product]);
            showToast("تم إرجاع الطرد إلى المستودع");
        } catch (err) {
            showToast("خطأ أثناء التفريغ", "error");
        } finally {
            setIsProcessing(false);
        }
    };

    // عملية التحقق من الـ QR Code والتسليم الفعلي للزبون أو المندوب
    const handleVerifyHandover = async () => {
        if (!handoverModal.qrCodeInput) return showToast("الرجاء مسح أو كتابة الرمز للتحقق", "error");
        setIsProcessing(true);
        try {
            const res = await axios.post('http://127.0.0.1:8000/api/logistics/verify_handover/', {
                shipment_id: handoverModal.shipmentId,
                qr_token: handoverModal.qrCodeInput
            });
            
            // تحديث واجهات البيانات بعد نجاح العملية
            await fetchStationData();
            await fetchShipments();
            fetchStats();
            
            setHandoverModal({ show: false, shipmentId: null, qrCodeInput: '' });
            showToast(res.data.message || "تم التحقق وتسليم الطرد بنجاح!");
        } catch (err) {
            showToast(err.response?.data?.error || "كود الـ QR المدخل غير مطابق أو منتهي الصلاحية", "error");
        } finally {
            setIsProcessing(false);
        }
    };

    const openTrackingMap = (vehicleId) => {
        const vehicle = fleet.find(v => v.id === vehicleId);
        if (vehicle.load.length === 0) return showToast("لا يمكن تسيير مركبة فارغة", "error");
        setTrackingInfo({ isTracking: true, vehicle: vehicle, destination: null });
    };

    const activeVehicle = fleet.find(v => v.id === activeVehicleId);
    
    const groupedWarehouse = Object.values(warehouse.reduce((acc, p) => {
        const key = p.product_name || `طرد غير معروف ${p.id}`;
        if (!acc[key]) acc[key] = { ...p, quantity: 0, ids: [] };
        acc[key].quantity += 1;
        acc[key].ids.push(p.id);
        return acc;
    }, {}));

    const groupedInTransit = Object.values(inTransitShipments.reduce((acc, p) => {
        const key = p.product_name || `شحنة قادمة ${p.id}`;
        if (!acc[key]) acc[key] = { ...p, quantity: 0, ids: [] };
        acc[key].quantity += 1;
        acc[key].ids.push(p.id);
        return acc;
    }, {}));

    const activeVehicleGroupedLoad = activeVehicle ? Object.values(activeVehicle.load.reduce((acc, p) => {
        const key = p.product_name || `طرد`;
        if (!acc[key]) acc[key] = { ...p, quantity: 0, ids: [] };
        acc[key].quantity += 1;
        acc[key].ids.push(p.id);
        return acc;
    }, {})) : [];

    return (
    <>
        <style>
            {`
            :root {
                --bg-main: ${isDarkMode ? '#0A1128' : '#F3F4F6'};
                --bg-card: ${isDarkMode ? '#16203B' : '#FFFFFF'};
                --bg-section: ${isDarkMode ? '#121A2F' : '#FFFFFF'};
                --bg-item: ${isDarkMode ? '#1E293B' : '#F9FAFB'};
                --bg-item-active: ${isDarkMode ? '#2E1065' : '#EEF2F6'};
                --bg-input: ${isDarkMode ? '#0A1128' : '#FFFFFF'};
                --text-main: ${isDarkMode ? '#FFFFFF' : '#111827'};
                --text-muted: ${isDarkMode ? '#9CA3AF' : '#4B5563'};
                --text-title: ${isDarkMode ? '#D8B4FE' : '#4F46E5'};
                --text-highlight: ${isDarkMode ? '#E9D5FF' : '#1F2937'};
                --border-color: ${isDarkMode ? '#4C1D95' : '#E5E7EB'};
                --border-hover: ${isDarkMode ? '#7C3AED' : '#4F46E5'};
                --shadow: ${isDarkMode ? '0 4px 6px rgba(0, 0, 0, 0.4)' : '0 4px 6px rgba(0, 0, 0, 0.05)'};
            }
            .station-layout { background-color: var(--bg-main); color: var(--text-main); font-family: sans-serif; padding: 20px; min-height: 100vh; transition: 0.3s ease; }
            .station-header { background-color: var(--bg-card); padding: 20px; border-radius: 8px; margin-bottom: 20px; border-right: 5px solid #7C3AED; display: flex; justify-content: space-between; align-items: center; box-shadow: var(--shadow); transition: 0.3s; }
            .kpi-container { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 20px; }
            .kpi-card { background: var(--bg-card); border: 1px solid var(--border-color); padding: 15px; border-radius: 8px; display: flex; justify-content: space-between; align-items: center; transition: 0.3s; box-shadow: var(--shadow); cursor: pointer; }
            .kpi-card:hover { transform: translateY(-3px); border-color: var(--border-hover); background: rgba(124, 58, 237, 0.05); }
            .kpi-card.active-tab { border-color: #10B981; background-color: var(--bg-item-active); box-shadow: 0 0 10px rgba(16, 185, 129, 0.2); }
            .kpi-info h4 { margin: 0; color: var(--text-muted); font-size: 0.85rem; }
            .kpi-info p { margin: 5px 0 0 0; font-size: 1.6rem; font-weight: bold; color: var(--border-hover); }
            .kpi-icon { font-size: 1.8rem; background: rgba(124, 58, 237, 0.15); padding: 8px; border-radius: 6px; color: #7C3AED; }
            .main-dashboard-grid { display: grid; grid-template-columns: 1fr 2fr 1fr; gap: 20px; }
            .fleet-sidebar, .ops-center, .loading-bay-advanced { background-color: var(--bg-section); border: 1px solid var(--border-color); border-radius: 8px; padding: 15px; box-shadow: var(--shadow); transition: 0.3s; }
            h3 { color: var(--border-hover); border-bottom: 2px solid var(--border-color); padding-bottom: 10px; margin-top: 0; display: flex; justify-content: space-between; align-items: center; }
            .fleet-item { background-color: var(--bg-item); padding: 12px; margin-bottom: 8px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; transition: 0.2s; display: flex; align-items: center; justify-content: space-between; }
            .fleet-item.active { border-color: #7C3AED; background-color: var(--bg-item-active); }
            .p-card, .loaded-item { background-color: var(--bg-item); padding: 12px; border-radius: 5px; margin-bottom: 10px; display: flex; justify-content: space-between; align-items: center; border-right: 4px solid #7C3AED; box-shadow: var(--shadow); }
            input { padding: 10px; border-radius: 5px; border: 1px solid var(--border-color); background-color: var(--bg-input); color: var(--text-main); outline: none; transition: 0.2s; }
            input:focus { border-color: #10B981; }
            button { background-color: #7C3AED; color: white; border: none; padding: 10px 15px; border-radius: 5px; cursor: pointer; font-weight: bold; transition: 0.2s; }
            button:hover:not(:disabled) { background-color: #6D28D9; }
            button:disabled { opacity: 0.6; cursor: not-allowed; }
            .toast-notification { position: fixed; top: 20px; right: 20px; background-color: #10B981; color: white; padding: 15px 25px; border-radius: 5px; z-index: 4000; font-weight: bold; box-shadow: 0 4px 10px rgba(0,0,0,0.4); }
            .toast-notification.error { background-color: #EF4444; }
            .force-transfer-box { padding: 10px; border-radius: 6px; margin-top: 10px; transition: 0.3s; }
            .force-transfer-box.active { background: rgba(239, 68, 68, 0.1); border: 1px solid #EF4444; }
            `}
        </style>
        
        <div className="station-layout" dir="rtl">
            {toast.show && <div className={`toast-notification ${toast.type}`}>{toast.message}</div>}

            <header className="station-header">
                <h2>إدارة العمليات اللوجستية والمسارات (المحطة #{STATION_ID})</h2>
                <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                    <button 
                        onClick={() => setIsDarkMode(!isDarkMode)} 
                        style={{ 
                            backgroundColor: isDarkMode ? '#F59E0B' : '#1E293B', 
                            color: isDarkMode ? '#111827' : '#FFFFFF',
                            borderRadius: '20px',
                            padding: '8px 16px'
                        }}
                    >
                        {isDarkMode ? '☀️ الوضع المضيء' : '🌙 الوضع المظلم'}
                    </button>
                    
                    <button onClick={() => addNewVehicle('truck')} disabled={isProcessing}>+ شاحنة</button>
                    <button onClick={() => addNewVehicle('car')} disabled={isProcessing}>+ سيارة</button>
                    <button onClick={() => addNewVehicle('manual')} style={{ backgroundColor: '#10B981' }} disabled={isProcessing}>+ مندوب</button>
                    <button onClick={onBack} style={{ backgroundColor: '#4B5563' }}>خروج</button>
                </div>
            </header>

            <div className="kpi-container">
                <div className={`kpi-card ${activeTab === 'warehouse' ? 'active-tab' : ''}`} onClick={() => setActiveTab('warehouse')}>
                    <div className="kpi-info">
                        <h4>طرود المستودع</h4>
                        <p>{warehouse.length}</p>
                    </div>
                    <div className="kpi-icon">📦</div>
                </div>
                
                <div className={`kpi-card ${activeTab === 'in_transit' ? 'active-tab' : ''}`} onClick={() => setActiveTab('in_transit')}>
                    <div className="kpi-info">
                        <h4>شحنات قادمة</h4>
                        <p>{inTransitShipments.length || stats.in_transit}</p>
                    </div>
                    <div className="kpi-icon">🚚</div>
                </div>

                <div className={`kpi-card ${activeTab === 'fleet' ? 'active-tab' : ''}`} onClick={() => setActiveTab('fleet')}>
                    <div className="kpi-info">
                        <h4>أسطول المحطة</h4>
                        <p>{fleet.length}</p>
                    </div>
                    <div className="kpi-icon">🚗</div>
                </div>

                <div className="kpi-card" style={{ cursor: 'default' }}>
                    <div className="kpi-info">
                        <h4>إجمالي العمليات</h4>
                        <p>{stats.total_shipments}</p>
                    </div>
                    <div className="kpi-icon">📋</div>
                </div>
            </div>

            <div className="main-dashboard-grid">
                <aside className="fleet-sidebar">
                    <h3>استقبال المركبات</h3>
                    <div style={{ display: 'flex', gap: '5px', marginBottom: '15px' }}>
                        <input type="text" placeholder="رقم اللوحة..." value={incomingVehiclePlate} onChange={e => setIncomingVehiclePlate(e.target.value)} style={{ width: '65%' }} disabled={isProcessing} />
                        <button onClick={receiveVehicle} style={{ padding: '5px' }} disabled={isProcessing || !incomingVehiclePlate}>تفريغ</button>
                    </div>
                    <h3>المركبات المتاحة</h3>
                    <div className="fleet-list">
                        {fleet.length === 0 && <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>لا توجد مركبات في المحطة</p>}
                        {fleet.map(v => (
                            <div key={v.id} className={`fleet-item ${activeVehicleId === v.id ? 'active' : ''}`} onClick={() => setActiveVehicleId(v.id)}>
                                <div>
                                    <span>{v.type === 'truck' ? '🚛' : v.type === 'car' ? '🚗' : '🚶‍♂️'} </span>
                                    <strong>{v.name}</strong>
                                    <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{v.load.length} طرود محملة</div>
                                </div>
                            </div>
                        ))}
                    </div>
                </aside>

                <main className="ops-center">
                    {activeTab === 'warehouse' && (
                        <section className="warehouse-section">
                            <h3>المستودع والاستلام</h3>
                            <form className="scan-box" onSubmit={receiveProduct} style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '20px', background: 'var(--bg-card)', padding: '15px', borderRadius: '8px' }}>
                                <div style={{ display: 'flex', gap: '10px' }}>
                                    <input type="number" placeholder="رقم الباركود للشحنة..." value={newProductId} onChange={e => setNewProductId(e.target.value)} style={{ flexGrow: 1 }} disabled={isProcessing} />
                                    <button type="submit" disabled={isProcessing || !newProductId}>إدخال للمستودع</button>
                                </div>
                                <div className={`force-transfer-box ${forceTransfer ? 'active' : ''}`}>
                                    <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.85rem', color: forceTransfer ? '#EF4444' : '#10B981', cursor: 'pointer', fontWeight: 'bold' }}>
                                        <input type="checkbox" checked={forceTransfer} onChange={e => setForceTransfer(e.target.checked)} disabled={isProcessing} />
                                        نقل حيازة قسري (تجاوز خطأ التكرار إذا كانت الشحنة مسجلة مسبقاً)[cite: 3]
                                    </label>
                                </div>
                            </form>

                            <div className="p-grid">
                                {groupedWarehouse.map(group => (
                                    <div key={group.ids[0]} className="p-card">
                                        <div>
                                            <strong>{group.product_name}</strong>
                                            <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginTop: '5px' }}>
                                                الكمية المتوفرة: <span style={{ fontWeight: 'bold', color: '#10B981' }}>{group.quantity}</span> طرود
                                            </div>
                                        </div>
                                        <button onClick={() => loadToActiveVehicle(warehouse.find(p => p.id === group.ids[0]))} disabled={isProcessing || !activeVehicleId}>
                                            تحميل طرد[cite: 3]
                                        </button>
                                    </div>
                                ))}
                                {warehouse.length === 0 && <p style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '20px' }}>المستودع فارغ حالياً[cite: 3]</p>}
                            </div>
                        </section>
                    )}

                    {activeTab === 'in_transit' && (
                        <section className="transit-section">
                            <h3>الشحنات المتجهة إلينا</h3>
                            <div className="transit-grid">
                                {groupedInTransit.map(group => (
                                    <div key={group.ids[0]} className="p-card" style={{ borderRightColor: '#F59E0B' }}>
                                        <div>
                                            <span style={{ color: '#F59E0B', fontSize: '0.9rem' }}>🚚 قيد النقل</span>
                                            <strong> - {group.product_name}</strong>
                                            <div style={{ fontSize: '0.85rem', marginTop: '5px' }}>
                                                العدد القادم: <strong>{group.quantity}</strong> طرود
                                            </div>
                                        </div>
                                        <button onClick={() => confirmInTransitArrival(group.ids[0])} style={{ backgroundColor: '#10B981' }} disabled={isProcessing}>
                                            تأكيد وصول
                                        </button>
                                    </div>
                                ))}
                                {inTransitShipments.length === 0 && <p style={{ textAlign: 'center', color: 'var(--text-muted)', marginTop: '20px' }}>لا توجد شحنات قيد النقل لهذه المحطة حالياً.[cite: 3]</p>}
                            </div>
                        </section>
                    )}

                    {activeTab === 'fleet' && (
                        <section className="fleet-status-section">
                            <h3>حالة الأسطول والعمليات</h3>
                            <div style={{ background: 'var(--bg-card)', padding: '20px', borderRadius: '8px', lineHeight: '1.8' }}>
                                <p>المركبات المتاحة في المحطة: <strong>{fleet.length}</strong></p>
                                <p>إجمالي الطرود المحملة حالياً: <strong>{fleet.reduce((acc, v) => acc + v.load.length, 0)}</strong></p>
                                <hr style={{ borderColor: 'var(--border-color)', margin: '15px 0' }} />
                                <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>يمكنك إرسال المركبات للتسليم المباشر أو ترحيلها إلى محطات أخرى عبر قائمة الشحن الجانبية.[cite: 3]</p>
                            </div>
                        </section>
                    )}
                </main>

                <section className="loading-bay-advanced">
                    <h3>منطقة التحميل والتحقق</h3>
                    {activeVehicle ? (
                        <div className="active-vehicle-card">
                            <h4 style={{ marginBottom: '15px' }}>جاري التحميل: <span style={{ color: '#7C3AED' }}>{activeVehicle.name}</span>[cite: 3]</h4>
                            
                            <div className="loaded-items" style={{ margin: '15px 0', maxHeight: '350px', overflowY: 'auto' }}>
                                {activeVehicleGroupedLoad.map(group => {
                                    const actualItem = activeVehicle.load.find(p => p.id === group.ids[0]);
                                    return (
                                        <div key={group.ids[0]} className="loaded-item" style={{ borderRightColor: '#10B981', display: 'flex', flexDirection: 'column', gap: '8px', alignItems: 'stretch' }}>
                                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                <span>{group.product_name} <strong style={{color: '#7C3AED'}}>(x{group.quantity})</strong></span>
                                                <button onClick={() => unloadFromVehicle(activeVehicle.id, actualItem)} style={{ backgroundColor: '#EF4444', padding: '5px 10px', fontSize: '0.8rem' }} disabled={isProcessing}>
                                                    تفريغ طرد[cite: 3]
                                                </button>
                                            </div>
                                            
                                            {/* زر تسليم الشحنة الفوري عبر الـ QR Code عند الوصول للزبون */}
                                            <button 
                                                onClick={() => setHandoverModal({ show: true, shipmentId: actualItem.id, qrCodeInput: '' })}
                                                style={{ backgroundColor: '#0284C7', padding: '6px', fontSize: '0.8rem', color: 'white', width: '100%', borderRadius: '4px' }}
                                            >
                                                تسليم فوري (مسح QR زبون) 🔍📲
                                            </button>
                                        </div>
                                    );
                                })}
                                {activeVehicle.load.length === 0 && <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', textAlign: 'center', padding: '20px 0' }}>المركبة فارغة، جاهزة للتحميل[cite: 3]</p>}
                            </div>

                            <button onClick={() => openTrackingMap(activeVehicle.id)} disabled={activeVehicle.load.length === 0 || isProcessing} style={{ width: '100%', backgroundColor: '#10B981', padding: '12px' }}>
                                رسم مسار الرحلة وتسييرها ➔
                            </button>
                        </div>
                    ) : (
                        <p style={{ color: 'var(--text-muted)', textAlign: 'center', marginTop: '30px' }}>حدد مركبة من القائمة الجانبية لتعبئتها[cite: 3]</p>
                    )}
                </section>
            </div>

            {/* نافذة خريطة تتبع المسارات ورسم الاتجاهات المتعددة */}
            {trackingInfo.isTracking && (
                <div className="tracking-overlay" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.8)', zIndex: 5000, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                    <div className="tracking-modal" style={{ width: '85%', height: '85%', background: 'var(--bg-card)', borderRadius: '10px', overflow: 'hidden', position: 'relative' }}>
                        <button onClick={() => setTrackingInfo({ isTracking: false, vehicle: null, destination: null })} style={{ position: 'absolute', top: '10px', left: '10px', zIndex: 5001, background: '#EF4444' }}>إلغاء النافذة[cite: 3]</button>
                        <TrackingMap 
                            vehicle={trackingInfo.vehicle} 
                            stationCoords={stationCoords} 
                            stationId={STATION_ID}
                            onClose={(targetStationId) => {
                                setFleet(fleet.filter(v => v.id !== trackingInfo.vehicle.id));
                                if (activeVehicleId === trackingInfo.vehicle.id) setActiveVehicleId(null);
                                fetchShipments();
                                fetchStats();
                                setTrackingInfo({ isTracking: false, vehicle: null, destination: null });
                            }}
                        />
                    </div>
                </div>
            )}

            {/* نافذة محاكاة مسح الـ QR Code للتسليم المباشر */}
            {handoverModal.show && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.85)', zIndex: 6000, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                    <div style={{ width: '400px', background: 'var(--bg-card)', border: '2px solid #4C1D95', borderRadius: '8px', padding: '20px', color: 'white' }}>
                        <h3 style={{ borderBottom: '1px solid #4C1D95', paddingBottom: '10px' }}>📲 محاكاة مسح QR التسليم</h3>
                        <p style={{ fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: '15px' }}>
                            يرجى توجيه الكاميرا إلى الـ QR Code الخاص بجوال الزبون/المندوب المستلم، أو قم بإدخال رمز التحقق السري الآمن يدوياً:
                        </p>
                        
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
                            <input 
                                type="text" 
                                placeholder="أدخل رمز التحقق الآمن (مثال: QR_SECURE_991)..." 
                                value={handoverModal.qrCodeInput} 
                                onChange={(e) => setHandoverModal({ ...handoverModal, qrCodeInput: e.target.value })}
                                style={{ padding: '12px', borderRadius: '6px', border: '1px solid #7C3AED', background: '#0A1128', color: 'white', textAlign: 'center', fontSize: '1.1rem', letterSpacing: '2px' }}
                            />

                            <div style={{ display: 'flex', gap: '10px' }}>
                                <button 
                                    onClick={handleVerifyHandover} 
                                    style={{ flex: 1, backgroundColor: '#10B981' }}
                                    disabled={isProcessing}
                                >
                                    {isProcessing ? 'جاري التحقق...' : 'تأكيد التسليم الفوري'}
                                </button>
                                <button 
                                    onClick={() => setHandoverModal({ show: false, shipmentId: null, qrCodeInput: '' })} 
                                    style={{ flex: 1, backgroundColor: '#EF4444' }}
                                    disabled={isProcessing}
                                >
                                    إلغاء
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    </>
    );
}

export default StationDashboard;