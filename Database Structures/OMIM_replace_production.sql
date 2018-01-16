# Delete the current DB backup
DROP DATABASE OMIM_OLD;

#------------------------------

# Recreate the current DB backup
CREATE DATABASE OMIM_OLD;

#------------------------------

# Move the current production DB to the backup DB 
RENAME TABLE OMIM.omim_disorders TO OMIM_OLD.omim_disorders, OMIM.omim_disorders_to_omim_numbers TO OMIM_OLD.omim_disorders_to_omim_numbers, OMIM.omim_genes TO OMIM_OLD.omim_genes, OMIM.omim_number_to_gene TO OMIM_OLD.omim_number_to_gene, OMIM.omim_numbers TO OMIM_OLD.omim_numbers;

#------------------------------

# Move the current new DB to the production DB
RENAME TABLE OMIM_NEW.omim_disorders TO OMIM.omim_disorders, OMIM_NEW.omim_disorders_to_omim_numbers TO OMIM.omim_disorders_to_omim_numbers, OMIM_NEW.omim_genes TO OMIM.omim_genes, OMIM_NEW.omim_number_to_gene TO OMIM.omim_number_to_gene, OMIM_NEW.omim_numbers TO OMIM.omim_numbers;

#------------------------------

# Delete the now-empty new DB
DROP DATABASE OMIM_NEW;