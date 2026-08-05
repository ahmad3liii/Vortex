class ProductModel {
  final String id;
  final String title;
  final double price;
  final String image;
  final List<String> images;
  final String description;
  final double rating;
  final String sellerPhone;
  final String sellerId;
  final String sellerName;
  final String sellerAvatar;
  final bool isApproved;
  final String category;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.images,
    required this.description,
    required this.rating,
    required this.sellerPhone,
    required this.sellerId,
    required this.sellerName,
    required this.sellerAvatar,
    this.isApproved = true,
    required this.category,
  });

  ProductModel copyWith({
    String? id,
    String? title,
    double? price,
    String? image,
    List<String>? images,
    String? description,
    double? rating,
    String? sellerPhone,
    String? sellerId,
    String? sellerName,
    String? sellerAvatar,
    bool? isApproved,
    String? category,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      image: image ?? this.image,
      images: images ?? this.images,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      isApproved: isApproved ?? this.isApproved,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'image': image,
      'images': images,
      'description': description,
      'rating': rating,
      'sellerPhone': sellerPhone,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAvatar': sellerAvatar,
      'isApproved': isApproved,
      'category': category,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    double parsePrice(dynamic price) {
      if (price == null) return 0.0;
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) return double.tryParse(price) ?? 0.0;
      return 0.0;
    }

    double parseRating(dynamic rating) {
      if (rating == null) return 4.0;
      if (rating is double) return rating;
      if (rating is int) return rating.toDouble();
      if (rating is String) return double.tryParse(rating) ?? 4.0;
      return 4.0;
    }

    String parseId(dynamic id) {
      if (id == null) return '';
      return id.toString();
    }

    String parseImageUrl(dynamic image) {
      if (image == null) return '';
      String url = image.toString();
      if (url.isEmpty) return '';
      if (url.startsWith('http')) {
        return url
            .replaceAll('localhost', '10.219.48.75')
            .replaceAll('127.0.0.1', '10.219.48.75')
            .replaceAll('192.168.4.45', '10.219.48.75');
      }
      String cleanPath = url.startsWith('/') ? url : '/$url';
      if (!cleanPath.startsWith('/media/')) {
        cleanPath = '/media$cleanPath';
      }
      return 'http://10.219.48.75:8000$cleanPath';
    }

    List<String> parseImages(dynamic images) {
      if (images == null) return [];
      if (images is List) {
        return images
            .map((e) {
              if (e is Map) {
                final imgPath = e['image']?.toString() ?? '';
                return parseImageUrl(imgPath);
              }
              return parseImageUrl(e.toString());
            })
            .where((url) => url.isNotEmpty)
            .toList();
      }
      if (images is String) {
        return [parseImageUrl(images)];
      }
      return [];
    }

    // Parse seller info - backend returns seller_id directly now
    String parseSellerId(dynamic seller) {
      if (seller == null) return '';
      if (seller is int) return seller.toString();
      if (seller is Map) {
        return parseId(seller['user_id'] ?? seller['id']);
      }
      if (seller is String) return seller;
      return '';
    }

    String parseSellerName(dynamic seller) {
      if (seller == null) return '';
      if (seller is Map) {
        return seller['full_name']?.toString() ?? '';
      }
      return '';
    }

    String parseSellerPhone(dynamic seller) {
      if (seller == null) return '';
      if (seller is Map) {
        return seller['phone']?.toString() ?? '';
      }
      return '';
    }

    String parseSellerAvatar(dynamic seller) {
      if (seller == null) return '';
      if (seller is Map) {
        final avatar = seller['avatar'] ?? seller['profile_image'];
        return parseImageUrl(avatar);
      }
      return '';
    }

    // Handle seller object from backend
    dynamic sellerData = map['seller'];

    return ProductModel(
      id: parseId(map['id'] ?? map['product_id']),
      title: map['title'] ?? map['product_name'] ?? '',
      price: parsePrice(map['price']),
      image: parseImageUrl(map['image'] ?? map['image_url']),
      images: parseImages(
        map['images'] ?? (map['image'] != null ? [map['image']] : []),
      ),
      description: map['description'] ?? '',
      rating: parseRating(map['rating']),
      sellerPhone:
          map['seller_phone']?.toString() ??
          parseSellerPhone(sellerData) ??
          map['sellerPhone'] ??
          '',
      sellerId:
          map['seller_id']?.toString() ??
          parseSellerId(sellerData) ??
          map['sellerId'] ??
          '',
      sellerName:
          map['seller_name'] ??
          parseSellerName(sellerData) ??
          map['sellerName'] ??
          '',
      sellerAvatar:
          map['seller_avatar'] ??
          parseSellerAvatar(sellerData) ??
          map['sellerAvatar'] ??
          '',
      isApproved: map['isApproved'] == true || map['status'] == 'approved',
      category: map['category'] ?? 'الكل',
    );
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final double availableBalance;
  final double pendingBalance;
  final String avatar;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.availableBalance,
    required this.pendingBalance,
    required this.avatar,
    required this.role,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? location,
    double? availableBalance,
    double? pendingBalance,
    String? avatar,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'location': location,
      'available_balance': availableBalance,
      'pending_balance': pendingBalance,
      'avatar': avatar,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      availableBalance:
          (map['available_balance'] ?? map['availableBalance'] as num?)
              ?.toDouble() ??
          0.0,
      pendingBalance:
          (map['pending_balance'] ?? map['pendingBalance'] as num?)
              ?.toDouble() ??
          0.0,
      avatar: map['avatar'] ?? '',
      role: map['role'] ?? 'buyer',
    );
  }
}

