/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.7.2-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: internship
-- ------------------------------------------------------
-- Server version	11.7.2-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `agencies`
--

DROP TABLE IF EXISTS `agencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `agencies` (
  `agency_id` int(11) NOT NULL AUTO_INCREMENT,
  `name_agency` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`agency_id`)
) ENGINE=InnoDB AUTO_INCREMENT=122 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agencies`
--

LOCK TABLES `agencies` WRITE;
/*!40000 ALTER TABLE `agencies` DISABLE KEYS */;
INSERT INTO `agencies` VALUES
(61,'Adrar'),
(62,'Chlef'),
(63,'Laghouat'),
(64,'Oum El Bouaghi'),
(65,'Batna'),
(66,'Bejaia'),
(67,'Biskra'),
(68,'Bechar'),
(69,'Blida'),
(70,'Bouira'),
(71,'Tamanrasset'),
(72,'Tebessa'),
(73,'Tlemcen'),
(74,'Tiaret'),
(75,'Tizi Ouzou'),
(76,'Alger Centre'),
(77,'Djelfa'),
(78,'Jijel'),
(79,'Setif'),
(80,'Saida'),
(81,'Skikda'),
(82,'Sidi Bel Abbes'),
(83,'Annaba'),
(84,'Guelma'),
(85,'Constantine'),
(86,'Medea'),
(87,'Mostaganem'),
(88,'Msila'),
(89,'Mascara'),
(90,'Ouargla'),
(91,'Oran'),
(92,'El Bayadh'),
(93,'Illizi'),
(94,'Bordj Bou Arreridj'),
(95,'Boumerdes'),
(96,'El Tarf'),
(97,'Tindouf'),
(98,'Tissemsilt'),
(99,'El Oued'),
(100,'Khenchela'),
(101,'Souk Ahras'),
(102,'Tipaza'),
(103,'Mila'),
(104,'Ain Defla'),
(105,'Naama'),
(106,'Ain Temouchent'),
(107,'Ghardaïa'),
(108,'Relizane'),
(109,'Timimoun'),
(110,'Bordj Badji Mokhtar'),
(111,'Ouled Djellal'),
(112,'Béni Abbès'),
(113,'In Salah'),
(114,'In Guezzam'),
(115,'Touggourt'),
(116,'Djanet'),
(117,'D’El M’Ghaier'),
(118,'D’El Meniaa'),
(119,'Alger Est'),
(120,'Alger Ouest'),
(121,'Alger Nord');
/*!40000 ALTER TABLE `agencies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `death_causes`
--

DROP TABLE IF EXISTS `death_causes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `death_causes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cause_name` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cause_name` (`cause_name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `death_causes`
--

LOCK TABLES `death_causes` WRITE;
/*!40000 ALTER TABLE `death_causes` DISABLE KEYS */;
INSERT INTO `death_causes` VALUES
(4,'Accident de travail'),
(2,'Acte terroriste'),
(5,'Autre'),
(1,'Causes naturelles'),
(3,'Victime de tragédie nationale');
/*!40000 ALTER TABLE `death_causes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `declaration_documents`
--

DROP TABLE IF EXISTS `declaration_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `declaration_documents` (
  `declaration_document_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `declaration_id` int(10) unsigned NOT NULL COMMENT 'FK vers la déclaration spécifique',
  `document_type_id` int(10) unsigned NOT NULL COMMENT 'FK vers le type de document requis',
  `status` enum('pending','uploaded','verified','rejected') NOT NULL DEFAULT 'pending' COMMENT 'Statut de ce document spécifique pour la déclaration',
  `uploaded_file_path` varchar(255) DEFAULT NULL COMMENT 'Chemin ou référence vers le fichier téléchargé',
  `uploaded_at` timestamp NULL DEFAULT NULL COMMENT 'Timestamp du téléchargement du document',
  `reviewed_by_admin_id` int(10) unsigned DEFAULT NULL COMMENT 'FK vers la table users (admin ayant examiné)',
  `reviewed_at` timestamp NULL DEFAULT NULL COMMENT 'Timestamp de l''examen du document',
  `rejection_reason` text DEFAULT NULL COMMENT 'Raison si le document a été rejeté par l''admin',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`declaration_document_id`),
  KEY `declaration_id` (`declaration_id`),
  KEY `document_type_id` (`document_type_id`),
  KEY `reviewed_by_admin_id` (`reviewed_by_admin_id`),
  CONSTRAINT `declaration_documents_ibfk_1` FOREIGN KEY (`declaration_id`) REFERENCES `declarations` (`declaration_id`) ON DELETE CASCADE,
  CONSTRAINT `declaration_documents_ibfk_2` FOREIGN KEY (`document_type_id`) REFERENCES `document_types` (`document_type_id`),
  CONSTRAINT `declaration_documents_ibfk_3` FOREIGN KEY (`reviewed_by_admin_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=210 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Suit le statut des documents requis pour chaque déclaration';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `declaration_documents`
--

LOCK TABLES `declaration_documents` WRITE;
/*!40000 ALTER TABLE `declaration_documents` DISABLE KEYS */;
INSERT INTO `declaration_documents` VALUES
(27,7,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-01 21:18:47','2025-06-01 21:18:47'),
(28,7,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-01 21:18:47','2025-06-01 21:18:47'),
(29,7,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-01 21:18:47','2025-06-01 21:18:47'),
(30,7,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-01 21:18:47','2025-06-01 21:18:47'),
(31,7,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-01 21:18:47','2025-06-01 21:18:47'),
(32,8,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 07:54:48','2025-06-03 07:54:48'),
(33,8,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 07:54:48','2025-06-03 07:54:48'),
(34,8,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 07:54:48','2025-06-03 07:54:48'),
(35,8,5,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 07:54:48','2025-06-03 07:54:48'),
(36,8,6,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 07:54:48','2025-06-03 07:54:48'),
(37,8,7,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 07:54:48','2025-06-03 07:54:48'),
(38,9,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 08:23:24','2025-06-03 08:23:24'),
(39,9,2,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 08:23:24','2025-06-03 08:23:24'),
(40,9,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 08:23:24','2025-06-03 08:23:24'),
(41,9,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 08:23:24','2025-06-03 08:23:24'),
(42,10,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 08:45:55','2025-06-03 08:45:55'),
(43,10,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 08:45:55','2025-06-03 08:45:55'),
(44,10,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 08:45:55','2025-06-03 08:45:55'),
(45,10,5,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 08:45:55','2025-06-03 08:45:55'),
(46,10,8,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 08:45:55','2025-06-03 08:45:55'),
(47,11,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:15:34','2025-06-03 09:15:34'),
(48,11,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:15:34','2025-06-03 09:15:34'),
(49,11,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:15:34','2025-06-03 09:15:34'),
(50,11,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:15:34','2025-06-03 09:15:34'),
(51,11,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:15:34','2025-06-03 09:15:34'),
(52,12,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:35:58','2025-06-03 09:35:58'),
(53,12,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:35:58','2025-06-03 09:35:58'),
(54,12,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:35:58','2025-06-03 09:35:58'),
(55,12,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:35:58','2025-06-03 09:35:58'),
(56,12,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-03 09:35:58','2025-06-03 09:35:58'),
(57,13,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-11 13:29:56','2025-06-11 13:29:56'),
(58,13,2,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-11 13:29:56','2025-06-11 13:29:56'),
(59,13,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-11 13:29:56','2025-06-11 13:29:56'),
(60,13,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-11 13:29:56','2025-06-11 13:29:56'),
(61,14,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 15:59:05','2025-06-13 15:59:05'),
(62,14,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 15:59:05','2025-06-13 15:59:05'),
(63,14,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 15:59:05','2025-06-13 15:59:05'),
(64,14,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 15:59:05','2025-06-13 15:59:05'),
(65,14,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 15:59:05','2025-06-13 15:59:05'),
(66,15,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:10:04','2025-06-13 16:10:04'),
(67,15,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:10:04','2025-06-13 16:10:04'),
(68,15,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:10:04','2025-06-13 16:10:04'),
(69,15,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:10:04','2025-06-13 16:10:04'),
(70,15,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:10:04','2025-06-13 16:10:04'),
(71,16,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:12:41','2025-06-13 16:12:41'),
(72,16,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:12:41','2025-06-13 16:12:41'),
(73,16,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:12:41','2025-06-13 16:12:41'),
(74,16,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:12:41','2025-06-13 16:12:41'),
(75,16,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:12:41','2025-06-13 16:12:41'),
(76,17,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:21:46','2025-06-13 16:21:46'),
(77,17,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:21:46','2025-06-13 16:21:46'),
(78,17,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:21:46','2025-06-13 16:21:46'),
(79,17,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:21:46','2025-06-13 16:21:46'),
(80,17,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:21:46','2025-06-13 16:21:46'),
(81,18,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:39:35','2025-06-13 16:39:35'),
(82,18,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:39:35','2025-06-13 16:39:35'),
(83,18,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:39:35','2025-06-13 16:39:35'),
(84,18,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:39:35','2025-06-13 16:39:35'),
(85,18,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-13 16:39:35','2025-06-13 16:39:35'),
(86,19,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-14 20:58:52','2025-06-14 20:58:52'),
(87,19,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-14 20:58:52','2025-06-14 20:58:52'),
(88,19,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-14 20:58:52','2025-06-14 20:58:52'),
(89,19,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-14 20:58:52','2025-06-14 20:58:52'),
(90,19,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-14 20:58:52','2025-06-14 20:58:52'),
(91,20,1,'uploaded','/uploads/documentFile-1749987364349-140010948.pdf','2025-06-15 11:36:04',NULL,NULL,NULL,'2025-06-15 11:20:11','2025-06-15 11:36:04'),
(92,20,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 11:20:11','2025-06-15 11:20:11'),
(93,20,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 11:20:11','2025-06-15 11:20:11'),
(94,20,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 11:20:11','2025-06-15 11:20:11'),
(95,20,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 11:20:11','2025-06-15 11:20:11'),
(96,21,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 11:50:11','2025-06-15 11:50:11'),
(97,21,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 11:50:11','2025-06-15 11:50:11'),
(98,21,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 11:50:11','2025-06-15 11:50:11'),
(99,21,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 11:50:11','2025-06-15 11:50:11'),
(100,21,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 11:50:11','2025-06-15 11:50:11'),
(101,22,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:01:03','2025-06-15 12:01:03'),
(102,22,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:01:03','2025-06-15 12:01:03'),
(103,22,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:01:03','2025-06-15 12:01:03'),
(104,22,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:01:03','2025-06-15 12:01:03'),
(105,22,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:01:03','2025-06-15 12:01:03'),
(106,23,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:05:21','2025-06-15 12:05:21'),
(107,23,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:05:21','2025-06-15 12:05:21'),
(108,23,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:05:21','2025-06-15 12:05:21'),
(109,23,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:05:21','2025-06-15 12:05:21'),
(110,23,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:05:21','2025-06-15 12:05:21'),
(111,24,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:11:52','2025-06-15 12:11:52'),
(112,24,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:11:52','2025-06-15 12:11:52'),
(113,24,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:11:52','2025-06-15 12:11:52'),
(114,24,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:11:52','2025-06-15 12:11:52'),
(115,24,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:11:52','2025-06-15 12:11:52'),
(116,25,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:23:43','2025-06-15 12:23:43'),
(117,25,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:23:43','2025-06-15 12:23:43'),
(118,25,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:23:43','2025-06-15 12:23:43'),
(119,25,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:23:43','2025-06-15 12:23:43'),
(120,25,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:23:43','2025-06-15 12:23:43'),
(121,26,1,'uploaded','/uploads/documentFile-1749990716970-409020109.pdf','2025-06-15 12:31:56',NULL,NULL,NULL,'2025-06-15 12:25:17','2025-06-15 12:31:56'),
(122,26,2,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:25:17','2025-06-15 12:25:17'),
(123,26,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:25:17','2025-06-15 12:25:17'),
(124,26,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:25:17','2025-06-15 12:25:17'),
(125,27,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:37:37','2025-06-15 12:37:37'),
(126,27,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:37:37','2025-06-15 12:37:37'),
(127,27,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:37:37','2025-06-15 12:37:37'),
(128,27,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:37:37','2025-06-15 12:37:37'),
(129,27,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:37:37','2025-06-15 12:37:37'),
(130,28,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:52:28','2025-06-15 12:52:28'),
(131,28,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:52:28','2025-06-15 12:52:28'),
(132,28,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:52:28','2025-06-15 12:52:28'),
(133,28,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:52:28','2025-06-15 12:52:28'),
(134,28,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:52:28','2025-06-15 12:52:28'),
(135,29,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:55:44','2025-06-15 12:55:44'),
(136,29,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:55:44','2025-06-15 12:55:44'),
(137,29,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:55:44','2025-06-15 12:55:44'),
(138,29,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:55:44','2025-06-15 12:55:44'),
(139,29,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 12:55:44','2025-06-15 12:55:44'),
(140,30,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 13:09:36','2025-06-15 13:09:36'),
(141,30,2,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 13:09:36','2025-06-15 13:09:36'),
(142,30,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 13:09:36','2025-06-15 13:09:36'),
(143,30,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 13:09:36','2025-06-15 13:09:36'),
(144,31,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 13:23:08','2025-06-15 13:23:08'),
(145,31,2,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 13:23:08','2025-06-15 13:23:08'),
(146,31,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 13:23:08','2025-06-15 13:23:08'),
(147,31,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 13:23:08','2025-06-15 13:23:08'),
(148,32,1,'uploaded','/uploads/documentFile-1749994933251-745085127.jpg','2025-06-15 13:42:13',NULL,NULL,NULL,'2025-06-15 13:37:27','2025-06-15 13:42:13'),
(149,32,3,'uploaded','/uploads/documentFile-1749994936011-990671749.jpg','2025-06-15 13:42:16',NULL,NULL,NULL,'2025-06-15 13:37:27','2025-06-15 13:42:16'),
(150,32,4,'uploaded','/uploads/documentFile-1749994938615-912316163.jpg','2025-06-15 13:42:18',NULL,NULL,NULL,'2025-06-15 13:37:27','2025-06-15 13:42:18'),
(151,32,5,'uploaded','/uploads/documentFile-1749994940690-375076706.jpg','2025-06-15 13:42:20',NULL,NULL,NULL,'2025-06-15 13:37:27','2025-06-15 13:42:20'),
(152,32,8,'uploaded','/uploads/documentFile-1749994942840-752124582.jpg','2025-06-15 13:42:22',NULL,NULL,NULL,'2025-06-15 13:37:27','2025-06-15 13:42:22'),
(153,33,1,'uploaded','/uploads/documentFile-1750008647305-172491439.jpg','2025-06-15 17:30:47',NULL,NULL,NULL,'2025-06-15 17:30:16','2025-06-15 17:30:47'),
(154,33,2,'uploaded','/uploads/documentFile-1750008649139-818816059.jpg','2025-06-15 17:30:49',NULL,NULL,NULL,'2025-06-15 17:30:16','2025-06-15 17:30:49'),
(155,33,3,'uploaded','/uploads/documentFile-1750008650877-114842162.jpg','2025-06-15 17:30:51',NULL,NULL,NULL,'2025-06-15 17:30:16','2025-06-15 17:30:51'),
(156,33,4,'uploaded','/uploads/documentFile-1750008652521-514546312.jpg','2025-06-15 17:30:52',NULL,NULL,NULL,'2025-06-15 17:30:16','2025-06-15 17:30:52'),
(157,34,1,'uploaded','/uploads/documentFile-1750008915869-401830193.jpg','2025-06-15 17:35:15',NULL,NULL,NULL,'2025-06-15 17:34:27','2025-06-15 17:35:15'),
(158,34,3,'uploaded','/uploads/documentFile-1750008917631-478683665.jpg','2025-06-15 17:35:17',NULL,NULL,NULL,'2025-06-15 17:34:27','2025-06-15 17:35:17'),
(159,34,4,'uploaded','/uploads/documentFile-1750008919679-646300402.jpg','2025-06-15 17:35:19',NULL,NULL,NULL,'2025-06-15 17:34:27','2025-06-15 17:35:19'),
(160,34,5,'uploaded','/uploads/documentFile-1750008922241-675957137.jpg','2025-06-15 17:35:22',NULL,NULL,NULL,'2025-06-15 17:34:27','2025-06-15 17:35:22'),
(161,34,8,'uploaded','/uploads/documentFile-1750008924800-774335123.jpg','2025-06-15 17:35:25',NULL,NULL,NULL,'2025-06-15 17:34:27','2025-06-15 17:35:25'),
(162,35,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:26:35','2025-06-15 21:26:35'),
(163,35,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:26:35','2025-06-15 21:26:35'),
(164,35,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:26:35','2025-06-15 21:26:35'),
(165,35,5,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:26:35','2025-06-15 21:26:35'),
(166,35,6,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:26:35','2025-06-15 21:26:35'),
(167,35,7,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:26:35','2025-06-15 21:26:35'),
(168,36,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:37:48','2025-06-15 21:37:48'),
(169,36,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:37:48','2025-06-15 21:37:48'),
(170,36,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:37:48','2025-06-15 21:37:48'),
(171,36,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:37:48','2025-06-15 21:37:48'),
(172,36,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:37:48','2025-06-15 21:37:48'),
(173,37,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:48:58','2025-06-15 21:48:58'),
(174,37,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:48:58','2025-06-15 21:48:58'),
(175,37,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:48:58','2025-06-15 21:48:58'),
(176,37,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:48:58','2025-06-15 21:48:58'),
(177,37,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:48:58','2025-06-15 21:48:58'),
(178,38,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:50:37','2025-06-15 21:50:37'),
(179,38,2,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:50:37','2025-06-15 21:50:37'),
(180,38,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:50:37','2025-06-15 21:50:37'),
(181,38,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 21:50:37','2025-06-15 21:50:37'),
(182,39,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:02:36','2025-06-15 22:02:36'),
(183,39,2,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:02:36','2025-06-15 22:02:36'),
(184,39,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:02:36','2025-06-15 22:02:36'),
(185,39,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:02:36','2025-06-15 22:02:36'),
(186,40,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:24:33','2025-06-15 22:24:33'),
(187,40,2,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:24:33','2025-06-15 22:24:33'),
(188,40,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:24:33','2025-06-15 22:24:33'),
(189,40,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:24:33','2025-06-15 22:24:33'),
(190,41,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:38:08','2025-06-15 22:38:08'),
(191,41,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:38:08','2025-06-15 22:38:08'),
(192,41,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:38:08','2025-06-15 22:38:08'),
(193,41,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:38:08','2025-06-15 22:38:08'),
(194,41,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:38:08','2025-06-15 22:38:08'),
(195,42,1,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:52:07','2025-06-15 22:52:07'),
(196,42,3,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:52:07','2025-06-15 22:52:07'),
(197,42,4,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:52:07','2025-06-15 22:52:07'),
(198,42,9,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:52:07','2025-06-15 22:52:07'),
(199,42,10,'pending',NULL,NULL,NULL,NULL,NULL,'2025-06-15 22:52:07','2025-06-15 22:52:07'),
(200,43,1,'uploaded','/uploads/documentFile-1750083757950-761808301.jpg','2025-06-16 14:22:38',NULL,NULL,NULL,'2025-06-16 14:22:00','2025-06-16 14:22:38'),
(201,43,3,'uploaded','/uploads/documentFile-1750083758766-118487184.jpg','2025-06-16 14:22:38',NULL,NULL,NULL,'2025-06-16 14:22:00','2025-06-16 14:22:38'),
(202,43,4,'uploaded','/uploads/documentFile-1750083759381-285883377.jpg','2025-06-16 14:22:39',NULL,NULL,NULL,'2025-06-16 14:22:00','2025-06-16 14:22:39'),
(203,43,9,'uploaded','/uploads/documentFile-1750083759813-630284782.jpg','2025-06-16 14:22:39',NULL,NULL,NULL,'2025-06-16 14:22:00','2025-06-16 14:22:39'),
(204,43,10,'uploaded','/uploads/documentFile-1750083759968-472312399.jpg','2025-06-16 14:22:41',NULL,NULL,NULL,'2025-06-16 14:22:00','2025-06-16 14:22:41'),
(205,44,1,'uploaded','/uploads/documentFile-1750084249171-208696714.jpg','2025-06-16 14:30:49',NULL,NULL,NULL,'2025-06-16 14:30:28','2025-06-16 14:30:49'),
(206,44,3,'uploaded','/uploads/documentFile-1750084249496-895573099.jpg','2025-06-16 14:30:49',NULL,NULL,NULL,'2025-06-16 14:30:28','2025-06-16 14:30:49'),
(207,44,4,'uploaded','/uploads/documentFile-1750084250705-63567251.jpg','2025-06-16 14:30:50',NULL,NULL,NULL,'2025-06-16 14:30:28','2025-06-16 14:30:50'),
(208,44,9,'uploaded','/uploads/documentFile-1750084250913-326804119.jpg','2025-06-16 14:30:51',NULL,NULL,NULL,'2025-06-16 14:30:28','2025-06-16 14:30:51'),
(209,44,10,'uploaded','/uploads/documentFile-1750084251494-851314616.jpg','2025-06-16 14:30:51',NULL,NULL,NULL,'2025-06-16 14:30:28','2025-06-16 14:30:51');
/*!40000 ALTER TABLE `declaration_documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `declarations`
--

DROP TABLE IF EXISTS `declarations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `declarations` (
  `declaration_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `applicant_user_id` int(10) unsigned NOT NULL,
  `decujus_pension_number` varchar(9) DEFAULT NULL,
  `relationship_id` int(10) unsigned NOT NULL,
  `death_cause_id` int(10) unsigned DEFAULT NULL,
  `declaration_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('submitted','approved','rejected') NOT NULL DEFAULT 'submitted',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`declaration_id`),
  KEY `fk_declarations_user_idx` (`applicant_user_id`),
  KEY `idx_decujus_pension_number` (`decujus_pension_number`),
  KEY `idx_status` (`status`),
  KEY `fk_declaration_relationship` (`relationship_id`),
  KEY `fk_declaration_death_cause` (`death_cause_id`),
  CONSTRAINT `fk_declaration_death_cause` FOREIGN KEY (`death_cause_id`) REFERENCES `death_causes` (`id`),
  CONSTRAINT `fk_declaration_relationship` FOREIGN KEY (`relationship_id`) REFERENCES `relationships` (`id`),
  CONSTRAINT `fk_declarations_user` FOREIGN KEY (`applicant_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `declarations`
--

LOCK TABLES `declarations` WRITE;
/*!40000 ALTER TABLE `declarations` DISABLE KEYS */;
INSERT INTO `declarations` VALUES
(7,10,'QWER12345',6,4,'2025-06-01 20:18:45','submitted','2025-06-01 21:18:47','2025-06-01 21:18:47'),
(8,10,'TEST12345',3,2,'2025-06-03 06:54:47','submitted','2025-06-03 07:54:48','2025-06-03 07:54:48'),
(9,10,'ABCD12345',1,3,'2025-06-03 07:23:23','submitted','2025-06-03 08:23:24','2025-06-03 08:23:24'),
(10,10,'ASDF12345',4,3,'2025-06-03 07:45:53','submitted','2025-06-03 08:45:55','2025-06-03 08:45:55'),
(11,10,'ASDF12346',6,4,'2025-06-03 08:15:33','submitted','2025-06-03 09:15:34','2025-06-03 09:15:34'),
(12,10,'12345QWER',6,4,'2025-06-03 08:35:57','submitted','2025-06-03 09:35:58','2025-06-03 09:35:58'),
(13,10,'ASDFGHJKL',2,2,'2025-06-11 12:29:55','submitted','2025-06-11 13:29:56','2025-06-11 13:29:56'),
(14,10,'ZXCV98765',6,2,'2025-06-13 14:59:06','submitted','2025-06-13 15:59:05','2025-06-13 15:59:05'),
(15,10,'LMNO54321',5,2,'2025-06-13 15:10:05','submitted','2025-06-13 16:10:04','2025-06-13 16:10:04'),
(16,10,'WISS12345',5,2,'2025-06-13 15:12:42','submitted','2025-06-13 16:12:41','2025-06-13 16:12:41'),
(17,10,'GHJK11223',6,2,'2025-06-13 15:21:46','submitted','2025-06-13 16:21:46','2025-06-13 16:21:46'),
(18,10,'RETY33445',6,2,'2025-06-13 15:39:35','submitted','2025-06-13 16:39:35','2025-06-13 16:39:35'),
(19,10,'BNMV88990',6,2,'2025-06-14 19:58:53','submitted','2025-06-14 20:58:52','2025-06-14 20:58:52'),
(20,10,'PLKI77882',6,2,'2025-06-15 10:20:11','submitted','2025-06-15 11:20:11','2025-06-15 11:20:11'),
(21,11,'XZCV44551',6,2,'2025-06-15 10:50:12','submitted','2025-06-15 11:50:11','2025-06-15 11:50:11'),
(22,11,'TYUI99331',6,2,'2025-06-15 11:01:04','submitted','2025-06-15 12:01:03','2025-06-15 12:01:03'),
(23,11,'JKLO88226',6,2,'2025-06-15 11:05:22','submitted','2025-06-15 12:05:21','2025-06-15 12:05:21'),
(24,11,'ZXAS77889',6,2,'2025-06-15 11:11:52','submitted','2025-06-15 12:11:52','2025-06-15 12:11:52'),
(25,11,'WERU66543',6,2,'2025-06-15 11:23:44','submitted','2025-06-15 12:23:43','2025-06-15 12:23:43'),
(26,11,'YUIN55220',2,1,'2025-06-15 11:25:18','submitted','2025-06-15 12:25:17','2025-06-15 12:25:17'),
(27,12,'LMNB22334',6,2,'2025-06-15 11:37:38','submitted','2025-06-15 12:37:37','2025-06-15 12:37:37'),
(28,12,'QWER99001',6,2,'2025-06-15 11:52:29','submitted','2025-06-15 12:52:28','2025-06-15 12:52:28'),
(29,12,'TYGH88221',6,2,'2025-06-15 11:55:45','submitted','2025-06-15 12:55:44','2025-06-15 12:55:44'),
(30,12,'BNML66332',1,3,'2025-06-15 12:09:37','submitted','2025-06-15 13:09:36','2025-06-15 13:09:36'),
(31,12,'PLMN88220',1,3,'2025-06-15 12:23:09','submitted','2025-06-15 13:23:08','2025-06-15 13:23:08'),
(32,12,'UJMN55331',4,1,'2025-06-15 12:37:28','submitted','2025-06-15 13:37:27','2025-06-15 13:37:27'),
(33,13,'REZA22110',2,4,'2025-06-15 16:30:17','submitted','2025-06-15 17:30:16','2025-06-15 17:30:16'),
(34,14,'MNOP77331',4,2,'2025-06-15 16:34:28','submitted','2025-06-15 17:34:27','2025-06-15 17:34:27'),
(35,15,'LKJI44221',3,5,'2025-06-15 20:26:35','submitted','2025-06-15 21:26:35','2025-06-15 21:26:35'),
(36,16,'GHJK11992',6,4,'2025-06-15 20:37:48','submitted','2025-06-15 21:37:48','2025-06-15 21:37:48'),
(37,16,'XZCV88220',6,1,'2025-06-15 20:48:58','submitted','2025-06-15 21:48:58','2025-06-15 21:48:58'),
(38,16,'RTYU99112',2,4,'2025-06-15 20:50:38','submitted','2025-06-15 21:50:37','2025-06-15 21:50:37'),
(39,16,'QAZX77881',1,1,'2025-06-15 21:02:37','submitted','2025-06-15 22:02:36','2025-06-15 22:02:36'),
(40,16,'WSXC55330',1,4,'2025-06-15 21:24:34','submitted','2025-06-15 22:24:33','2025-06-15 22:24:33'),
(41,16,'REWT44128',5,1,'2025-06-15 21:38:08','submitted','2025-06-15 22:38:08','2025-06-15 22:38:08'),
(42,16,'LKOP77331',5,2,'2025-06-15 21:52:08','submitted','2025-06-15 22:52:07','2025-06-15 22:52:07'),
(43,16,'ZXCV55210',6,2,'2025-06-16 13:22:00','submitted','2025-06-16 14:22:00','2025-06-16 14:22:00'),
(44,17,'GHJK22991',6,4,'2025-06-16 13:30:29','submitted','2025-06-16 14:30:28','2025-06-16 14:30:28');
/*!40000 ALTER TABLE `declarations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `decujus`
--

DROP TABLE IF EXISTS `decujus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `decujus` (
  `decujus_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pension_number` varchar(9) DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `agency_id` int(11) DEFAULT NULL,
  `is_pension_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`decujus_id`),
  UNIQUE KEY `pension_number` (`pension_number`),
  KEY `idx_pension_number` (`pension_number`),
  KEY `fk_decujus_agency` (`agency_id`),
  CONSTRAINT `fk_decujus_agency` FOREIGN KEY (`agency_id`) REFERENCES `agencies` (`agency_id`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `decujus`
--

LOCK TABLES `decujus` WRITE;
/*!40000 ALTER TABLE `decujus` DISABLE KEYS */;
INSERT INTO `decujus` VALUES
(2,'QWER12345','Maria','Intern','1990-06-15',76,0,'2025-05-29 02:12:49','2025-06-01 21:18:47'),
(3,'TEST12345','Jean','Dupont','1950-05-15',75,0,'2025-06-01 21:23:05','2025-06-03 07:54:48'),
(4,'ABCD12345','Haj','Smail','1960-12-01',76,0,'2025-06-03 07:58:47','2025-06-03 08:23:24'),
(5,'ASDF12345','Rami','Mohamed','1960-01-12',76,0,'2025-06-03 08:44:49','2025-06-03 08:45:55'),
(6,'ASDF12346','Rami','Mohamed','1960-01-12',76,0,'2025-06-03 09:15:15','2025-06-03 09:15:34'),
(7,'12345QWER','Demy','Mohamed','1960-01-12',76,0,'2025-06-03 09:35:42','2025-06-03 09:35:58'),
(8,NULL,'Yacine','Klasd','1990-01-01',76,1,'2025-06-11 13:28:53','2025-06-11 13:28:53'),
(9,'ASDFGHJKL','adfa','Kla','1990-01-01',76,0,'2025-06-11 13:29:30','2025-06-11 13:29:56'),
(10,'ZXCV98765','Leila','Benali','1955-04-20',76,0,'2025-06-13 13:00:00','2025-06-13 15:59:05'),
(11,'LMNO54321','Sofia','Khaled','1958-09-10',76,0,'2025-06-13 13:10:00','2025-06-13 16:10:04'),
(12,'WISS12345','Wissam','Recham','1965-03-25',76,0,'2025-06-13 13:20:00','2025-06-13 16:12:41'),
(13,'MNOP67890','Omar','Zeroual','1952-11-08',76,0,'2025-06-13 13:30:00','2025-06-13 13:30:00'),
(14,'GHJK11223','Nadia','Belkacem','1957-07-30',76,0,'2025-06-13 13:40:00','2025-06-13 16:21:46'),
(15,'RETY33445','Karim','Amrani','1959-02-18',76,0,'2025-06-13 13:50:00','2025-06-13 16:39:35'),
(17,'BNMV88990','Youssef','Hamdi','1956-08-14',76,0,'2025-06-13 14:10:00','2025-06-14 20:58:52'),
(18,'PLKI77882','Samira','Dali','1954-04-02',76,0,'2025-06-13 14:20:00','2025-06-15 11:20:11'),
(20,'XZCV44551','Rachid','Boualem','1953-06-09',76,0,'2025-06-13 14:40:00','2025-06-15 11:50:11'),
(21,'TYUI99331','Salima','Brahimi','1950-12-22',76,0,'2025-06-13 14:50:00','2025-06-15 12:01:03'),
(23,'JKLO88226','Amina','Saidi','1963-05-06',76,0,'2025-06-13 15:10:00','2025-06-15 12:05:21'),
(25,'ZXAS77889','Lina','Guenifi','1960-02-17',76,0,'2025-06-13 15:30:00','2025-06-15 12:11:52'),
(26,'WERU66543','Tarek','Mansouri','1955-07-13',76,0,'2025-06-13 15:40:00','2025-06-15 12:23:43'),
(28,'YUIN55220','Zineb','Kerrad','1956-06-21',76,0,'2025-06-13 16:00:00','2025-06-15 12:25:17'),
(29,'LMNB22334','Walid','Sebti','1958-08-26',76,0,'2025-06-13 16:10:00','2025-06-15 12:37:37'),
(30,'QWER99001','Sonia','Meziane','1954-10-10',76,0,'2025-06-13 16:20:00','2025-06-15 12:52:28'),
(31,'TYGH88221','Hakim','Zerrouki','1952-01-30',76,0,'2025-06-13 16:30:00','2025-06-15 12:55:44'),
(32,'BNML66332','Karima','Fodil','1957-04-18',76,0,'2025-06-13 16:40:00','2025-06-15 13:09:36'),
(33,'PLMN88220','Nadir','Belkacem','1955-11-12',76,0,'2025-06-13 16:50:00','2025-06-15 13:23:08'),
(34,'UJMN55331','Nahla','Boukhalfa','1959-02-05',76,0,'2025-06-13 17:00:00','2025-06-15 13:37:27'),
(35,'REZA22110','Yassine','Merabet','1956-08-08',76,0,'2025-06-13 17:10:00','2025-06-15 17:30:16'),
(36,'MNOP77331','Sabrina','Tebani','1953-03-14',76,0,'2025-06-13 17:20:00','2025-06-15 17:34:27'),
(37,'LKJI44221','Imane','Cherif','1951-09-05',76,0,'2025-06-13 17:30:00','2025-06-15 21:26:35'),
(38,'GHJK11992','Khaled','Benaissa','1952-12-19',76,0,'2025-06-13 17:40:00','2025-06-15 21:37:48'),
(39,'XZCV88220','Leila','Hamidi','1955-06-07',76,0,'2025-06-13 17:50:00','2025-06-15 21:48:58'),
(40,'RTYU99112','Mourad','Khelifi','1950-04-22',76,0,'2025-06-13 18:00:00','2025-06-15 21:50:37'),
(41,'QAZX77881','Sofia','Touati','1958-10-30',76,0,'2025-06-13 18:10:00','2025-06-15 22:02:36'),
(42,'WSXC55330','Nour','Bouderbala','1957-07-11',76,0,'2025-06-13 18:20:00','2025-06-15 22:24:33'),
(43,'REWT44128','Samir','Mehanna','1951-12-19',76,0,'2025-06-13 17:30:00','2025-06-15 22:38:08'),
(44,'LKOP77331','Nassima','Hamdi','1958-10-04',76,0,'2025-06-13 17:40:00','2025-06-15 22:52:07'),
(45,'ZXCV55210','Rachid','Merabet','1959-07-22',76,0,'2025-06-13 17:50:00','2025-06-16 14:22:00'),
(46,'GHJK22991','Salima','Djebar','1956-05-11',76,0,'2025-06-13 18:00:00','2025-06-16 14:30:28'),
(47,'BNVC11887','Mourad','Saadi','1957-09-09',76,1,'2025-06-13 18:10:00','2025-06-13 18:10:00');
/*!40000 ALTER TABLE `decujus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document_types`
--

DROP TABLE IF EXISTS `document_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_types` (
  `document_type_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT 'Nom du document',
  `description` text DEFAULT NULL COMMENT 'Description optionnelle du document',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`document_type_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Liste maîtresse de tous les types de documents possibles';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document_types`
--

LOCK TABLES `document_types` WRITE;
/*!40000 ALTER TABLE `document_types` DISABLE KEYS */;
INSERT INTO `document_types` VALUES
(1,'Formulaire de demande de pension de réversion dûment renseigné','Le formulaire principal de demande, complété.','2025-04-23 20:57:57','2025-04-23 20:57:57'),
(2,'Fiche familiale d\'état civil','Document officiel indiquant la composition de la famille et l\'état civil.','2025-04-23 20:57:57','2025-04-23 20:57:57'),
(3,'Photocopie de la pièce d\'identité','Copie de la carte d\'identité nationale, passeport, etc. du demandeur.','2025-04-23 20:57:57','2025-04-23 20:57:57'),
(4,'Relevé d\'identité postale ou bancaire','Document indiquant les détails du compte bancaire pour le paiement (RIB).','2025-04-23 20:57:57','2025-04-23 20:57:57'),
(5,'Attestation de non activité signée par deux (02) témoins et légalisée par l\'APC','Attestation confirmant que le demandeur n\'est pas employé, signée par deux témoins et légalisée par l\'APC.','2025-04-23 20:57:57','2025-04-23 20:57:57'),
(6,'Certificat de scolarité ou d’apprentissage','Preuve d\'inscription actuelle dans un programme d\'éducation ou d\'apprentissage.','2025-04-23 20:57:57','2025-04-23 20:57:57'),
(7,'Certificat médical et photocopie de la carte d’handicapé indiquant le taux d’incapacité','Preuve médicale d\'invalidité et copie de la carte d\'invalidité officielle, incluant le taux d\'incapacité. Requis seulement si applicable.','2025-04-23 20:57:57','2025-04-23 20:57:57'),
(8,'Attestation de non mariage signée par deux (02) témoins et légalisée par l\'APC','Attestation confirmant que le demandeur n\'est pas marié, signée par deux témoins et légalisée par l\'APC.','2025-04-23 20:57:57','2025-04-23 20:57:57'),
(9,'Fiche familiale d’état civil du demandeur','Document officiel indiquant la propre composition familiale et l\'état civil du demandeur (spécifique aux Ascendants).','2025-04-23 20:57:57','2025-04-23 20:57:57'),
(10,'Déclaration des revenus mensuels (fiche de paie, relevé des émoluments, etc…)','Preuve des revenus mensuels du demandeur (fiche de paie, relevé des émoluments, etc.).','2025-04-23 20:57:57','2025-04-23 20:57:57');
/*!40000 ALTER TABLE `document_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `documents`
--

DROP TABLE IF EXISTS `documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `documents` (
  `document_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `declaration_id` int(10) unsigned NOT NULL,
  `file_path` varchar(512) NOT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `upload_timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`document_id`),
  KEY `fk_documents_declaration_idx` (`declaration_id`),
  CONSTRAINT `fk_documents_declaration` FOREIGN KEY (`declaration_id`) REFERENCES `declarations` (`declaration_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `documents`
--

LOCK TABLES `documents` WRITE;
/*!40000 ALTER TABLE `documents` DISABLE KEYS */;
/*!40000 ALTER TABLE `documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `type` enum('document_review','declaration_approved','declaration_rejected','general') NOT NULL DEFAULT 'general',
  `related_id` int(11) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `sent_at` timestamp NULL DEFAULT current_timestamp(),
  `read_at` timestamp NULL DEFAULT NULL,
  `created_by_admin_id` int(10) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`notification_id`),
  KEY `created_by_admin_id` (`created_by_admin_id`),
  KEY `idx_user_notifications` (`user_id`,`sent_at`),
  KEY `idx_notification_type` (`type`),
  KEY `idx_unread_notifications` (`user_id`,`is_read`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `notifications_ibfk_2` FOREIGN KEY (`created_by_admin_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES
(1,17,'Test Notification from Admin','This is a test notification sent from the admin panel to verify the notification system is working correctly.','general',NULL,1,'2025-06-16 20:25:55','2025-06-16 21:03:10',19,'2025-06-16 20:25:55'),
(2,17,'🎉 Flutter Integration Test','This is a test notification to verify that your Flutter app can receive and display notifications from the admin panel! If you can see this, the integration is working perfectly.','general',NULL,1,'2025-06-16 20:37:56','2025-06-16 21:03:08',19,'2025-06-16 20:37:56'),
(3,17,'🔔 Test Push Notification','This is a live test notification sent directly to your phone! If you see this as a push notification popup, the system is working perfectly! 📱✅','general',NULL,1,'2025-06-16 21:04:10','2025-06-16 21:04:18',19,'2025-06-16 21:04:10'),
(4,17,'🚀 Second Test Notification','This is the second test notification! Are you receiving push notifications on your phone? Please check if this appears as a popup! 📲🔔','document_review',NULL,0,'2025-06-16 21:07:25',NULL,19,'2025-06-16 21:07:25');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `relationship_required_documents`
--

DROP TABLE IF EXISTS `relationship_required_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `relationship_required_documents` (
  `relationship_required_document_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `relationship_id` int(10) unsigned NOT NULL COMMENT 'FK vers la table relationships',
  `document_type_id` int(10) unsigned NOT NULL COMMENT 'FK vers la table document_types',
  `is_mandatory` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Ce document est-il obligatoire pour cette relation ?',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`relationship_required_document_id`),
  UNIQUE KEY `uq_relationship_document` (`relationship_id`,`document_type_id`),
  KEY `document_type_id` (`document_type_id`),
  CONSTRAINT `relationship_required_documents_ibfk_1` FOREIGN KEY (`relationship_id`) REFERENCES `relationships` (`id`) ON DELETE CASCADE,
  CONSTRAINT `relationship_required_documents_ibfk_2` FOREIGN KEY (`document_type_id`) REFERENCES `document_types` (`document_type_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Définit quels documents sont requis pour des relations spécifiques';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `relationship_required_documents`
--

LOCK TABLES `relationship_required_documents` WRITE;
/*!40000 ALTER TABLE `relationship_required_documents` DISABLE KEYS */;
INSERT INTO `relationship_required_documents` VALUES
(1,1,1,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(2,1,2,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(3,1,3,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(4,1,4,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(5,2,1,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(6,2,2,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(7,2,3,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(8,2,4,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(9,3,1,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(10,3,3,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(11,3,4,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(12,3,5,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(13,3,6,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(14,3,7,0,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(15,4,1,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(16,4,3,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(17,4,4,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(18,4,5,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(19,4,8,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(20,5,1,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(21,5,3,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(22,5,4,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(23,5,9,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(24,5,10,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(25,6,1,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(26,6,3,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(27,6,4,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(28,6,9,1,'2025-04-23 20:59:57','2025-04-23 20:59:57'),
(29,6,10,1,'2025-04-23 20:59:57','2025-04-23 20:59:57');
/*!40000 ALTER TABLE `relationship_required_documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `relationships`
--

DROP TABLE IF EXISTS `relationships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `relationships` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `description` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `relationships`
--

LOCK TABLES `relationships` WRITE;
/*!40000 ALTER TABLE `relationships` DISABLE KEYS */;
INSERT INTO `relationships` VALUES
(6,'Ascendant (Femme)'),
(5,'Ascendant (Homme)'),
(2,'Conjoint (Femme)'),
(1,'Conjoint (Homme)'),
(4,'Enfant majeur (Femme)'),
(3,'Enfant majeur (Homme)');
/*!40000 ALTER TABLE `relationships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_device_tokens`
--

DROP TABLE IF EXISTS `user_device_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_device_tokens` (
  `token_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `device_token` varchar(255) NOT NULL,
  `platform` enum('android','ios') NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `unique_user_token` (`user_id`,`device_token`),
  KEY `idx_active_tokens` (`user_id`,`is_active`),
  CONSTRAINT `user_device_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_device_tokens`
--

LOCK TABLES `user_device_tokens` WRITE;
/*!40000 ALTER TABLE `user_device_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_device_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('user','admin') NOT NULL DEFAULT 'user' COMMENT 'User role: user or admin',
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_email` (`email`),
  KEY `idx_users_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,'testuser@example.com','$2b$12$T7L/o7Px.SGle.4Dsiku9OB0hWPdG66FM8UOR6qZ9j9roAodsKM6S','user','Test','User','2025-04-16 14:22:33','2025-04-16 14:22:33',NULL),
(2,'adminuser@example.com','$2b$12$X.dyY85XJrVz3GFH52AbVexP2KCSrCFvOB5oU.DBzCgBYpdnVLbH6','user','Admin','User','2025-04-16 14:51:05','2025-04-16 14:51:05',NULL),
(3,'adminusergg@example.com','$2b$12$Hdqfp8VEOgKETXpd0lS1LOOgqeeq2z6iPXRubgS8zW1WrPELDz5V6','user','Admin','User','2025-04-16 14:54:16','2025-04-16 14:54:16',NULL),
(4,'adminuseaargg@example.com','$2b$12$VE3JdNalRO1wLYYwwqqfEe68Kv/x9h70v7DkDV5yjwyoculAck1re','user','Admin','User','2025-04-16 14:54:48','2025-04-16 14:54:48',NULL),
(5,'user@example.com','$2b$12$NEQBls8IMXRU9udFFa0mjOgiw1K1E7l67cRyGc.9oPCOZhBJ4EVDq','user','demy','xd','2025-04-16 16:13:48','2025-04-16 16:13:48',NULL),
(6,'john.doe@example.com','$2b$12$unWoSaV7bGSNwWn.KVuVnOOKun2GoQzJf5sitGOP09UFNcPnELR9q','user','John','Doe','2025-04-29 12:40:26','2025-04-29 12:40:26',NULL),
(7,'rami2004@gmail.com','$2b$12$tjdmpgoQhcAWDpZq4nrIwuUhuPyJkxi/L81pKEWfHf3q1ChqM0TXO','user','rami','mohamed','2025-05-16 19:29:07','2025-05-16 19:29:07',NULL),
(8,'test@test.com','$2b$12$4pa2aTQkF.RI8hPc761Xke5KZ0a4IGG/BGRmNeUmAIFqyGTVDEEoy','user','test','test','2025-05-16 19:36:16','2025-05-16 19:36:16',NULL),
(9,'adminadmin@gmail.com','$2b$12$UB0tPTn78O/jr9lfI48jn.b6YfKK8/nYPaHkIDJclPQibQRhiBHDG','user','admin','admin','2025-05-16 20:11:47','2025-05-16 20:11:47',NULL),
(10,'newuser01@gmail.com','$2b$12$/DEviU/gq7LjSeYijwJN2uBhWZ0jvchPtg/y4tX0LqtakfP1E0VJm','user','Rami','Mohamed','2025-05-29 01:49:24','2025-05-29 01:49:24',NULL),
(11,'newuser02@gmail.com','$2b$12$oj6PujAV/s.eoirHynSpWuBpY1k5wU8F4jTexqV6YeJ7lBSKIaiGu','user','newuser','newuser','2025-06-15 11:49:08','2025-06-15 11:49:08',NULL),
(12,'newuser03@gmail.com','$2b$12$YN1/FseYPNRrn2DPY6.l2eNR48aI8.3mkgFxHMDjhe809TMfzg/Ou','user','Rami','Mohamed','2025-06-15 12:37:15','2025-06-15 12:37:15',NULL),
(13,'newuser04@gmail.com','$2b$12$TFbcP5w0FRkP/l2jHTEW5OaxfU3Tgg1EP8ZhG1wrjJp3WntvTToDe','user','Rami','Mohamed','2025-06-15 17:29:51','2025-06-15 17:29:51',NULL),
(14,'newuser05@gmail.com','$2b$12$.dMY5FpGidpimE0KN/1fwOOzM/1Aht9kEmZJUyZd.JHtPtduS5sY6','user','Wissam','Rami','2025-06-15 17:33:25','2025-06-15 17:33:25',NULL),
(15,'newuser06@gmail.com','$2b$12$cun19OEpQPSdgWmgaF6C3OI/HwVEC6dbVj4qacfm3JIMAPzQz6Rq6','user','Smail','Ramk','2025-06-15 21:25:43','2025-06-15 21:25:43',NULL),
(16,'newuser07@gmail.com','$2b$12$v4M7kvvdIxNa7Hd.z157c.EOR4GFFjo87/bG/mOk65j8MsSKISZNu','user','Papa','Johns','2025-06-15 21:37:01','2025-06-15 21:37:01',NULL),
(17,'newuser00@gmail.com','$2b$12$ZOA/BsruPHsYvN5vyCIqXubeeotpfaOdYXKx7SxR9xUANocZY5IsW','user','Amazigh','Matoub','2025-06-16 14:28:40','2025-06-16 14:28:40',NULL),
(18,'nativi@gmail.com','$2b$12$aphUAimulpDRvNbXBypHPetjGLXXf1MdfkCMmxX3quTOpnZuWFx9G','user','Kabylie','Boys','2025-06-16 14:42:13','2025-06-16 14:42:13',NULL),
(19,'admin@example.com','$2b$12$GtYs6.k8OwM/EB24tIr8DOP2gqJQCoc8xWiXEfgAYjUj5ep.EWMLO','admin','Admin','User','2025-06-16 20:08:35','2025-06-16 20:08:35',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2025-06-17  2:08:54
