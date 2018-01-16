CREATE DATABASE `MITOMAP_NEW`;

USE `MITOMAP_NEW`;

#------------------------------

CREATE TABLE `mitomap` (
	ID INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	chr VARCHAR(15) NOT NULL,
	pos INT UNSIGNED NOT NULL,
	ref VARCHAR(1000) NOT NULL,
	alt VARCHAR(1000) NOT NULL,
	AC VARCHAR(10),
	AF VARCHAR(10),
	Disease VARCHAR(1000),
	DiseaseStatus VARCHAR(1000)
);

CREATE INDEX mitomap_query ON `mitomap` (chr, pos, ref, alt);

/*
Queries to manually extract information from this database

Extract all MITOMAP information for a specific variant:
SELECT 
	*
FROM 
	MITOMAP.mitomap 
WHERE 
	chr = '' 
AND 
	pos = '' 
AND
	ref = '' 
AND 
	alt = ''
;
*/