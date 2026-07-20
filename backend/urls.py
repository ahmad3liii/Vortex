from django.urls import path
from admin_api import views
from django.conf import settings
from django.conf.urls.static import static
from admin_api.views import WalletAPIView  
urlpatterns = [
    # 1. Auth & Identity
    path('api/auth/<str:action>/', views.AuthAPIView.as_view()),
    
    # 2. User Management
    path('api/users/', views.UserAPIView.as_view()), 
    path('api/users/update/<str:action>/', views.UserAPIView.as_view()), 
    path('api/users/<int:user_id>/<str:resource>/', views.UserProfileAPIView.as_view()), 
    
    # 3. Products
    path('api/products/', views.ProductAPIView.as_view()), 
    path('api/products/<int:product_id>/', views.ProductAPIView.as_view()),
    path('api/products/delete/<int:product_id>/', views.ProductAPIView.as_view()),
    path('api/products/update/<str:action>/', views.ProductAPIView.as_view()), # لدعم تغيير حالة المنتج
    
    # 4. Stations & Logistics
    path('api/stations/', views.StationAPIView.as_view()), 
    path('api/stations/<int:station_id>/', views.StationAPIView.as_view()), 
    path('api/logistics/stats/<int:station_id>/', views.LogisticsStatsAPIView.as_view()), # 👈 هذا السطر الجديد والمهم جداً
    path('api/logistics/<str:resource>/', views.LogisticsAPIView.as_view()), 
    path('api/logistics/<str:resource>/<int:station_id>/', views.LogisticsAPIView.as_view()),
    path('api/admin/stations/', views.StationAdminAPIView.as_view()),

    # 5. Chat System
    path('api/chat/messages/<int:user_id>/<int:receiver_id>/', views.ChatAPIView.as_view()), 
    path('api/chat/active/<int:user_id>/', views.ChatAPIView.as_view()), 
    path('api/chat/action/<str:action>/', views.ChatAPIView.as_view()), 
    path('api/chat/requests/<int:user_id>/', views.ChatRequestAPIView.as_view()), 
    path('api/chat/requests/action/<str:action>/', views.ChatRequestAPIView.as_view()), 
    
    # 6. Finance & Transactions
    path('api/finance/data/<str:resource>/', views.FinanceAPIView.as_view()), 
    path('api/finance/transaction/<str:action>/', views.FinanceAPIView.as_view()),
    path('api/wallet/<str:action>/', WalletAPIView.as_view(), name='wallet_actions'),
    
    # 7. Seller Requests
    path('api/seller-requests/', views.SellerRequestAPIView.as_view()), 
    
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)