CREATE DATABASE `MGRB_NEW`;

USE `MGRB_NEW`;

# The max lengths of the ref and alt columns was determined by looking at the distribution of lengths of the ref and alt alleles in the MGRB VCF, this should be redone when updating

CREATE TABLE mgrb_vafs (
	ID INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	chr VARCHAR(30) NOT NULL,
	pos INT UNSIGNED NOT NULL,
	ref VARCHAR(320) NOT NULL,
	alt VARCHAR(762) NOT NULL,
	ac MEDIUMINT UNSIGNED NOT NULL,
	an MEDIUMINT UNSIGNED NOT NULL,
	filters VARCHAR(300)
);

CREATE INDEX query ON mgrb_vafs (chr, pos, ref, alt);