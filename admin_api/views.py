from django.db import connection, transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.core.files.storage import default_storage
from django.utils import timezone

# ==========================================
# 1. Core Infrastructure Layer
# ==========================================

class DB:
    @staticmethod
    def execute(sql, params=None, fetch="all"):
        with connection.cursor() as cursor:
            cursor.execute(sql, params or [])
            sql_upper = sql.strip().upper()
            
            # إذا كان الاستعلام لجلب بيانات
            if sql_upper.startswith(("SELECT", "SHOW", "DESCRIBE")):
                columns = [col[0] for col in cursor.description]
                if fetch == "one":
                    row = cursor.fetchone()
                    return dict(zip(columns, row)) if row else None
                return [dict(zip(columns, row)) for row in cursor.fetchall()]
            
            # إذا كان إدخال بيانات (INSERT)، نحتاج الـ ID الجديد فوراً
            if sql_upper.startswith("INSERT"):
                return cursor.lastrowid  # هذا هو الحل لربط الـ React بالـ Database
            
            return cursor.rowcount

class NotificationService:
    @staticmethod
    def send(user_id, message):
        DB.execute("INSERT INTO notifications (user_id, message, created_at) VALUES (%s, %s, %s)", 
                   [user_id, message, timezone.now()])

class FinanceService:
    @staticmethod
    def update_balance(user_id, amount, op='set'):
        if op == 'add': 
            sql = "UPDATE users SET balance = balance + %s WHERE user_id = %s"
        elif op == 'subtract': 
            sql = "UPDATE users SET balance = balance - %s WHERE user_id = %s"
        else: 
            sql = "UPDATE users SET balance = %s WHERE user_id = %s"
        DB.execute(sql, [amount, user_id])

# ==========================================
# 2. Authentication & Identity
# ==========================================

class AuthAPIView(APIView):
    def post(self, request, action):
        data = request.data
        if action == 'login':
            user = DB.execute("SELECT full_name, user_type, user_id FROM users WHERE email = %s AND password_hash = %s", 
                              [data.get('email'), data.get('password')], fetch="one")
            if user:
                return Response({"message": "success", "full_name": user['full_name'], "user_type": user['user_type'], "user_id": user['user_id']})
            return Response({"error": "Unauthorized"}, status=status.HTTP_401_UNAUTHORIZED)
        
        elif action == 'register':
            if DB.execute("SELECT user_id FROM users WHERE email = %s", [data.get('email')], fetch="one"):
                return Response({"error": "Email already exists"}, status=status.HTTP_400_BAD_REQUEST)
            DB.execute("INSERT INTO users (full_name, email, password_hash, user_type, balance) VALUES (%s, %s, %s, 'buyer', 0)", 
                       [data.get('full_name'), data.get('email'), data.get('password')])
            return Response({"message": "success"}, status=status.HTTP_201_CREATED)

# ==========================================
# 3. User Management & Profiles
# ==========================================

class UserAPIView(APIView):
    def get(self, request):
        users = DB.execute("""
            SELECT u.user_id as id, u.full_name as name, u.user_type as role, u.balance, 
            (SELECT qr_type FROM qrtransactions WHERE store_name = u.full_name ORDER BY id DESC LIMIT 1) as last_activity
            FROM users u
        """)
        for u in users:
            u['balance'] = f"{u['balance']} $"
            u['last_activity'] = u['last_activity'] or "None"
        return Response(users)

    def post(self, request, action=None):
        data = request.data
        if action == 'balance':
            FinanceService.update_balance(data.get('user_id'), data.get('balance'), 'set')
        elif action == 'role':
            DB.execute("UPDATE users SET user_type = %s WHERE user_id = %s", [data.get('role'), data.get('user_id')])
        elif action == 'upgrade_instant':
            DB.execute("UPDATE users SET user_type = 'seller' WHERE user_id = %s", [data.get('user_id')])
            DB.execute("INSERT INTO seller_requests (user_id, store_name, status) VALUES (%s, 'Auto-Upgraded Store', 'approved')", [data.get('user_id')])
            return Response({"message": "تم ترقية حسابك إلى بائع بنجاح!"})
        return Response({"message": "success"})

