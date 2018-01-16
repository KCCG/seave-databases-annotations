CREATE DATABASE GENE_LISTS;

USE GENE_LISTS;

CREATE TABLE genes (
	gene_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	gene_name VARCHAR(30) NOT NULL UNIQUE,
	date_added DATETIME NOT NULL
);


CREATE TABLE gene_lists (
	list_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	list_name VARCHAR(100) NOT NULL UNIQUE,
	date_added DATETIME NOT NULL
);


CREATE TABLE genes_in_lists (
	gene_id INT UNSIGNED NOT NULL,
	list_id INT UNSIGNED NOT NULL,
	date_added DATETIME NOT NULL,
	FOREIGN KEY (gene_id) REFERENCES genes(gene_id),
	FOREIGN KEY (list_id) REFERENCES gene_lists(list_id)
);


CREATE TABLE gene_lists_deletions (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	gene_name VARCHAR(30),
	list_name VARCHAR(100),
	date_deleted DATETIME NOT NULL,
	extra_info VARCHAR(100)
);


#--Trigger for logging deletions in the connections table:
DELIMITER $$
CREATE TRIGGER log_deletions BEFORE DELETE ON genes_in_lists FOR EACH ROW
BEGIN
INSERT INTO gene_lists_deletions (gene_name, list_name, date_deleted) VALUES ((SELECT gene_name FROM genes WHERE gene_id = OLD.gene_id), (SELECT list_name FROM gene_lists WHERE list_id = OLD.list_id), now());
END$$
DELIMITER ;
#--Note: to create a trigger on AWS RDS, need to change the 'log_bin_trust_function_creators' parameter to 1 in the parameter groups settings.
