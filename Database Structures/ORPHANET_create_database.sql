CREATE DATABASE `ORPHANET_NEW`;

USE `ORPHANET_NEW`;


CREATE TABLE orphanet_disorders (
	id INT UNSIGNED NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
	orphanet_number INT UNSIGNED NOT NULL UNIQUE,
	orphanet_name VARCHAR(500) NOT NULL
);

CREATE INDEX orphanet_number_index on orphanet_disorders (orphanet_number);


CREATE TABLE orphanet_genes (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	gene_name VARCHAR(30) NOT NULL UNIQUE
);

CREATE INDEX gene_name_index on orphanet_genes (gene_name);


CREATE TABLE orphanet_inheritances (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	inheritance_name VARCHAR(200) NOT NULL UNIQUE
);


CREATE TABLE orphanet_age_of_onsets (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	age_of_onset VARCHAR(100) NOT NULL UNIQUE
);


CREATE TABLE association_types (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	association_type VARCHAR(200) NOT NULL UNIQUE
);


CREATE TABLE association_statuses (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	association_status VARCHAR(100) NOT NULL UNIQUE
);


CREATE TABLE genes_to_disorders (
	gene_id INT UNSIGNED NOT NULL,
	disorder_id INT UNSIGNED NOT NULL,
	association_type_id INT UNSIGNED NOT NULL,
	association_status_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (gene_id) REFERENCES orphanet_genes(id),
	FOREIGN KEY (disorder_id) REFERENCES orphanet_disorders(id),
	FOREIGN KEY (association_type_id) REFERENCES association_types(id),
	FOREIGN KEY (association_status_id) REFERENCES association_statuses(id),
	PRIMARY KEY (gene_id, disorder_id, association_type_id, association_status_id)
);

CREATE INDEX disorder_id_index on genes_to_disorders (disorder_id);
CREATE INDEX gene_id_index on genes_to_disorders (gene_id);


CREATE TABLE age_of_onsets_to_disorders (
	age_of_onset_id INT UNSIGNED NOT NULL,
	disorder_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (age_of_onset_id) REFERENCES orphanet_age_of_onsets(id),
	FOREIGN KEY (disorder_id) REFERENCES orphanet_disorders(id),
	PRIMARY KEY (age_of_onset_id, disorder_id)
);

CREATE INDEX disorder_id_index on age_of_onsets_to_disorders (disorder_id);


CREATE TABLE inheritances_to_disorders (
	inheritance_id INT UNSIGNED NOT NULL,
	disorder_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (inheritance_id) REFERENCES orphanet_inheritances(id),
	FOREIGN KEY (disorder_id) REFERENCES orphanet_disorders(id),
	PRIMARY KEY (inheritance_id, disorder_id)
);

CREATE INDEX disorder_id_index on inheritances_to_disorders (disorder_id);


/*
View the information for a particular gene:
SELECT 
	ORPHANET.orphanet_genes.gene_name,
	ORPHANET.orphanet_disorders.orphanet_name,
	ORPHANET.orphanet_disorders.orphanet_number,
	ORPHANET.association_types.association_type,
	ORPHANET.association_statuses.association_status,
	ORPHANET.orphanet_inheritances.inheritance_name,
	ORPHANET.orphanet_age_of_onsets.age_of_onset
FROM 
	ORPHANET.orphanet_genes 
INNER JOIN ORPHANET.genes_to_disorders ON ORPHANET.genes_to_disorders.gene_id = ORPHANET.orphanet_genes.id 
INNER JOIN ORPHANET.orphanet_disorders ON ORPHANET.orphanet_disorders.id = ORPHANET.genes_to_disorders.disorder_id 
LEFT JOIN ORPHANET.association_types ON ORPHANET.association_types.id = ORPHANET.genes_to_disorders.association_type_id 
LEFT JOIN ORPHANET.association_statuses ON ORPHANET.association_statuses.id = ORPHANET.genes_to_disorders.association_status_id 
LEFT JOIN ORPHANET.age_of_onsets_to_disorders ON ORPHANET.age_of_onsets_to_disorders.disorder_id = ORPHANET.orphanet_disorders.id 
LEFT JOIN ORPHANET.inheritances_to_disorders ON ORPHANET.inheritances_to_disorders.disorder_id = ORPHANET.orphanet_disorders.id 
LEFT JOIN ORPHANET.orphanet_age_of_onsets ON ORPHANET.orphanet_age_of_onsets.id = ORPHANET.age_of_onsets_to_disorders.age_of_onset_id 
LEFT JOIN ORPHANET.orphanet_inheritances ON ORPHANET.orphanet_inheritances.id = ORPHANET.inheritances_to_disorders.inheritance_id 
WHERE 
	ORPHANET.orphanet_genes.gene_name = ''
;
*/