CREATE DATABASE `RVIS_NEW`;

USE `RVIS_NEW`;

#------------------------------

CREATE TABLE `rvis` (
	ID INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	gene VARCHAR(50) NOT NULL,
	percentile VARCHAR(30) NOT NULL
);

CREATE INDEX rvis_query ON `rvis` (gene);
