-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               8.0.40 - MySQL Community Server - GPL
-- Server OS:                    Win64
-- HeidiSQL Version:             12.8.0.6908
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Dumping structure for table pig_ops_dev.a02_business_object
CREATE TABLE IF NOT EXISTS `a02_business_object` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(80) DEFAULT NULL,
  `user_group_flag_num` int unsigned DEFAULT '0',
  `bit_num` int unsigned DEFAULT '0',
  `dt_entry` datetime DEFAULT (now()),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table pig_ops_dev.a02_business_object: ~24 rows (approximately)
INSERT INTO `a02_business_object` (`id`, `name`, `user_group_flag_num`, `bit_num`, `dt_entry`) VALUES
	(1, 'USER', 0, 0, '2025-08-26 02:46:30'),
	(2, 'ACCOUNT', 0, 1, '2025-08-26 02:46:56'),
	(3, 'ACCOUNT_REQUEST', 0, 2, '2025-08-26 02:47:19'),
	(4, 'USER_GROUP', 0, 3, '2025-08-26 02:48:02'),
	(5, 'PIG_FARM', 0, 4, '2025-08-26 02:48:18'),
	(6, 'PIG_FARM_STAFF', 0, 5, '2025-08-26 02:48:32'),
	(7, 'PIG_RACE', 0, 6, '2025-08-26 02:48:49'),
	(8, 'PIG_RACE_LINE', 0, 7, '2025-08-26 02:49:03'),
	(9, 'ACC_GESTATING_OPS', 0, 8, '2025-08-26 02:49:23'),
	(10, 'ACC_LACTATING_OPS', 0, 9, '2025-08-26 02:49:35'),
	(11, 'SEMEN_SUPPLIER', 0, 10, '2025-08-26 02:50:07'),
	(12, 'FEED_SUPPLIER', 0, 11, '2025-08-26 02:50:27'),
	(13, 'FEED_BRAND', 0, 12, '2025-08-26 02:50:35'),
	(14, 'FEED_TYPE', 0, 13, '2025-08-26 02:50:43'),
	(15, 'SOW_BOAR', 0, 14, '2025-08-26 02:51:05'),
	(16, 'SEMEN_SOURCE', 0, 15, '2025-08-26 02:51:12'),
	(17, 'PIG_PRODUCTION', 0, 16, '2025-08-26 02:51:37'),
	(18, 'PIG_PROD_AI', 0, 17, '2025-08-26 02:51:50'),
	(19, 'PIG_PROD_FEED_BUY', 0, 18, '2025-08-26 02:52:24'),
	(20, 'PIG_PROD_FEED_BAL', 0, 19, '2025-08-26 02:52:45'),
	(21, 'PIG_PROD_GESTATING_OPS', 0, 20, '2025-08-26 02:53:17'),
	(22, 'PIG_PROD_LACTATING_OPS', 0, 21, '2025-08-27 07:12:24'),
	(23, 'PIG_PROD_PIG_DEAD', 0, 22, '2025-08-27 07:12:51'),
	(24, 'PIG_PROD_HARVEST', 0, 23, '2025-08-27 07:13:06');

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
