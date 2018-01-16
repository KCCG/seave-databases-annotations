# Delete the current DB backup
DROP DATABASE ORPHANET_OLD;

#------------------------------

# Recreate the current DB backup
CREATE DATABASE ORPHANET_OLD;

#------------------------------

# Move the current production DB to the backup DB 
RENAME TABLE 
	ORPHANET.orphanet_disorders TO ORPHANET_OLD.orphanet_disorders, 
	ORPHANET.orphanet_genes TO ORPHANET_OLD.orphanet_genes, 
	ORPHANET.orphanet_inheritances TO ORPHANET_OLD.orphanet_inheritances, 
	ORPHANET.orphanet_age_of_onsets TO ORPHANET_OLD.orphanet_age_of_onsets, 
	ORPHANET.association_types TO ORPHANET_OLD.association_types,
	ORPHANET.association_statuses TO ORPHANET_OLD.association_statuses,
	ORPHANET.genes_to_disorders TO ORPHANET_OLD.genes_to_disorders,
	ORPHANET.age_of_onsets_to_disorders TO ORPHANET_OLD.age_of_onsets_to_disorders,
	ORPHANET.inheritances_to_disorders TO ORPHANET_OLD.inheritances_to_disorders
;

#------------------------------

# Move the current new DB to the production DB
RENAME TABLE 
	ORPHANET_NEW.orphanet_disorders TO ORPHANET.orphanet_disorders, 
	ORPHANET_NEW.orphanet_genes TO ORPHANET.orphanet_genes, 
	ORPHANET_NEW.orphanet_inheritances TO ORPHANET.orphanet_inheritances, 
	ORPHANET_NEW.orphanet_age_of_onsets TO ORPHANET.orphanet_age_of_onsets, 
	ORPHANET_NEW.association_types TO ORPHANET.association_types,
	ORPHANET_NEW.association_statuses TO ORPHANET.association_statuses,
	ORPHANET_NEW.genes_to_disorders TO ORPHANET.genes_to_disorders,
	ORPHANET_NEW.age_of_onsets_to_disorders TO ORPHANET.age_of_onsets_to_disorders,
	ORPHANET_NEW.inheritances_to_disorders TO ORPHANET.inheritances_to_disorders
;

#------------------------------

# Delete the now-empty new DB
DROP DATABASE ORPHANET_NEW;