class UserProfileAPIView(APIView):
    def get(self, request, user_id, resource):
        if resource == 'addresses':
            return Response(DB.execute("SELECT id, name, details FROM addresses WHERE user_id = %s", [user_id]))
        elif resource == 'notifications':
            return Response(DB.execute("SELECT id, message, created_at as time FROM notifications WHERE user_id = %s ORDER BY created_at DESC", [user_id]))

    def post(self, request, user_id, resource):
        if resource == 'addresses':
            data = request.data
            DB.execute("INSERT INTO addresses (name, details, user_id) VALUES (%s, %s, %s)", 
                       [data.get('name', data.get('title')), data.get('details', data.get('address')), user_id])
            return Response({"message": "تمت إضافة العنوان بنجاح"}, status=status.HTTP_201_CREATED)

# ==========================================
# 4. Products & Marketplace
# ==========================================

class ProductAPIView(APIView):
    def get(self, request, product_id=None):
        if product_id:
            product = DB.execute("SELECT id, name, status FROM products WHERE id = %s", [product_id], fetch="one")
            if not product: return Response({"error": "Not found"}, status=status.HTTP_404_NOT_FOUND)
            product.update({"destination_city": "دمشق (افتراضية)", "buyer_id": 5, "type": "Local"})
            return Response(product)
        
        status_filter = request.query_params.get('status', 'approved')
        query = "SELECT p.id, p.name, p.price, p.description, p.image_url, p.status, u.full_name as seller_name, p.seller_id FROM products p LEFT JOIN users u ON p.seller_id = u.user_id"
        if status_filter != 'all':
            query += f" WHERE p.status = '{status_filter}'"
        query += " ORDER BY p.created_at DESC"
        
        products = DB.execute(query)
        for p in products:
            if p['image_url'] and not p['image_url'].startswith('http'):
                p['image_url'] = f"http://127.0.0.1:8000/media/{p['image_url']}"
        return Response(products)

    def post(self, request, action=None):
        if action == 'status':
            raw_status = request.data.get('status')
            product_id = request.data.get('product_id')

            # تنظيف القيمة وتحويلها لأحرف صغيرة
            new_status = str(raw_status).lower().strip() if raw_status else ""
            
            # قائمة الحالات المسموح بها في قاعدة البيانات (MySQL Enum)
            allowed_statuses = ['pending', 'approved', 'rejected', 'archived']

            if new_status not in allowed_statuses:
                # طباعة القيمة الخاطئة في الكونسول لمعرفتها
                print(f"⚠️ خطأ: تم استلام حالة غير مدعومة: '{raw_status}'")
                return Response({
                    "error": f"الحالة '{raw_status}' غير مدعومة",
                    "allowed": allowed_statuses
                }, status=status.HTTP_400_BAD_REQUEST)

            if not product_id:
                return Response({"error": "product_id مطلوب"}, status=status.HTTP_400_BAD_REQUEST)

            DB.execute("UPDATE products SET status = %s WHERE id = %s", [new_status, product_id])
            return Response({"message": "تم تحديث الحالة بنجاح"})
            
    def delete(self, request, product_id):
        # التأكد من وجود المنتج أولاً
        product = DB.execute("SELECT id FROM products WHERE id = %s", [product_id], fetch="one")
        
        if not product:
            return Response({"error": "المنتج غير موجود"}, status=status.HTTP_404_NOT_FOUND)

        try:
            # تنفيذ عملية الحذف
            DB.execute("DELETE FROM products WHERE id = %s", [product_id])
            return Response({"message": "تم حذف المنتج بنجاح"}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": f"فشل الحذف: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ==========================================
# 5. Stations & Logistics
# ==========================================
class StationAPIView(APIView):
    def get(self, request, station_id=None):
        if station_id:
            # تم إضافة latitude و longitude للاستعلام[cite: 14]
            station = DB.execute("SELECT id, name, city, location_details, latitude, longitude FROM stations WHERE id = %s", [station_id], fetch="one")
            if station:
                trucks = DB.execute("SELECT id, plate_number, status FROM trucks WHERE current_station_id = %s", [station_id])
                for t in trucks:
                    t['load'] = DB.execute("""
                        SELECT s.id, COALESCE(p.name, CONCAT('شحنة رقم ', s.transaction_id)) as product_name 
                        FROM shipments s LEFT JOIN products p ON s.transaction_id = p.id WHERE s.truck_id = %s
                    """, [t['id']])
                
                station['trucks'] = trucks
                station['products'] = DB.execute("SELECT id, product_name, quantity FROM station_products WHERE station_id = %s", [station_id])
                return Response(station)
            return Response({"error": f"المحطة رقم {station_id} غير موجودة في قاعدة البيانات"}, status=status.HTTP_404_NOT_FOUND)
        
        # الإصلاح الأساسي هنا لظهور المحطات على الخريطة[cite: 14]
        stations = DB.execute("SELECT id, name, city, location_details, latitude, longitude FROM stations")
        return Response(stations)

class StationAdminAPIView(APIView):
    def get(self, request):
        # جلب جميع المحطات مع حساب حمولتها الحالية برمجياً (Data Aggregation)
        stations = DB.execute("""
            SELECT s.*, 
                   (SELECT COUNT(*) FROM shipments WHERE current_station_id = s.id) as current_load,
                   (SELECT COUNT(*) FROM trucks WHERE current_station_id = s.id) as active_trucks
            FROM stations s
        """)
        return Response(stations)

    def post(self, request):
        data = request.data
        action = data.get('action')
        
        with transaction.atomic():
            if action == 'create':
                new_id = DB.execute("""
                    INSERT INTO stations (name, city, location_details, latitude, longitude, coverage_radius, status) 
                    VALUES (%s, %s, %s, %s, %s, %s, 'Active')
                """, [
                    data.get('name'), data.get('city'), data.get('location_details'), 
                    data.get('latitude'), data.get('longitude'), data.get('coverage_radius', 50)
                ], fetch="last_id")
                return Response({"message": "تم تأسيس المحطة بنجاح", "id": new_id})

            elif action == 'delete':
                station_id = data.get('station_id')
                # حماية المنطق: لا يمكن حذف محطة تحتوي على شحنات أو شاحنات
                load = DB.execute("SELECT COUNT(*) as c FROM shipments WHERE current_station_id = %s", [station_id], fetch="one")['c']
                if load > 0:
                    return Response({"error": "لا يمكن حذف محطة تحتوي على طرود حالياً. قم بإخلائها أولاً."}, status=400)
                
                DB.execute("DELETE FROM stations WHERE id = %s", [station_id])
                return Response({"message": "تم إزالة المحطة من الشبكة"})

            elif action == 'toggle_status':
                new_status = 'Maintenance' if data.get('current_status') == 'Active' else 'Active'
                DB.execute("UPDATE stations SET status = %s WHERE id = %s", [new_status, data.get('station_id')])
                return Response({"message": f"تم تغيير حالة المحطة إلى {new_status}"})
            
            return Response({"error": "إجراء غير معروف"}, status=400)

class LogisticsStatsAPIView(APIView):
    def get(self, request, station_id):
        total_shipments = DB.execute("SELECT COUNT(*) as count FROM shipments WHERE current_station_id = %s", [station_id], fetch="one")['count']
        in_transit = DB.execute("SELECT COUNT(*) as count FROM shipments WHERE current_station_id = %s AND status = 'In Transit'", [station_id], fetch="one")['count']
        delivered = DB.execute("SELECT COUNT(*) as count FROM shipments WHERE origin_station_id = %s AND status = 'Out for Delivery'", [station_id], fetch="one")['count']
        available_trucks = DB.execute("SELECT COUNT(*) as count FROM trucks WHERE current_station_id = %s AND status = 'Available'", [station_id], fetch="one")['count']
        
        return Response({
            "total_shipments": total_shipments,
            "in_transit": in_transit,
            "delivered": delivered,
            "available_trucks": available_trucks
        })

class LogisticsAPIView(APIView):
    def get(self, request, resource, station_id=None):
        if resource == 'shipments' and station_id:
            # تم التعديل لجلب الطرود التي في المحطة وليست مرتبطة بأي شاحنة
            return Response(DB.execute("""
                SELECT s.id, COALESCE(p.name, CONCAT('شحنة رقم ', s.transaction_id)) as product_name, s.status, p.buyer_id 
                FROM shipments s 
                LEFT JOIN products p ON s.transaction_id = p.id
                WHERE s.current_station_id = %s AND (s.status = 'At Origin Station' OR s.status = 'At Destination Station') AND s.truck_id IS NULL
            """, [station_id]))

    def post(self, request, *args, **kwargs):
        action = kwargs.get('resource') or kwargs.get('action')
        data = request.data
        
        with transaction.atomic():
            if action == 'trucks':
                # التصحيح 1: منع تكرار الشاحنات
                existing = DB.execute("SELECT id FROM trucks WHERE plate_number = %s", [data.get('plate_number')], fetch="one")
                if existing:
                    return Response({"error": "رقم اللوحة مسجل مسبقاً لمركبة أخرى!"}, status=status.HTTP_400_BAD_REQUEST)
                    
                truck_id = DB.execute("INSERT INTO trucks (plate_number, current_station_id, status) VALUES (%s, %s, 'Available')", 
                                    [data.get('plate_number'), data.get('station_id')], fetch="last_id")
                return Response({"id": truck_id, "plate_number": data.get('plate_number')})

            elif action == 'delete_truck':
                DB.execute("DELETE FROM trucks WHERE id = %s", [data.get('truck_id')])
                return Response({"message": "تم حذف المركبة بنجاح"})

            elif action == 'arrive_truck':
                # التصحيح 2: وصول الشاحنة مع حمولتها (بدون إفراغ قسري للمستودع)
                plate_number = data.get('plate_number')
                station_id = data.get('station_id')
                
                truck = DB.execute("SELECT id FROM trucks WHERE plate_number = %s", [plate_number], fetch="one")
                if not truck:
                    return Response({"error": "المركبة غير مسجلة في النظام"}, status=status.HTTP_404_NOT_FOUND)
                    
                # تحديث موقع الشاحنة لتصبح في المحطة الحالية
                DB.execute("UPDATE trucks SET current_station_id = %s, destination_station_id = NULL, status = 'Available' WHERE id = %s", 
                        [station_id, truck['id']])
                
                # تحديث موقع الشحنات لتنتقل للمحطة الجديدة، لكنها تبقى داخل الشاحنة (truck_id يبقى كما هو)
                DB.execute("UPDATE shipments SET current_station_id = %s, destination_station_id = NULL, status = 'At Destination Station' WHERE truck_id = %s", 
                        [station_id, truck['id']])
                        
                return Response({"message": "تم وصول المركبة بحمولتها. يمكنك الآن تحديدها من القائمة الجانبية وتفريغها."})

            # ... الأكواد القديمة المتعلقة بالـ (receive, load, unload, dispatch_truck) تبقى كما هي
            s_id = data.get('shipment_id') or data.get('product_id')
            
            if action == 'receive':
                existing = DB.execute("SELECT id FROM shipments WHERE transaction_id = %s", [s_id], fetch="one")
                if existing:
                    if data.get('force_transfer'):
                        DB.execute("UPDATE shipments SET current_station_id = %s, status = 'At Origin Station', truck_id = NULL WHERE transaction_id = %s", [data.get('station_id'), s_id])
                        return Response({"message": "تم نقل الحيازة واستلام الشحنة بنجاح."})
                    return Response({"error": "الشحنة مستلمة مسبقاً في النظام"}, status=status.HTTP_400_BAD_REQUEST)
                
                DB.execute("INSERT INTO shipments (transaction_id, origin_station_id, current_station_id, status) VALUES (%s, %s, %s, 'At Origin Station')", 
                        [s_id, data.get('station_id'), data.get('station_id')])
                return Response({"message": "تم استلام الشحنة."})
                
            elif action == 'load':
                DB.execute("UPDATE shipments SET status = 'In Transit', truck_id = %s WHERE id = %s", [data.get('truck_id'), s_id])
                return Response({"message": "تم التحميل."})
                
            elif action == 'unload':
                DB.execute("UPDATE shipments SET status = 'At Destination Station', current_station_id = %s, truck_id = NULL WHERE id = %s", [data.get('station_id'), s_id])
                return Response({"message": "تم التفريغ."})
                
            elif action == 'dispatch_truck':
                truck_id = data.get('truck_id')
                destination_id = data.get('destination_station_id') # المحطة النهائية إن وجدت
                stops = data.get('stops', []) # مصفوفة المسارات الجغرافية الجديدة
                
                if not truck_id: 
                    return Response({"error": "معرف الشاحنة مطلوب"}, status=status.HTTP_400_BAD_REQUEST)
                
                with transaction.atomic():
                    # 1. تحديث حالة المركبة لتصبح قيد الترانزيت
                    DB.execute("UPDATE trucks SET status = 'In Transit', destination_station_id = %s WHERE id = %s", [destination_id, truck_id])
                    
                    # 2. تحديث حالة الشحنات المحملة على المركبة لتصبح قيد التوصيل الفعلي (Out for Delivery)
                    DB.execute("UPDATE shipments SET status = 'Out for Delivery' WHERE truck_id = %s", [truck_id])
                    
                    # 🔥 الإضافة الجديدة: إرسال إشعار تلقائي لكل زبون لديه شحنة داخل هذه المركبة المنطلقة فوراً
                    affected_buyers = DB.execute("""
                        SELECT DISTINCT p.buyer_id, p.name as prod_name 
                        FROM shipments s
                        JOIN products p ON s.transaction_id = p.id
                        WHERE s.truck_id = %s
                    """, [truck_id], fetch="all")
                    
                    if affected_buyers:
                        for buyer in affected_buyers:
                            notification_msg = f"بشرى سارة! انطلقت الشحنة الخاصة بمنتجك '{buyer['prod_name']}' وهي الآن في طريقها إلى موقعك الفعلي لتسليمها."
                            NotificationService.send(buyer['buyer_id'], notification_msg)

                    # 3. إزالة أي مسارات قديمة لنفس المركبة لحساب المسار الجديد
                    DB.execute("DELETE FROM shipment_stops WHERE truck_id = %s", [truck_id])
                    
                    # 4. إدخال نقاط المسار الجديد (الزبائن والمندوبين والمحطات) بالترتيب الجغرافي المحدد
                    for stop in stops:
                        DB.execute("""
                            INSERT INTO shipment_stops (truck_id, sequence, latitude, longitude, name, type, status) 
                            VALUES (%s, %s, %s, %s, %s, %s, 'Pending')
                        """, [truck_id, stop.get('sequence'), stop.get('lat'), stop.get('lon'), stop.get('name'), stop.get('type')])
                        
                return Response({"message": "تم تسيير الرحلة، رسم المسارات البرية بنجاح، وإشعار كافة المستخدمين المترقبين لوصول الطرود."})
# 6. Chat & Messaging
# ==========================================

class ChatAPIView(APIView):
    def get(self, request, user_id=None, receiver_id=None):
        if receiver_id:
            messages = DB.execute("""
                SELECT sender_id, receiver_id, message_text, is_admin_reply, created_at FROM messages 
                WHERE (sender_id = %s AND receiver_id = %s) OR (sender_id = %s AND receiver_id = %s) ORDER BY created_at ASC
            """, [user_id, receiver_id, receiver_id, user_id])
            return Response(messages)
        elif user_id:
            chats = DB.execute("""
                SELECT DISTINCT u.user_id as id, u.full_name FROM users u
                WHERE u.user_id IN (
                    SELECT CASE WHEN sender_id = %s THEN receiver_id ELSE sender_id END
                    FROM chatrequests WHERE (sender_id = %s OR receiver_id = %s) AND status = 'Accepted'
                    UNION
                    SELECT CASE WHEN sender_id = %s THEN receiver_id ELSE sender_id END
                    FROM messages WHERE (sender_id = %s OR receiver_id = %s)
                ) AND u.user_id != %s
            """, [user_id, user_id, user_id, user_id, user_id, user_id, user_id])
            return Response(chats)

    def post(self, request, action):
        data = request.data
        if action == 'send':
            DB.execute("INSERT INTO messages (sender_id, receiver_id, message_text, is_admin_reply) VALUES (%s, %s, %s, %s)", 
                       [data.get('sender_id'), data.get('receiver_id'), data.get('message_text'), data.get('is_admin', False)])
        elif action == 'offer':
            DB.execute("INSERT INTO messages (sender_id, receiver_id, message_text) VALUES (%s, %s, %s)", 
                       [data.get('sender_id'), data.get('receiver_id'), f"OFFER_PRICE:{data.get('amount')}"])
        return Response({"message": "تم الإرسال بنجاح"})

class ChatRequestAPIView(APIView):
    def get(self, request, user_id):
        requests = DB.execute("""
            SELECT cr.id, cr.sender_id, u.full_name as sender_name, cr.status FROM chatrequests cr
            JOIN users u ON cr.sender_id = u.user_id WHERE cr.receiver_id = %s AND cr.status = 'Pending'
        """, [user_id])
        return Response(requests)

    def post(self, request, action):
        data = request.data
        if action == 'create':
            if DB.execute("SELECT id FROM chatrequests WHERE sender_id=%s AND receiver_id=%s AND status='Pending'", [data.get('sender_id'), data.get('receiver_id')], fetch="one"):
                return Response({"message": "طلبك قيد الانتظار بالفعل"}, status=status.HTTP_400_BAD_REQUEST)
            DB.execute("INSERT INTO chatrequests (sender_id, receiver_id, status) VALUES (%s, %s, 'Pending')", [data.get('sender_id'), data.get('receiver_id')])
        elif action == 'respond':
            DB.execute("UPDATE chatrequests SET status=%s WHERE id=%s", [data.get('status'), data.get('request_id')])
        return Response({"message": "تم معالجة الطلب بنجاح"})

# ==========================================
# 7. Finances & Transactions
# ==========================================

class FinanceAPIView(APIView):
    def get(self, request, resource):
        if resource == 'admin_summary':
            held = DB.execute("SELECT SUM(amount) as t FROM qrtransactions WHERE status = 'Pending'", fetch="one")['t'] or 0
            completed = DB.execute("SELECT SUM(amount) as t FROM qrtransactions WHERE status = 'Completed'", fetch="one")['t'] or 0
            return Response({"total_held": f"{held} $", "pending_payouts": f"{completed} $"})
        elif resource == 'qr_requests':
            return Response(DB.execute("SELECT id, store_name as store, qr_type as type, amount, status FROM qrtransactions"))

    def post(self, request, action):
        data = request.data
        if action == 'initiate':
            prod = DB.execute("SELECT price, seller_id, name FROM products WHERE id = %s", [data.get('product_id')], fetch="one")
            if not prod: return Response({"error": "Product not found"}, status=status.HTTP_404_NOT_FOUND)
            
            buyer_bal = DB.execute("SELECT balance FROM users WHERE user_id = %s", [data.get('buyer_id')], fetch="one")['balance']
            if buyer_bal < prod['price']: return Response({"error": "رصيدك غير كافٍ"}, status=status.HTTP_400_BAD_REQUEST)
            
            with transaction.atomic():
                FinanceService.update_balance(data.get('buyer_id'), prod['price'], 'subtract')
                FinanceService.update_balance(1, prod['price'], 'add') # Admin Wallet
                DB.execute("INSERT INTO qrtransactions (store_name, amount, status, qr_type, seller_id) VALUES (%s, %s, 'Pending', %s, %s)", 
                           [prod['name'], prod['price'], f"Purchase from User {data.get('buyer_id')}", prod['seller_id']])
            return Response({"message": "تم الشراء بنجاح"})

        elif action == 'chat_purchase':
            amt = float(data.get('amount'))
            bal = DB.execute("SELECT balance FROM users WHERE user_id = %s", [data.get('buyer_id')], fetch="one")
            if not bal or bal['balance'] < amt: return Response({"error": "رصيد غير كافٍ"}, status=status.HTTP_400_BAD_REQUEST)
            
            with transaction.atomic():
                FinanceService.update_balance(data.get('buyer_id'), amt, 'subtract')
                FinanceService.update_balance(data.get('seller_id'), amt, 'add')
                DB.execute("INSERT INTO qrtransactions (store_name, amount, status, qr_type) VALUES ((SELECT full_name FROM users WHERE user_id=%s), %s, 'Completed', 'Chat Offer')", [data.get('seller_id'), amt])
            return Response({"message": "تمت العملية بنجاح"})

        elif action == 'release':
            tx = DB.execute("SELECT seller_id, store_name FROM qrtransactions WHERE id = %s", [data.get('transaction_id')], fetch="one")
            if not tx or not tx['seller_id']: return Response({"error": "المعاملة غير صالحة أو البائع غير مرتبط"}, status=status.HTTP_400_BAD_REQUEST)
            
            with transaction.atomic():
                DB.execute("UPDATE qrtransactions SET status = 'Completed' WHERE id = %s", [data.get('transaction_id')])
                FinanceService.update_balance(tx['seller_id'], float(data.get('amount')), 'add')
                FinanceService.update_balance(1, float(data.get('amount')), 'subtract')
            return Response({"message": "تم تحرير الأموال"})

# ==========================================
# 8. Seller Requests
# ==========================================
class VerifyHandoverAPIView(APIView):
    def post(self, request):
        data = request.data
        shipment_id = data.get('shipment_id')
        qr_token = data.get('qr_token') # الرمز المدخل أو الممسوح ضوئياً
        
        if not shipment_id or not qr_token:
            return Response({"error": "معرف الشحنة ورمز التحقق مطلوبان"}, status=status.HTTP_400_BAD_REQUEST)
            
        # جلب تفاصيل الشحنة والتأكد من مطابقة كود الـ QR
        shipment = DB.execute("""
            SELECT s.id, s.transaction_id, s.handover_token, p.price, p.seller_id, p.buyer_id, p.name as prod_name
            FROM shipments s 
            JOIN products p ON s.transaction_id = p.id 
            WHERE s.id = %s
        """, [shipment_id], fetch="one")
        
        if not shipment:
            return Response({"error": "الشحنة غير موجودة بالنظام"}, status=status.HTTP_404_NOT_FOUND)
            
        # محاكاة المطابقة (أو المطابقة الحرفية الصارمة)
        if shipment['handover_token'] and shipment['handover_token'] != qr_token:
            return Response({"error": "فشل التحقق: كود الـ QR غير صحيح أو غير مطابق للزبون"}, status=status.HTTP_400_BAD_REQUEST)
            
        # تنفيذ عملية التسليم والتحويل المالي النهائي للبائع من المحفظة المعلقة (Escrow)
        with transaction.atomic():
            # 1. تحديث حالة الشحنة لتصبح تم التسليم بنجاح وإلغاء ارتباطها بالمركبة
            DB.execute("UPDATE shipments SET status = 'Delivered', truck_id = NULL WHERE id = %s", [shipment_id])
            
            # 2. تحرير الأموال المعلقة للبائع (أو تحديث أرصدة النظام المالي)
            # جلب معرف الحركة المالية المعلقة المرتبطة بالمنتج
            tx = DB.execute("SELECT id, amount FROM qrtransactions WHERE store_name = %s AND status = 'Pending'", [shipment['prod_name']], fetch="one")
            if tx:
                DB.execute("UPDATE qrtransactions SET status = 'Completed' WHERE id = %s", [tx['id']])
                FinanceService.update_balance(shipment['seller_id'], tx['amount'], 'add') # تضاف لمحفظة البائع
                FinanceService.update_balance(1, tx['amount'], 'subtract') # تخصم من محفظة الأدمن المعلقة
            
            # 3. إرسال إشعار تلقائي للزبون والبائع بإتمام الرحلة والتوصيل
            NotificationService.send(shipment['buyer_id'], f"تم استلام طلبك '{shipment['prod_name']}' بنجاح عبر التحقق من الـ QR.")
            NotificationService.send(shipment['seller_id'], f"تم تسليم المنتج '{shipment['prod_name']}' للزبون، وتم تحرير رصيدك المالي بنجاح.")

        return Response({"message": "تم التحقق من الرمز الأمني، تسليم المنتج، وتحرير المستحقات المالية بنجاح!"})

class SellerRequestAPIView(APIView):
    def get(self, request):
        return Response(DB.execute("SELECT request_id, store_name, status FROM seller_requests WHERE status = 'pending'"))

    def put(self, request):
        DB.execute("UPDATE seller_requests SET status = %s WHERE request_id = %s", [request.data.get('status'), request.data.get('request_id')])
        return Response({"message": "تم تحديث الحالة"})

    def post(self, request):
        DB.execute("INSERT INTO seller_requests (user_id, store_name, status) VALUES (%s, %s, 'pending')", 
                   [request.data.get('user_id'), request.data.get('store_name')])
        return Response({"message": "تم إرسال الطلب"})
    
class WalletAPIView(APIView):
    def post(self, request, action):
        data = request.data
        user_id = data.get('user_id')
        amount = float(data.get('amount', 0))

        if amount <= 0:
            return Response({"error": "المبلغ يجب أن يكون أكبر من الصفر"}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            if action == 'deposit':
                FinanceService.update_balance(user_id, amount, 'add')
                
                user = DB.execute("SELECT full_name FROM users WHERE user_id=%s", [user_id], fetch="one")
                store_name = user.get('full_name', 'Unknown') if user else 'Unknown'
                
                DB.execute("INSERT INTO qrtransactions (store_name, amount, status, qr_type, seller_id) VALUES (%s, %s, 'Completed', 'Admin Deposit', %s)", 
                           [store_name, amount, user_id])
                
                # توثيق العملية بإرسال رسالة/إشعار تلقائي إلى العميل
                notification_message = f"تمت إضافة رصيد إلى حسابك بقيمة {amount} من قبل الإدارة بنجاح."
                NotificationService.send(user_id, notification_message)
                
                return Response({"message": "تم إرسال الرصيد وتوثيق العملية برسالة للمستخدم بنجاح"})

            elif action == 'withdraw_request':
                bal = DB.execute("SELECT balance, full_name FROM users WHERE user_id=%s", [user_id], fetch="one")
                if not bal or bal['balance'] < amount:
                    return Response({"error": "رصيدك غير كافٍ لطلب هذا السحب"}, status=status.HTTP_400_BAD_REQUEST)
                
                FinanceService.update_balance(user_id, amount, 'subtract')
                DB.execute("INSERT INTO qrtransactions (store_name, amount, status, qr_type, seller_id) VALUES (%s, %s, 'Pending', 'Withdrawal', %s)", 
                           [bal['full_name'], amount, user_id])
                return Response({"message": "تم إرسال طلب السحب للإدارة وسيتم التواصل معك"})

            elif action == 'withdraw_handle':
                tx_id = data.get('transaction_id')
                status_action = data.get('status_action')
                
                tx = DB.execute("SELECT seller_id, amount, status FROM qrtransactions WHERE id=%s", [tx_id], fetch="one")

                if not tx or tx['status'] != 'Pending':
                    return Response({"error": "هذا الطلب غير صالح أو تمت معالجته مسبقاً"}, status=status.HTTP_400_BAD_REQUEST)

                if status_action == 'approve':
                    DB.execute("UPDATE qrtransactions SET status='Completed' WHERE id=%s", [tx_id])
                    return Response({"message": "تمت الموافقة على السحب. يرجى تحويل المبلغ للمستخدم خارجياً."})
                
                elif status_action == 'reject':
                    FinanceService.update_balance(tx['seller_id'], tx['amount'], 'add')
                    DB.execute("UPDATE qrtransactions SET status='Rejected' WHERE id=%s", [tx_id])
                    return Response({"message": "تم رفض طلب السحب وإعادة الرصيد إلى محفظة المستخدم"})