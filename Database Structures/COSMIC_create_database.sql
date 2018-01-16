CREATE DATABASE `COSMIC_NEW`;

USE `COSMIC_NEW`;

#------------------------------

CREATE TABLE variants (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	chr VARCHAR(15) NOT NULL,
	pos INT UNSIGNED NOT NULL,
	ref VARCHAR(4000) NOT NULL,
	alt VARCHAR(4000) NOT NULL
);

CREATE INDEX variant on variants (chr, pos, ref(1000), alt(1000));

-- (1000) above indexes only up to the first 1000 characters

#------------------------------

CREATE TABLE cosmic_numbers (
	cosmic_number VARCHAR(100) NOT NULL UNIQUE PRIMARY KEY,
	cosmic_count INT UNSIGNED NOT NULL,
	cosmic_primary_site VARCHAR(500) NOT NULL,
	cosmic_primary_histology VARCHAR(500) NOT NULL
);

#------------------------------

CREATE TABLE cosmic_number_to_variant (
	cosmic_number VARCHAR(100) NOT NULL,
	variant_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (cosmic_number) REFERENCES cosmic_numbers(cosmic_number),
	FOREIGN KEY (variant_id) REFERENCES variants(id),
	PRIMARY KEY(cosmic_number, variant_id)
);

CREATE INDEX variant_id on cosmic_number_to_variant (variant_id);
CREATE INDEX cosmic_number on cosmic_number_to_variant (cosmic_number);

#------------------------------

/*
View the information for a particular variant:
SELECT 
	variants.chr,
	variants.pos,
	variants.ref,
	variants.alt,
	cosmic_numbers.cosmic_number,
	cosmic_numbers.count,
	cosmic_numbers.primary_site,
	cosmic_numbers.primary_histology
FROM 
	variants
INNER JOIN cosmic_number_to_variant ON cosmic_number_to_variant.variant_id = variants.id 
INNER JOIN cosmic_numbers ON cosmic_numbers.cosmic_number = cosmic_number_to_variant.cosmic_number 
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