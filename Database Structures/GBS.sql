CREATE DATABASE GBS;

USE GBS;

CREATE TABLE event_types (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	event_type VARCHAR(50) NOT NULL UNIQUE
);

#------------------------------

CREATE TABLE methods (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	method_name VARCHAR(100) NOT NULL UNIQUE
);

#------------------------------

CREATE TABLE chromosomes (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	chromosome VARCHAR(30) NOT NULL UNIQUE
);

#------------------------------

CREATE TABLE block_store (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	event_type_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (event_type_id) REFERENCES event_types(id) ON DELETE CASCADE ON UPDATE CASCADE,
	event_cn DECIMAL(5,2),
	method_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (method_id) REFERENCES methods(id) ON DELETE CASCADE ON UPDATE CASCADE,
	chr_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (chr_id) REFERENCES chromosomes(id) ON DELETE CASCADE ON UPDATE CASCADE,
	`start` INT UNSIGNED NOT NULL,
	`end` INT UNSIGNED NOT NULL,
	date_added DATETIME NOT NULL
);

CREATE INDEX method_id ON GBS.block_store (method_id);
CREATE INDEX event_type_id ON GBS.block_store (event_type_id);
CREATE INDEX chr_id ON GBS.block_store (chr_id);
CREATE INDEX `start` ON GBS.block_store (`start`);
CREATE INDEX `end` ON GBS.block_store (`end`);
CREATE INDEX event_cn ON GBS.block_store (event_cn);

#------------------------------

CREATE TABLE link_types (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	link_type VARCHAR(128) NOT NULL UNIQUE
);

#------------------------------

CREATE TABLE links (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	link_type_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (link_type_id) REFERENCES link_types(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX link_type_id ON GBS.links (link_type_id);

#------------------------------

CREATE TABLE event_links (
	link_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (link_id) REFERENCES links(id) ON DELETE CASCADE ON UPDATE CASCADE,
	block_store_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (block_store_id) REFERENCES block_store(id) ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY(link_id, block_store_id)
);

CREATE INDEX link_id ON GBS.event_links (link_id);
CREATE INDEX block_store_id ON GBS.event_links (block_store_id);

#------------------------------

CREATE TABLE samples (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	sample_name VARCHAR(128) BINARY NOT NULL UNIQUE # BINARY to make this column case-sensitive so 'test' and 'Test' can be different rows
);

#------------------------------

CREATE TABLE external_sample_names (
	id INT UNSIGNED NOT NULL PRIMARY KEY,
	FOREIGN KEY (id) REFERENCES samples(id) ON DELETE CASCADE ON UPDATE CASCADE,
	external_name VARCHAR(128) NOT NULL
);

#------------------------------

CREATE TABLE sample_groups (
	block_store_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (block_store_id) REFERENCES block_store(id) ON DELETE CASCADE ON UPDATE CASCADE,
	sample_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (sample_id) REFERENCES samples(id) ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY(block_store_id, sample_id)
);

CREATE INDEX sample_id ON GBS.sample_groups (sample_id);
CREATE INDEX block_store_id ON GBS.sample_groups (block_store_id);

#------------------------------

CREATE TABLE annotation_tags (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	tag_name VARCHAR(50) NOT NULL UNIQUE
);

#------------------------------

CREATE TABLE annotation_values (
	block_store_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (block_store_id) REFERENCES block_store(id) ON DELETE CASCADE ON UPDATE CASCADE,
	sample_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (sample_id) REFERENCES samples(id) ON DELETE CASCADE ON UPDATE CASCADE,
	annotation_id INT UNSIGNED NOT NULL,
	FOREIGN KEY (annotation_id) REFERENCES annotation_tags(id) ON DELETE CASCADE ON UPDATE CASCADE,
	annotation_value VARCHAR(50) NOT NULL,
	PRIMARY KEY(block_store_id, sample_id, annotation_id)
);

CREATE INDEX block_store_id ON GBS.annotation_values (block_store_id);
CREATE INDEX sample_id ON GBS.annotation_values (sample_id);
CREATE INDEX annotation_id ON GBS.annotation_values (annotation_id);

#------------------------------

CREATE TABLE genes_to_positions (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	gene_name VARCHAR(100) NOT NULL,
	chromosome VARCHAR(10) NOT NULL,
	`start` INT UNSIGNED NOT NULL,
	`end` INT UNSIGNED NOT NULL
);

CREATE INDEX gene_name ON GBS.genes_to_positions (gene_name);
CREATE INDEX chromosome ON GBS.genes_to_positions (chromosome);
CREATE INDEX start ON GBS.genes_to_positions (start);
CREATE INDEX end ON GBS.genes_to_positions (end);