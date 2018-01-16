CREATE DATABASE `OMIM_NEW`;

USE `OMIM_NEW`;

#------------------------------

CREATE TABLE omim_numbers (
	omim_number int unsigned not null unique primary key,
	omim_title varchar(300) not null,
	omim_status varchar(10) not null
);

CREATE TABLE omim_genes (
	gene_id int unsigned not null auto_increment primary key,
	gene_name varchar(30) not null unique
);


CREATE TABLE omim_disorders (
	disorder_id int unsigned not null auto_increment primary key,
	omim_disorder varchar(500) not null unique
);


CREATE TABLE omim_number_to_gene (
	omim_number int unsigned not null,
	gene_id int unsigned not null,
	FOREIGN KEY (gene_id) REFERENCES omim_genes(gene_id),
	FOREIGN KEY (omim_number) REFERENCES omim_numbers(omim_number)
);

CREATE INDEX gene_id on omim_number_to_gene (gene_id);
CREATE INDEX omim_number on omim_number_to_gene (omim_number);


CREATE TABLE omim_disorders_to_omim_numbers (
	omim_number int unsigned not null,
	disorder_id int unsigned not null,
	FOREIGN KEY (disorder_id) REFERENCES omim_disorders(disorder_id),
	FOREIGN KEY (omim_number) REFERENCES omim_numbers(omim_number)
);

CREATE INDEX disorder_id on omim_disorders_to_omim_numbers (disorder_id);
CREATE INDEX omim_number on omim_disorders_to_omim_numbers (omim_number);


/*
View the information for a particular gene:
SELECT 
	OMIM.omim_genes.gene_name, 
	omim_numbers.omim_number, 
	omim_numbers.omim_title, 
	omim_numbers.omim_status, 
	omim_disorders.omim_disorder 
FROM 
	OMIM.omim_numbers 
INNER JOIN OMIM.omim_number_to_gene ON OMIM.omim_number_to_gene.omim_number = OMIM.omim_numbers.omim_number 
INNER JOIN OMIM.omim_genes ON OMIM.omim_genes.gene_id = OMIM.omim_number_to_gene.gene_id 
INNER JOIN OMIM.omim_disorders_to_omim_numbers ON OMIM.omim_disorders_to_omim_numbers.omim_number = OMIM.omim_numbers.omim_number 
INNER JOIN OMIM.omim_disorders ON OMIM.omim_disorders_to_omim_numbers.disorder_id = OMIM.omim_disorders.disorder_id 
WHERE 
	OMIM.omim_genes.gene_name = ''; 
*/