class OrderModel {
  final String id;
  final String productId;
  final String productTitle;
  final String productImage;
  final double amount;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String status;
  final String qrCodeToken;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.amount,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.status,
    required this.qrCodeToken,
    required this.createdAt,
  });

  OrderModel copyWith({
    String? id,
    String? productId,
    String? productTitle,
    String? productImage,
    double? amount,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? sellerName,
    String? status,
    String? qrCodeToken,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      amount: amount ?? this.amount,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      status: status ?? this.status,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_title': productTitle,
      'product_image': productImage,
      'amount': amount,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'status': status,
      'qr_code_token': qrCodeToken,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      productTitle: map['product_title'] ?? '',
      productImage: map['product_image'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      buyerId: map['buyer_id']?.toString() ?? '',
      buyerName: map['buyer_name'] ?? '',
      sellerId: map['seller_id']?.toString() ?? '',
      sellerName: map['seller_name'] ?? '',
      status: map['status'] ?? '',
      qrCodeToken: map['qr_code_token']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime time;
  final bool isMe;
  final double? offerAmount;
  final String? offerStatus;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.time,
    required this.isMe,
    this.offerAmount,
    this.offerStatus,
  });

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? time,
    bool? isMe,
    double? offerAmount,
    String? offerStatus,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      time: time ?? this.time,
      isMe: isMe ?? this.isMe,
      offerAmount: offerAmount ?? this.offerAmount,
      offerStatus: offerStatus ?? this.offerStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
      'time': time.toIso8601String(),
      'is_me': isMe,
      'offer_amount': offerAmount,
      'offer_status': offerStatus,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['message_id']?.toString() ?? map['id']?.toString() ?? '',
      senderId: map['sender'] ?? map['sender_id']?.toString() ?? '',
      receiverId: map['receiver'] ?? map['receiver_id']?.toString() ?? '',
      // ✅ دعم الحقلين 'content' و 'text'
      text: map['content'] ?? map['text'] ?? '',
      time:
          DateTime.tryParse(map['created_at'] ?? map['time'] ?? '') ??
          DateTime.now(),
      isMe: map['is_me'] == true,
      offerAmount: map['offer_amount'] != null
          ? (map['offer_amount'] as num).toDouble()
          : null,
      offerStatus: map['offer_status'],
    );
  }
}

class ChatModel {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  ChatModel copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatModel(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id']?.toString() ?? '',
      otherUserId: map['other_user_id']?.toString() ?? '',
      otherUserName: map['other_user_name'] ?? '',
      otherUserAvatar: map['other_user_avatar'] ?? '',
      lastMessage: map['last_message'] ?? '',
      lastMessageTime:
          DateTime.tryParse(map['last_message_time'] ?? '') ?? DateTime.now(),
      unreadCount: map['unread_count'] ?? 0,
    );
  }
}

class ReviewModel {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    String getFullImageUrl(String? path) {
      if (path == null || path.isEmpty) return '';
      if (path.startsWith('http')) return path;
      String cleanPath = path.startsWith('/') ? path : '/$path';
      if (!cleanPath.startsWith('/media/')) cleanPath = '/media$cleanPath';
      return 'http://10.219.48.75:8000$cleanPath';
    }

