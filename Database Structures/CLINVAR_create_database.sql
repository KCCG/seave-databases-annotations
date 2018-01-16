CREATE DATABASE `CLINVAR_NEW`;

USE `CLINVAR_NEW`;

#------------------------------

CREATE TABLE `clinvar` (
	ID INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	chr VARCHAR(15) NOT NULL,
	position INT UNSIGNED NOT NULL,
	ref VARCHAR(1000) NOT NULL,
	alt VARCHAR(1000) NOT NULL,
	clinvar_rs VARCHAR(20) NOT NULL,
	clinsig VARCHAR(100) NOT NULL,
	clintrait VARCHAR(1000) NOT NULL
);

CREATE INDEX clinvar_query ON `clinvar` (chr, position, ref, alt);