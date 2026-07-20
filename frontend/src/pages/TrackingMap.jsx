import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet';
import axios from 'axios';

// مكون إضافي لتحديث مركز الخريطة عند رسم المسار
function MapUpdater({ center }) {
    const map = useMap();
    if (center) {
        map.flyTo(center, 13);
    }
    return null;
}

const TrackingMap = ({ vehicle, stationCoords, onClose, stationId }) => {
    const [searchQuery, setSearchQuery] = useState('');
    const [searchResults, setSearchResults] = useState([]);
    const [isSearching, setIsSearching] = useState(false);
    
    // قائمة الوجهات (مسار الرحلة)
    const [destinations, setDestinations] = useState([]); 
    const [selectedType, setSelectedType] = useState('customer');
    const [destinationStationId, setDestinationStationId] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);
    
    // إحداثيات الطريق من خادم OSRM
    const [roadRouteCoords, setRoadRouteCoords] = useState([]);

    // الكيانات المتاحة من قاعدة البيانات
    const [availableEntities, setAvailableEntities] = useState([]);

    // 1. جلب البيانات الحقيقية من قاعدة البيانات (Django Backend)
    useEffect(() => {
        const fetchEntitiesFromDB = async () => {
            try {
                // يرجى تعديل هذه الروابط لتتطابق مع مسارات (URLs) الباك إند الفعلي لديك
                let endpoint = '';
                if (selectedType === 'customer') {
                    endpoint = 'http://127.0.0.1:8000/api/users/?role=customer';
                } else if (selectedType === 'delegate') {
                    endpoint = 'http://127.0.0.1:8000/api/users/?role=delegate';
                } else if (selectedType === 'station') {
                    endpoint = 'http://127.0.0.1:8000/api/stations/';
                }

                const response = await axios.get(endpoint);
                
                // توحيد شكل البيانات الواردة من السيرفر لتعمل مع الخريطة
                const mappedData = response.data.map(item => ({
                    id: item.id,
                    lat: parseFloat(item.latitude || item.lat), // تأكد من اسم الحقل في السيرفر
                    lon: parseFloat(item.longitude || item.lon),
                    name: item.name || item.username || item.station_name,
                    type: selectedType
                }));

                // تصفية الكيانات التي لا تمتلك إحداثيات صحيحة
                const validEntities = mappedData.filter(e => !isNaN(e.lat) && !isNaN(e.lon));
                setAvailableEntities(validEntities);

            } catch (error) {
                console.error("خطأ في جلب البيانات من قاعدة البيانات:", error);
                setAvailableEntities([]); // تفريغ القائمة في حال حدوث خطأ
            }
        };

        fetchEntitiesFromDB();
    }, [selectedType]);

    // البحث اليدوي عبر OpenStreetMap
    const handleSearch = async () => {
        if (!searchQuery) return;
        setIsSearching(true);
        try {
            const res = await axios.get(`https://nominatim.openstreetmap.org/search?format=json&q=${searchQuery}&limit=5`);
            setSearchResults(res.data);
        } catch (error) {
            console.error("خطأ في البحث:", error);
        } finally {
            setIsSearching(false);
        }
    };

    // حساب المسار البري
    const fetchRealRoadRoute = async (currentDestinations) => {
        if (currentDestinations.length === 0) {
            setRoadRouteCoords([]);
            return;
        }
        try {
            let coordsPath = `${stationCoords[1]},${stationCoords[0]}`;
            currentDestinations.forEach(stop => {
                coordsPath += `;${stop.lon},${stop.lat}`;
            });
            const osrmUrl = `https://router.project-osrm.org/route/v1/driving/${coordsPath}?overview=full&geometries=geojson`;
            const response = await axios.get(osrmUrl);
            if (response.data && response.data.routes && response.data.routes[0]) {
                const geometry = response.data.routes[0].geometry.coordinates;
                const formattedCoords = geometry.map(coord => [coord[1], coord[0]]);
                setRoadRouteCoords(formattedCoords);
            }
        } catch (error) {
            console.error("خطأ OSRM:", error);
            const fallback = [stationCoords, ...currentDestinations.map(d => [d.lat, d.lon])];
            setRoadRouteCoords(fallback);
        }
    };

    useEffect(() => {
        fetchRealRoadRoute(destinations);
    }, [destinations, stationCoords]);

    // إضافة نقطة للمسار
    const addStopToRoute = (lat, lon, displayName, type = selectedType) => {
        const stopLat = parseFloat(lat);
        const stopLon = parseFloat(lon);
        
        if (destinations.some(d => d.lat === stopLat && d.lon === stopLon)) {
            alert("هذا الموقع مضاف بالفعل في المسار.");
            return;
        }

        const newStop = {
            id: Date.now() + Math.random(),
            lat: stopLat,
            lon: stopLon,
            name: displayName,
            type: type
        };

        setDestinations([...destinations, newStop]);
        setSearchQuery('');
        setSearchResults([]);
    };

    const removeStop = (id) => {
        setDestinations(destinations.filter(stop => stop.id !== id));
    };

    // تعديل الدالة لتقبل المعرف حتى لو لم يتم رسم مسار
    const handleDispatch = async () => {
        if (destinations.length === 0 && !destinationStationId) {
            alert("الرجاء تحديد وجهة واحدة على الأقل أو إدخال معرف المحطة النهائية.");
            return;
        }
        setIsSubmitting(true);
        try {
            await axios.post('http://127.0.0.1:8000/api/logistics/dispatch_truck/', {
                truck_id: vehicle.id,
                destination_station_id: destinationStationId || null, 
                stops: destinations.map((d, index) => ({
                    sequence: index + 1,
                    lat: d.lat,
                    lon: d.lon,
                    name: d.name,
                    type: d.type
                }))
            });
            alert(`تم تسيير الرحلة بنجاح!`);
            onClose(destinationStationId);
        } catch (error) {
            alert("حدث خطأ أثناء إرسال تفاصيل المسار للسيرفر.");
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div style={{ display: 'flex', flexDirection: 'column', height: '100%', width: '100%', fontFamily: 'sans-serif', backgroundColor: '#0B0F19' }} dir="rtl">
            
            {/* 🛠️ شريط التحكم الجديد: استخدام Flexbox مع Flex-wrap لمنع تداخل العناصر نهائياً */}
            <div style={{ 
                padding: '15px 25px', 
                background: '#111827', 
                borderBottom: '2px solid #4F46E5', 
                display: 'flex', 
                flexWrap: 'wrap', // هذا السطر يمنع خروج العناصر عن الشاشة
                gap: '20px', 
                alignItems: 'center',
                justifyContent: 'space-between',
                zIndex: 1000,
                position: 'relative'
            }}>
                {/* معلومات الشاحنة */}
                <div style={{ color: '#F3F4F6', fontWeight: 'bold', fontSize: '1.1rem', minWidth: 'fit-content' }}>
                    تسيير الشاحنة: <span style={{ color: '#818CF8' }}>{vehicle?.name}</span>
                </div>
                
                {/* مجموعة الفلاتر والبحث */}
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '15px', flexGrow: 1, alignItems: 'center' }}>
                    <select 
                        value={selectedType} 
                        onChange={(e) => setSelectedType(e.target.value)}
                        style={{ padding: '12px 15px', borderRadius: '8px', border: '1px solid #374151', backgroundColor: '#1F2937', color: '#F3F4F6', cursor: 'pointer', outline: 'none', fontSize: '1rem', minWidth: '200px' }}
                    >
                        <option value="customer">👥 مواقع الزبائن (DB)</option>
                        <option value="delegate">🚶‍♂️ نقاط المندوبين (DB)</option>
                        <option value="station">🏢 المحطات (DB)</option>
                    </select>

                    <div style={{ position: 'relative', display: 'flex', gap: '8px', flexGrow: 1, minWidth: '250px' }}>
                        <input 
                            type="text" 
                            placeholder="بحث حر عن عنوان خارجي..." 
                            value={searchQuery} 
                            onChange={(e) => setSearchQuery(e.target.value)}
                            style={{ padding: '12px 15px', borderRadius: '8px', border: '1px solid #374151', backgroundColor: '#1F2937', color: '#F3F4F6', width: '100%', outline: 'none', fontSize: '1rem' }}
                        />
                        <button onClick={handleSearch} style={{ backgroundColor: '#4F46E5', color: 'white', border: 'none', padding: '12px 20px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold', fontSize: '1rem' }}>
                            بحث 🔍
                        </button>

                        {/* قائمة البحث مع z-index عالي لمنع الاختفاء تحت الخريطة */}
                        {searchResults.length > 0 && (
                            <div style={{ position: 'absolute', top: 'calc(100% + 5px)', right: 0, left: 0, backgroundColor: '#1F2937', border: '1px solid #4F46E5', borderRadius: '8px', zIndex: 9999, maxHeight: '250px', overflowY: 'auto', boxShadow: '0 10px 25px rgba(0,0,0,0.6)' }}>
                                {searchResults.map((result, index) => (
                                    <div 
                                        key={index} 
                                        onClick={() => addStopToRoute(result.lat, result.lon, result.display_name, 'search')}
                                        style={{ padding: '15px', color: '#E5E7EB', borderBottom: '1px solid #374151', cursor: 'pointer', fontSize: '1rem' }}
                                        onMouseEnter={(e) => e.target.style.backgroundColor = '#374151'}
                                        onMouseLeave={(e) => e.target.style.backgroundColor = 'transparent'}
                                    >
                                        ➕ {result.display_name}
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>

                {/* مجموعة الإرسال */}
                <div style={{ display: 'flex', gap: '15px', alignItems: 'center' }}>
                    <input 
                        type="number" 
                        placeholder="معرف المحطة النهائية" 
                        value={destinationStationId}
                        onChange={(e) => setDestinationStationId(e.target.value)}
                        style={{ padding: '12px 15px', borderRadius: '8px', border: '1px solid #374151', backgroundColor: '#1F2937', color: '#F3F4F6', width: '160px', outline: 'none', fontSize: '1rem' }}
                    />
                    <button 
                        onClick={handleDispatch} 
                        disabled={isSubmitting || (destinations.length === 0 && !destinationStationId)}
                        style={{ backgroundColor: '#10B981', color: 'white', border: 'none', padding: '12px 25px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold', fontSize: '1.1rem', minWidth: 'max-content' }}
                    >
                        {isSubmitting ? 'جاري الحفظ...' : 'تثبيت المسار وانطلاق ➔'}
                    </button>
                </div>
            </div>

            {/* الجسم السفلي */}
            <div style={{ display: 'flex', flexGrow: 1, position: 'relative', overflow: 'hidden' }}>
                
                {/* 🛠️ القائمة الجانبية: تم التوسيع وتكبير الكروت لتكون مريحة جداً للمستخدم */}
                <div style={{ width: '350px', background: '#111827', borderLeft: '1px solid #374151', padding: '20px', overflowY: 'auto', color: 'white', zIndex: 10 }}>
                    <h3 style={{ borderBottom: '2px solid #374151', paddingBottom: '15px', fontSize: '1.2rem', color: '#9CA3AF', marginTop: 0 }}>📋 مسار الرحلة ({destinations.length})</h3>
                    
                    {destinations.length === 0 ? (
                        <p style={{ color: '#6B7280', fontSize: '1rem', textAlign: 'center', marginTop: '30px', lineHeight: '1.6' }}>
                            المسار فارغ.<br/>قم باختيار نقاط من الخريطة بعد تحديد النوع من الأعلى.
                        </p>
                    ) : (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '15px', marginTop: '15px' }}>
                            {destinations.map((stop, index) => (
                                <div key={stop.id} style={{ background: '#1F2937', padding: '18px', borderRadius: '10px', borderRight: `5px solid ${stop.type === 'customer' ? '#10B981' : stop.type === 'delegate' ? '#F59E0B' : '#3B82F6'}`, boxShadow: '0 4px 6px rgba(0,0,0,0.1)' }}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                                        <span style={{ fontWeight: 'bold', color: '#818CF8', fontSize: '1.1rem' }}>نقطة #{index + 1}</span>
                                        <button onClick={() => removeStop(stop.id)} style={{ background: 'none', color: '#EF4444', border: 'none', cursor: 'pointer', fontSize: '1.2rem', padding: '0 5px' }}>✖</button>
                                    </div>
                                    <p style={{ fontSize: '1rem', margin: '8px 0', color: '#F3F4F6', lineHeight: '1.4', fontWeight: '500' }}>{stop.name}</p>
                                    <span style={{ fontSize: '0.85rem', padding: '4px 10px', borderRadius: '6px', background: 'rgba(255,255,255,0.08)', color: '#D1D5DB', display: 'inline-block', marginTop: '5px' }}>
                                        {stop.type === 'customer' ? '👤 موقع زبون' : stop.type === 'delegate' ? '🚶‍♂️ تسليم مندوب' : stop.type === 'station' ? '🏢 محطة شحن' : '📍 موقع خارجي'}
                                    </span>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* الخريطة */}
                <div style={{ flexGrow: 1, position: 'relative', height: '100%' }}>
                    <MapContainer center={stationCoords} zoom={13} style={{ height: '100%', width: '100%', zIndex: 1 }}>
                        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                        
                        <Marker position={stationCoords}>
                            <Popup><div style={{ textAlign: 'center', fontWeight: 'bold', fontSize: '1rem' }}>🏢 مركز الانطلاق الحالي</div></Popup>
                        </Marker>
                        
                        {/* عرض الكيانات القادمة من قاعدة البيانات الحقيقية */}
                        {availableEntities.map((entity) => {
                            const isAlreadyAdded = destinations.some(d => d.lat === entity.lat && d.lon === entity.lon);
                            return (
                                <Marker key={`entity-${entity.id}`} position={[entity.lat, entity.lon]}>
                                    <Popup>
                                        <div style={{ textAlign: 'right', fontFamily: 'sans-serif', minWidth: '180px' }}>
                                            <strong style={{ color: '#4F46E5', fontSize: '1.1rem', display: 'block', marginBottom: '5px' }}>
                                                {entity.type === 'customer' ? '👤 زبون' : entity.type === 'delegate' ? '🚶‍♂️ مندوب' : '🏢 محطة'}
                                            </strong>
                                            <div style={{ margin: '8px 0', fontSize: '1rem', color: '#374151', fontWeight: 'bold' }}>{entity.name}</div>
                                            
                                            {isAlreadyAdded ? (
                                                <span style={{ color: '#10B981', fontWeight: 'bold', fontSize: '0.9rem', display: 'block', marginTop: '10px' }}>✓ تمت الإضافة للمسار</span>
                                            ) : (
                                                <button 
                                                    onClick={() => addStopToRoute(entity.lat, entity.lon, entity.name, entity.type)}
                                                    style={{ width: '100%', backgroundColor: '#4F46E5', color: 'white', border: 'none', padding: '8px 10px', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold', fontSize: '0.9rem', marginTop: '10px' }}
                                                >
                                                    إضافة للمسار ➕
                                                </button>
                                            )}
                                        </div>
                                    </Popup>
                                </Marker>
                            );
                        })}

                        {/* نقاط مسار الرحلة الحالي */}
                        {destinations.map((stop, index) => (
                            <Marker key={`stop-${stop.id}`} position={[stop.lat, stop.lon]}>
                                <Popup>
                                    <div style={{ textAlign: 'right', fontFamily: 'sans-serif' }}>
                                        <strong style={{ color: '#10B981', fontSize: '1.1rem' }}>📍 نقطة #{index + 1}</strong>
                                        <div style={{ fontSize: '1rem', marginTop: '5px', fontWeight: 'bold' }}>{stop.name}</div>
                                    </div>
                                </Popup>
                            </Marker>
                        ))}

                        {roadRouteCoords.length > 0 && (
                            <>
                                <Polyline positions={roadRouteCoords} color="#4F46E5" weight={6} opacity={0.8} />
                                <MapUpdater center={[destinations[destinations.length - 1].lat, destinations[destinations.length - 1].lon]} />
                            </>
                        )}
                    </MapContainer>
                </div>
            </div>
        </div>
    );
};

export default TrackingMap;