    return ReviewModel(
      id: map['id']?.toString() ?? map['review_id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      productName: map['product_name'] ?? map['product_title'] ?? '',
      productImage: getFullImageUrl(map['product_image'] ?? map['image'] ?? ''),
      userName: map['user_name'] ?? map['full_name'] ?? map['buyer_name'] ?? '',
      userAvatar: getFullImageUrl(map['user_avatar'] ?? map['avatar'] ?? ''),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'] ?? map['content'] ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] ?? map['date'] ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class CardModel {
  final String id;
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final String cardholderName;
  final String cardType;

  CardModel({
    required this.id,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    required this.cardholderName,
    required this.cardType,
  });

  CardModel copyWith({
    String? id,
    String? cardNumber,
    String? expiryDate,
    String? cvv,
    String? cardholderName,
    String? cardType,
  }) {
    return CardModel(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      cardholderName: cardholderName ?? this.cardholderName,
      cardType: cardType ?? this.cardType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_number': cardNumber,
      'expiry_date': expiryDate,
      'cvv': cvv,
      'cardholder_name': cardholderName,
      'card_type': cardType,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id']?.toString() ?? '',
      cardNumber: map['card_number'] ?? '',
      expiryDate: map['expiry_date'] ?? '',
      cvv: map['cvv'] ?? '',
      cardholderName: map['cardholder_name'] ?? '',
      cardType: map['card_type'] ?? '',
    );
  }
}

class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String? stripePaymentIntentId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? productImage;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.stripePaymentIntentId,
    required this.createdAt,
    this.completedAt,
    this.productImage,
  });

  bool get isSuccessful => status == 'succeeded' || status == 'completed';
  String get statusText => isSuccessful ? 'تم الدفع بنجاح' : 'معلق';

  factory PaymentModel.fromOrderMap(Map<String, dynamic> order) {
    return PaymentModel(
      id: order['order_id'].toString(),
      orderId: order['order_id'].toString(),
      userId: order['buyer_id']?.toString() ?? '',
      amount: (order['amount'] as num).toDouble(),
      currency: 'usd',
      status: _mapOrderStatusToPaymentStatus(order['order_status']),
      paymentMethod: 'card',
      stripePaymentIntentId: null,
      createdAt: DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now(),
      completedAt: order['delivery_date'] != null
          ? DateTime.tryParse(order['delivery_date'])
          : null,
      productImage: order['product_image']?.toString() ?? '',
    );
  }

  static String _mapOrderStatusToPaymentStatus(String? orderStatus) {
    switch (orderStatus) {
      case 'pending':
        return 'pending';
      case 'confirmed':
        return 'completed';
      case 'delivered':
        return 'completed';
      case 'shipped':
        return 'completed';
      case 'cancelled':
        return 'failed';
      default:
        return 'pending';
    }
  }

  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    String? currency,
    String? status,
    String? paymentMethod,
    String? stripePaymentIntentId,
    DateTime? createdAt,
    DateTime? completedAt,
    String? productImage,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripePaymentIntentId:
          stripePaymentIntentId ?? this.stripePaymentIntentId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      productImage: productImage ?? this.productImage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'stripePaymentIntentId': stripePaymentIntentId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'productImage': productImage,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] ?? 'USD',
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'card',
      stripePaymentIntentId: map['stripePaymentIntentId'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      productImage: map['product_image']?.toString() ?? '',
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }
}

class UploadedProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final String sellerId;
  final String status;
  final DateTime createdAt;
  final double? rating;
  final int? reviewCount;

  UploadedProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.sellerId,
    required this.status,
    required this.createdAt,
    this.rating,
    this.reviewCount,
  });

  UploadedProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? category,
    List<String>? images,
    String? sellerId,
    String? status,
    DateTime? createdAt,
    double? rating,
    int? reviewCount,
  }) {
    return UploadedProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'sellerId': sellerId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  factory UploadedProductModel.fromMap(Map<String, dynamic> map) {
    return UploadedProductModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num).toDouble(),
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      sellerId: map['sellerId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      rating: (map['rating'] as num?)?.toDouble(),
      reviewCount: map['reviewCount'],
    );
  }
}
