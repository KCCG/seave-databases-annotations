CREATE DATABASE `DBNSFP_NEW`;

USE `DBNSFP_NEW`;

CREATE TABLE dbnsfp (
	ID int unsigned not null auto_increment primary key,
	chr varchar(30),
	`pos(1-coor)` varchar(30),
	ref varchar(30),
	alt varchar(30),
	Uniprot_acc varchar(30),
	Uniprot_id varchar(30),
	Uniprot_aapos varchar(30),
	FATHMM_score varchar(30),
	FATHMM_rankscore varchar(30),
	FATHMM_pred varchar(30),
	MetaSVM_score varchar(30),
	MetaSVM_rankscore varchar(30),
	MetaSVM_pred varchar(30),
	MetaLR_score varchar(30),
	MetaLR_rankscore varchar(30),
	MetaLR_pred varchar(30),
	PROVEAN_score varchar(30),
	PROVEAN_pred varchar(30),
	`GERP++_NR` varchar(30)
);

CREATE INDEX dbnsfp_query on dbnsfp (chr, `pos(1-coor)`, ref, alt);

-- Note: DBNSFP v2.9 uses `pos(1-based)` whereas v2.9.1 (and presumably later?) uses `pos(1-coor)` this has to be the same as the importation script for it to work
-- TODO: use `position` instead regardless of what the DBNSFP file calls it so the Seave code doesn't have to change when DBNSFP changes it