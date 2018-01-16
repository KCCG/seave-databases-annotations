CREATE DATABASE `COSMIC_CGC_NEW`;

USE `COSMIC_CGC_NEW`;

#------------------------------

CREATE TABLE `cosmic_cgc` (
	ID INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	gene VARCHAR(50) NOT NULL,
	associations VARCHAR(3000) NOT NULL,
	mutation_types VARCHAR(100) NOT NULL,
	translocation_partner VARCHAR(3000) NOT NULL
);

CREATE INDEX COSMIC_CGC_query ON `cosmic_cgc` (gene);

/*
Queries to manually extract information from this database

Extract all COSMIC_CGC information for a specific gene:
SELECT 
	*
FROM 
	COSMIC_CGC.cosmic_cgc 
WHERE 
	gene = ''
;
*/