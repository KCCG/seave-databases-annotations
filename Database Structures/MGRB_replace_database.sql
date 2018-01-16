# Delete the current DB backup
DROP DATABASE MGRB_OLD;

#------------------------------

# Recreate the current DB backup
CREATE DATABASE MGRB_OLD;

#------------------------------

# Move the current production DB to the backup DB 
RENAME TABLE MGRB.mgrb_vafs TO MGRB_OLD.mgrb_vafs;

#------------------------------

# Move the current new DB to the production DB
RENAME TABLE MGRB_NEW.mgrb_vafs TO MGRB.mgrb_vafs;

#------------------------------

# Delete the now-empty new DB
DROP DATABASE MGRB_NEW;