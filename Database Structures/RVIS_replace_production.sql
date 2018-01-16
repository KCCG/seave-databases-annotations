# Delete the current DB backup
DROP DATABASE RVIS_OLD;

#------------------------------

# Recreate the current DB backup
CREATE DATABASE RVIS_OLD;

#------------------------------

# Move the current production DB to the backup DB 
RENAME TABLE RVIS.rvis TO RVIS_OLD.rvis;

#------------------------------

# Move the current new DB to the production DB
RENAME TABLE RVIS_NEW.rvis TO RVIS.rvis;

#------------------------------

# Delete the now-empty new DB
DROP DATABASE RVIS_NEW;