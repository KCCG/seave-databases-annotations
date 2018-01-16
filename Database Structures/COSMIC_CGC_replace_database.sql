# Delete the current DB backup
DROP DATABASE COSMIC_CGC_OLD;

#------------------------------

# Recreate the DB backup
CREATE DATABASE COSMIC_CGC_OLD;

#------------------------------

# Move the current production DB to the backup DB 
RENAME TABLE COSMIC_CGC.cosmic_cgc TO COSMIC_CGC_OLD.cosmic_cgc;

#------------------------------

# Move the current new DB to the production DB
RENAME TABLE COSMIC_CGC_NEW.cosmic_cgc TO COSMIC_CGC.cosmic_cgc;

#------------------------------

# Delete the now-empty new DB
DROP DATABASE COSMIC_CGC_NEW;