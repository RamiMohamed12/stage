-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: localhost    Database: internship
-- ------------------------------------------------------
-- Server version	8.3.0

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

--
-- Table structure for table `agencies`
--

DROP TABLE IF EXISTS `agencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agencies` (
  `agency_id` int NOT NULL AUTO_INCREMENT,
  `name_agency` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`agency_id`)
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agencies`
--

LOCK TABLES `agencies` WRITE;
/*!40000 ALTER TABLE `agencies` DISABLE KEYS */;
INSERT INTO `agencies` VALUES (1,'Adrar'),(2,'Chlef'),(3,'Laghouat'),(4,'Oum El Bouaghi'),(5,'Batna'),(6,'Béjaïa'),(7,'Biskra'),(8,'Béchar'),(9,'Blida'),(10,'Bouira'),(11,'Tamanrasset'),(12,'Tébessa'),(13,'Tlemcen'),(14,'Tiaret'),(15,'Tizi Ouzou'),(16,'Alger Centre'),(17,'Alger Ouest'),(18,'Alger West'),(19,'Djelfa'),(20,'Jijel'),(21,'Sétif'),(22,'Saïda'),(23,'Skikda'),(24,'Sidi Bel Abbès'),(25,'Annaba'),(26,'Guelma'),(27,'Constantine'),(28,'Médéa'),(29,'Mostaganem'),(30,'M\'Sila'),(31,'Mascara'),(32,'Ouargla'),(33,'Oran'),(34,'El Bayadh'),(35,'Illizi'),(36,'Bordj Bou Arreridj'),(37,'Boumerdès'),(38,'El Tarf'),(39,'Tindouf'),(40,'Tissemsilt'),(41,'El Oued'),(42,'Khenchela'),(43,'Souk Ahras'),(44,'Tipaza'),(45,'Mila'),(46,'Aïn Defla'),(47,'Naâma'),(48,'Aïn Témouchent'),(49,'Ghardaïa'),(50,'Relizane'),(51,'Timimoun'),(52,'Bordj Badji Mokhtar'),(53,'Ouled Djellal'),(54,'Béni Abbès'),(55,'In Salah'),(56,'In Guezzam'),(57,'Touggourt'),(58,'Djanet'),(59,'El M\'Ghair'),(60,'El Meniaa');
/*!40000 ALTER TABLE `agencies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `declarations`
--

DROP TABLE IF EXISTS `declarations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `declarations` (
  `declaration_id` int unsigned NOT NULL AUTO_INCREMENT,
  `applicant_user_id` int unsigned NOT NULL,
  `decujus_pension_number` varchar(9) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `declaration_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('submitted','processing','approved','rejected','requires_info') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'submitted',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`declaration_id`),
  KEY `fk_declarations_user_idx` (`applicant_user_id`),
  KEY `idx_decujus_pension_number` (`decujus_pension_number`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_declarations_user` FOREIGN KEY (`applicant_user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `declarations`
--

LOCK TABLES `declarations` WRITE;
/*!40000 ALTER TABLE `declarations` DISABLE KEYS */;
/*!40000 ALTER TABLE `declarations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `decujus`
--

DROP TABLE IF EXISTS `decujus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `decujus` (
  `decujus_id` int unsigned NOT NULL AUTO_INCREMENT,
  `pension_number` varchar(9) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `agency_id` int DEFAULT NULL,
  `is_pension_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`decujus_id`),
  UNIQUE KEY `pension_number` (`pension_number`),
  KEY `idx_pension_number` (`pension_number`),
  KEY `fk_decujus_agency` (`agency_id`),
  CONSTRAINT `fk_decujus_agency` FOREIGN KEY (`agency_id`) REFERENCES `agencies` (`agency_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `decujus`
--

LOCK TABLES `decujus` WRITE;
/*!40000 ALTER TABLE `decujus` DISABLE KEYS */;
/*!40000 ALTER TABLE `decujus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `documents`
--

DROP TABLE IF EXISTS `documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documents` (
  `document_id` int unsigned NOT NULL AUTO_INCREMENT,
  `declaration_id` int unsigned NOT NULL,
  `document_type` enum('acte_deces','justificatif_lien','piece_identite','autre') COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_path` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL,
  `original_filename` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `upload_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ocr_extracted_text_arabic` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`document_id`),
  KEY `fk_documents_declaration_idx` (`declaration_id`),
  KEY `idx_document_type` (`document_type`),
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
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('user','admin') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'user' COMMENT 'User role: user or admin',
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_email` (`email`),
  KEY `idx_users_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'testuser@example.com','$2b$12$T7L/o7Px.SGle.4Dsiku9OB0hWPdG66FM8UOR6qZ9j9roAodsKM6S','user','Test','User','2025-04-16 14:22:33','2025-04-16 14:22:33',NULL),(2,'adminuser@example.com','$2b$12$X.dyY85XJrVz3GFH52AbVexP2KCSrCFvOB5oU.DBzCgBYpdnVLbH6','user','Admin','User','2025-04-16 14:51:05','2025-04-16 14:51:05',NULL),(3,'adminusergg@example.com','$2b$12$Hdqfp8VEOgKETXpd0lS1LOOgqeeq2z6iPXRubgS8zW1WrPELDz5V6','user','Admin','User','2025-04-16 14:54:16','2025-04-16 14:54:16',NULL),(4,'adminuseaargg@example.com','$2b$12$VE3JdNalRO1wLYYwwqqfEe68Kv/x9h70v7DkDV5yjwyoculAck1re','user','Admin','User','2025-04-16 14:54:48','2025-04-16 14:54:48',NULL),(5,'user@example.com','$2b$12$NEQBls8IMXRU9udFFa0mjOgiw1K1E7l67cRyGc.9oPCOZhBJ4EVDq','user','demy','xd','2025-04-16 16:13:48','2025-04-16 16:13:48',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-04-20 23:10:25
