-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: marketdb
-- ------------------------------------------------------
-- Server version	9.5.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '91a777e0-b256-11f0-b532-88a4c2bfaf5f:1-342';

--
-- Dumping data for table `addresses`
--

LOCK TABLES `addresses` WRITE;
/*!40000 ALTER TABLE `addresses` DISABLE KEYS */;
/*!40000 ALTER TABLE `addresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `auth_group`
--

LOCK TABLES `auth_group` WRITE;
/*!40000 ALTER TABLE `auth_group` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `auth_group_permissions`
--

LOCK TABLES `auth_group_permissions` WRITE;
/*!40000 ALTER TABLE `auth_group_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_group_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `auth_permission`
--

LOCK TABLES `auth_permission` WRITE;
/*!40000 ALTER TABLE `auth_permission` DISABLE KEYS */;
INSERT INTO `auth_permission` VALUES (1,'Can add log entry',1,'add_logentry'),(2,'Can change log entry',1,'change_logentry'),(3,'Can delete log entry',1,'delete_logentry'),(4,'Can view log entry',1,'view_logentry'),(5,'Can add permission',2,'add_permission'),(6,'Can change permission',2,'change_permission'),(7,'Can delete permission',2,'delete_permission'),(8,'Can view permission',2,'view_permission'),(9,'Can add group',3,'add_group'),(10,'Can change group',3,'change_group'),(11,'Can delete group',3,'delete_group'),(12,'Can view group',3,'view_group'),(13,'Can add user',4,'add_user'),(14,'Can change user',4,'change_user'),(15,'Can delete user',4,'delete_user'),(16,'Can view user',4,'view_user'),(17,'Can add content type',5,'add_contenttype'),(18,'Can change content type',5,'change_contenttype'),(19,'Can delete content type',5,'delete_contenttype'),(20,'Can view content type',5,'view_contenttype'),(21,'Can add session',6,'add_session'),(22,'Can change session',6,'change_session'),(23,'Can delete session',6,'delete_session'),(24,'Can view session',6,'view_session'),(25,'Can add orders',7,'add_orders'),(26,'Can change orders',7,'change_orders'),(27,'Can delete orders',7,'delete_orders'),(28,'Can view orders',7,'view_orders'),(29,'Can add permissions',8,'add_permissions'),(30,'Can change permissions',8,'change_permissions'),(31,'Can delete permissions',8,'delete_permissions'),(32,'Can view permissions',8,'view_permissions'),(33,'Can add products',9,'add_products'),(34,'Can change products',9,'change_products'),(35,'Can delete products',9,'delete_products'),(36,'Can view products',9,'view_products'),(37,'Can add role permissions',10,'add_rolepermissions'),(38,'Can change role permissions',10,'change_rolepermissions'),(39,'Can delete role permissions',10,'delete_rolepermissions'),(40,'Can view role permissions',10,'view_rolepermissions'),(41,'Can add roles',11,'add_roles'),(42,'Can change roles',11,'change_roles'),(43,'Can delete roles',11,'delete_roles'),(44,'Can view roles',11,'view_roles'),(45,'Can add seller requests',12,'add_sellerrequests'),(46,'Can change seller requests',12,'change_sellerrequests'),(47,'Can delete seller requests',12,'delete_sellerrequests'),(48,'Can view seller requests',12,'view_sellerrequests'),(49,'Can add users',13,'add_users'),(50,'Can change users',13,'change_users'),(51,'Can delete users',13,'delete_users'),(52,'Can view users',13,'view_users');
/*!40000 ALTER TABLE `auth_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `auth_user`
--

LOCK TABLES `auth_user` WRITE;
/*!40000 ALTER TABLE `auth_user` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `auth_user_groups`
--

LOCK TABLES `auth_user_groups` WRITE;
/*!40000 ALTER TABLE `auth_user_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_user_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `auth_user_user_permissions`
--

LOCK TABLES `auth_user_user_permissions` WRITE;
/*!40000 ALTER TABLE `auth_user_user_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_user_user_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `chatrequests`
--

LOCK TABLES `chatrequests` WRITE;
/*!40000 ALTER TABLE `chatrequests` DISABLE KEYS */;
INSERT INTO `chatrequests` VALUES (1,5,NULL,'Pending',NULL,'2026-03-25 06:20:18'),(2,6,NULL,'Pending',NULL,'2026-03-25 06:25:55'),(3,6,NULL,'Pending',NULL,'2026-03-25 06:37:47'),(4,6,NULL,'Pending',NULL,'2026-03-25 06:37:54'),(5,6,NULL,'Pending',NULL,'2026-03-25 06:38:19'),(6,6,NULL,'Pending',NULL,'2026-03-25 06:38:24'),(7,6,NULL,'Pending',NULL,'2026-03-25 06:38:41'),(8,5,NULL,'Pending',NULL,'2026-03-25 06:41:18'),(9,5,NULL,'Pending',NULL,'2026-03-25 06:41:27'),(10,5,NULL,'Pending',NULL,'2026-03-25 06:41:32'),(11,6,NULL,'Pending',NULL,'2026-03-25 06:49:30'),(12,6,NULL,'Pending',NULL,'2026-03-25 06:49:35'),(13,6,NULL,'Pending',NULL,'2026-03-25 06:49:40'),(14,5,NULL,'Pending',NULL,'2026-03-25 06:55:13'),(15,5,NULL,'Pending',NULL,'2026-03-25 06:55:18'),(16,5,NULL,'Pending',NULL,'2026-03-25 06:55:22');
/*!40000 ALTER TABLE `chatrequests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `django_admin_log`
--

LOCK TABLES `django_admin_log` WRITE;
/*!40000 ALTER TABLE `django_admin_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `django_admin_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `django_content_type`
--

LOCK TABLES `django_content_type` WRITE;
/*!40000 ALTER TABLE `django_content_type` DISABLE KEYS */;
INSERT INTO `django_content_type` VALUES (1,'admin','logentry'),(7,'admin_api','orders'),(8,'admin_api','permissions'),(9,'admin_api','products'),(10,'admin_api','rolepermissions'),(11,'admin_api','roles'),(12,'admin_api','sellerrequests'),(13,'admin_api','users'),(3,'auth','group'),(2,'auth','permission'),(4,'auth','user'),(5,'contenttypes','contenttype'),(6,'sessions','session');
/*!40000 ALTER TABLE `django_content_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `django_migrations`
--

LOCK TABLES `django_migrations` WRITE;
/*!40000 ALTER TABLE `django_migrations` DISABLE KEYS */;
INSERT INTO `django_migrations` VALUES (1,'contenttypes','0001_initial','2026-02-21 06:53:34.832219'),(2,'auth','0001_initial','2026-02-21 06:53:35.375654'),(3,'admin','0001_initial','2026-02-21 06:53:35.513619'),(4,'admin','0002_logentry_remove_auto_add','2026-02-21 06:53:35.520026'),(5,'admin','0003_logentry_add_action_flag_choices','2026-02-21 06:53:35.526517'),(6,'admin_api','0001_initial','2026-02-21 06:53:35.532464'),(7,'contenttypes','0002_remove_content_type_name','2026-02-21 06:53:35.642372'),(8,'auth','0002_alter_permission_name_max_length','2026-02-21 06:53:35.702459'),(9,'auth','0003_alter_user_email_max_length','2026-02-21 06:53:35.723856'),(10,'auth','0004_alter_user_username_opts','2026-02-21 06:53:35.729961'),(11,'auth','0005_alter_user_last_login_null','2026-02-21 06:53:35.792407'),(12,'auth','0006_require_contenttypes_0002','2026-02-21 06:53:35.795309'),(13,'auth','0007_alter_validators_add_error_messages','2026-02-21 06:53:35.801598'),(14,'auth','0008_alter_user_username_max_length','2026-02-21 06:53:35.871016'),(15,'auth','0009_alter_user_last_name_max_length','2026-02-21 06:53:35.934304'),(16,'auth','0010_alter_group_name_max_length','2026-02-21 06:53:35.951111'),(17,'auth','0011_update_proxy_permissions','2026-02-21 06:53:35.964175'),(18,'auth','0012_alter_user_first_name_max_length','2026-02-21 06:53:36.026167'),(19,'sessions','0001_initial','2026-02-21 06:53:36.061085');
/*!40000 ALTER TABLE `django_migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `django_session`
--

LOCK TABLES `django_session` WRITE;
/*!40000 ALTER TABLE `django_session` DISABLE KEYS */;
/*!40000 ALTER TABLE `django_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
INSERT INTO `messages` VALUES (1,1,5,'Welcome',1,'2026-02-28 08:03:54'),(2,5,1,'بدي اضربك',0,'2026-02-28 08:04:42'),(3,1,5,'any thing',0,'2026-03-24 06:31:09'),(4,1,5,'any thing',0,'2026-03-24 06:31:43'),(5,1,5,'ANY THING',0,'2026-03-24 06:43:24'),(6,1,5,'dddd',0,'2026-03-24 06:43:31'),(7,1,5,'ddddd',0,'2026-03-24 06:43:32'),(8,1,1,'Any',0,'2026-03-24 06:46:51'),(9,1,1,'ffff',0,'2026-03-24 06:47:56'),(10,1,1,'ءءءءءءءءءء',0,'2026-03-24 06:50:16'),(11,1,1,'شششششش',0,'2026-03-24 06:52:15'),(12,1,5,'asmdmd',0,'2026-03-24 06:52:32'),(13,1,5,'any thing',0,'2026-03-24 12:52:14'),(14,1,6,'any',0,'2026-03-24 12:52:27'),(15,5,1,'ءلالءللاءبلءلبلا',0,'2026-03-24 13:02:50'),(16,1,1,'Hello',0,'2026-04-11 07:05:50'),(17,1,5,'any',0,'2026-05-07 12:05:52'),(18,1,5,'شششش',0,'2026-05-07 12:24:58'),(19,1,6,'sskdk',1,'2026-05-09 05:26:16'),(20,1,6,'11',1,'2026-05-15 07:15:46'),(21,1,1,'شىشسس',1,'2026-05-21 16:00:02'),(22,1,8,'abcd',1,'2026-05-21 16:01:34'),(23,1,5,'cdd',1,'2026-05-22 20:38:04');
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,5,'? طلبك رقم 2 في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-07 11:54:15'),(2,5,'? طلبك رقم 2 في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-07 11:54:17'),(3,5,'? طلبك رقم 2 في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-07 11:54:19'),(4,5,'? طلبك رقم 2 في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-07 11:54:21'),(5,5,'? طلبك رقم 2 في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-07 11:54:22'),(6,5,'? طلبك رقم 2 في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-07 11:54:23'),(7,5,'? طلبك رقم 2 في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-07 11:54:28'),(8,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-15 08:06:35'),(9,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-15 08:07:06'),(10,1,'? طلبك في طريقه إليك!',0,'2026-05-15 08:21:54'),(11,1,'? طلبك رقم 1 في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-15 08:23:25'),(12,1,'? طلبك رقم 1 في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-15 08:31:00'),(13,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-15 09:15:49'),(14,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-19 08:31:28'),(15,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-21 11:14:07'),(16,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-21 11:14:47'),(17,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-22 09:28:32'),(18,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-22 09:28:32'),(19,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-22 19:45:01'),(20,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-22 19:45:01'),(21,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-22 19:45:01'),(22,1,'? طلبك في طريقه إليك الآن مع مندوب التوصيل!',0,'2026-05-23 07:23:44'),(23,5,'تمت إضافة رصيد إلى حسابك بقيمة 500.0 من قبل الإدارة بنجاح.',0,'2026-05-27 04:45:39'),(24,7,'تمت إضافة رصيد إلى حسابك بقيمة 300.0 من قبل الإدارة بنجاح.',0,'2026-05-27 05:14:24');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `permissions`
--

LOCK TABLES `permissions` WRITE;
/*!40000 ALTER TABLE `permissions` DISABLE KEYS */;
INSERT INTO `permissions` VALUES (1,'APPROVE_SELLER_REQUEST'),(2,'APPROVE_PRODUCT'),(3,'MANAGE_USERS'),(4,'ADD_PRODUCT'),(5,'VIEW_SALES_REPORT'),(6,'BUY_PRODUCT');
/*!40000 ALTER TABLE `permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES (2,5,NULL,'سيارة',2500.00,'http://127.0.0.1:8000/media/products/Gemini_Generated_Image_jxd8qfjxd8qfjxd8.png','شو ما كان','2026-03-19 08:55:02','approved');
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `qrtransactions`
--

LOCK TABLES `qrtransactions` WRITE;
/*!40000 ALTER TABLE `qrtransactions` DISABLE KEYS */;
INSERT INTO `qrtransactions` VALUES (1,'Modar Abdallah','Admin Deposit',500.00,'Completed',5),(2,'ModarAbdullah','Admin Deposit',300.00,'Completed',7);
/*!40000 ALTER TABLE `qrtransactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `role_permissions`
--

LOCK TABLES `role_permissions` WRITE;
/*!40000 ALTER TABLE `role_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `role_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'Admin'),(2,'Seller'),(3,'Buyer');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `seller_requests`
--

LOCK TABLES `seller_requests` WRITE;
/*!40000 ALTER TABLE `seller_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `seller_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `shipments`
--

LOCK TABLES `shipments` WRITE;
/*!40000 ALTER TABLE `shipments` DISABLE KEYS */;
INSERT INTO `shipments` VALUES (1,1,1,NULL,1,NULL,'At Destination Station'),(2,1,1,NULL,1,NULL,'At Destination Station'),(3,1,1,NULL,1,NULL,'At Destination Station'),(4,2,1,NULL,1,NULL,'At Destination Station'),(5,1,1,NULL,1,NULL,'At Destination Station'),(6,1,1,NULL,1,NULL,'At Destination Station'),(7,1,1,NULL,1,NULL,'At Destination Station'),(8,1,1,NULL,1,NULL,'At Destination Station'),(9,3,1,NULL,1,NULL,'At Destination Station'),(10,4,1,NULL,1,NULL,'At Destination Station'),(11,5,1,NULL,1,NULL,'At Destination Station'),(12,6,2,NULL,2,NULL,'At Destination Station'),(13,7,2,NULL,2,NULL,'At Destination Station');
/*!40000 ALTER TABLE `shipments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `station_products`
--

LOCK TABLES `station_products` WRITE;
/*!40000 ALTER TABLE `station_products` DISABLE KEYS */;
/*!40000 ALTER TABLE `station_products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `stations`
--

LOCK TABLES `stations` WRITE;
/*!40000 ALTER TABLE `stations` DISABLE KEYS */;
INSERT INTO `stations` VALUES (1,'مركز عمليات Vortex الرئيسي','دمشق','المنطقة الصناعية',NULL,NULL,50,'Active'),(2,'مركز الزراعة','اللاذقية','بجانب علي بابا',35.52472929,35.79143727,50,'Active'),(3,'مراكش','حمص','فوق الشام',34.69300610,36.73365212,50,'Active');
/*!40000 ALTER TABLE `stations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `trucks`
--

LOCK TABLES `trucks` WRITE;
/*!40000 ALTER TABLE `trucks` DISABLE KEYS */;
INSERT INTO `trucks` VALUES (11,'سيارة 2',NULL,2,'In Transit'),(14,'04456',NULL,1,'Available');
/*!40000 ALTER TABLE `trucks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `useraddresses`
--

LOCK TABLES `useraddresses` WRITE;
/*!40000 ALTER TABLE `useraddresses` DISABLE KEYS */;
/*!40000 ALTER TABLE `useraddresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'Admin Test','test@test.com','1234',1,0.00,0.00,'2026-02-21 15:07:46',7.00,'admin',NULL,NULL),(5,'Modar Abdallah','modar@gmail.com','1234',2,0.00,0.00,'2026-02-28 07:51:16',1100.00,'buyer',NULL,NULL),(6,'Mozart','modarabd@gmail.com','1234',2,0.00,0.00,'2026-03-21 07:53:04',0.00,'seller',NULL,NULL),(7,'ModarAbdullah','modarabdallah630@gmail.com','Modar2003',3,0.00,0.00,'2026-04-06 20:56:46',300.00,'buyer',NULL,NULL),(8,'Morad','modar655@gmail.com','1234',3,0.00,0.00,'2026-04-12 06:25:59',0.00,'buyer',NULL,NULL),(9,'Modar','modar1@gmail.com','1234',1,0.00,0.00,'2026-05-15 07:12:45',0.00,'buyer',NULL,NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-16 13:31:35
