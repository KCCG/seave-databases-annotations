# Delete the current DB backup
DROP DATABASE CLINVAR_OLD;

#------------------------------

# Recreate the current DB backup
CREATE DATABASE CLINVAR_OLD;

#------------------------------

# Move the current production DB to the backup DB 
RENAME TABLE CLINVAR.clinvar TO CLINVAR_OLD.clinvar;

#------------------------------

# Move the current new DB to the production DB
RENAME TABLE CLINVAR_NEW.clinvar TO CLINVAR.clinvar;

#------------------------------

# Delete the now-empty new DB
DROP DATABASE CLINVAR_NEW;