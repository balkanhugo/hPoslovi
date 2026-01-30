-- ========================================
-- hPoslovi Database Schema Fix
-- ========================================
-- This script will check and fix your database schema
-- Run this SQL script to ensure compatibility

-- First, let's check if the table exists and what columns it has
-- If the table exists with wrong column name, we'll fix it

-- Option 1: If table uses 'jobname' instead of 'job_name', add the correct column
-- Uncomment the line below if your table has 'jobname' column
-- ALTER TABLE `hposlovi_vehicles` CHANGE COLUMN `jobname` `job_name` VARCHAR(50) NOT NULL;

-- Option 2: If table doesn't exist yet, create it with the correct schema
CREATE TABLE IF NOT EXISTS `hposlovi_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `model` varchar(50) NOT NULL,
  `color_r` int(11) DEFAULT 255,
  `color_g` int(11) DEFAULT 255,
  `color_b` int(11) DEFAULT 255,
  `plate` varchar(20) DEFAULT NULL,
  `fullkit` tinyint(1) DEFAULT 0,
  `min_grade` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `job_name` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ensure all other required tables exist
CREATE TABLE IF NOT EXISTS `hposlovi_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL UNIQUE,
  `job_label` varchar(100) NOT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `job_name` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hposlovi_positions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `position_type` varchar(50) NOT NULL,
  `position_id` varchar(50) DEFAULT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `heading` float DEFAULT NULL,
  `extra_data` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `job_name` (`job_name`),
  CONSTRAINT `fk_positions_job` FOREIGN KEY (`job_name`) REFERENCES `hposlovi_jobs` (`job_name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hposlovi_inventories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `inventory_id` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `slots` int(11) NOT NULL DEFAULT 50,
  `max_weight` int(11) NOT NULL DEFAULT 100000,
  `min_grade` int(11) DEFAULT 0,
  `x` float DEFAULT NULL,
  `y` float DEFAULT NULL,
  `z` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `job_name` (`job_name`),
  CONSTRAINT `fk_inventories_job` FOREIGN KEY (`job_name`) REFERENCES `hposlovi_jobs` (`job_name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hposlovi_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `outfit_name` varchar(100) NOT NULL,
  `outfit_data` longtext NOT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_outfit` (`job_name`, `outfit_name`),
  KEY `job_name` (`job_name`),
  CONSTRAINT `fk_outfits_job` FOREIGN KEY (`job_name`) REFERENCES `hposlovi_jobs` (`job_name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add foreign key constraint to vehicles table if it doesn't exist
-- This ensures when a job is deleted, all its vehicles are also deleted
SET @query = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'hposlovi_vehicles'
    AND CONSTRAINT_NAME = 'fk_vehicles_job'
);

SET @query = IF(@query = 0, 
    'ALTER TABLE `hposlovi_vehicles` ADD CONSTRAINT `fk_vehicles_job` FOREIGN KEY (`job_name`) REFERENCES `hposlovi_jobs` (`job_name`) ON DELETE CASCADE',
    'SELECT "Foreign key already exists" AS message'
);

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verification queries (these won't modify anything, just check)
-- You can run these separately to verify your schema

-- Check hposlovi_vehicles structure
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'hposlovi_vehicles';

-- Check all hPoslovi tables exist
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME LIKE 'hposlovi_%';
