# Delete the current DB backup
DROP DATABASE MITOMAP_OLD;

#------------------------------

# Recreate the DB backup
CREATE DATABASE MITOMAP_OLD;

#------------------------------

# Move the current production DB to the backup DB 
RENAME TABLE MITOMAP.mitomap TO MITOMAP_OLD.mitomap;

#------------------------------

# Move the current new DB to the production DB
RENAME TABLE MITOMAP_NEW.mitomap TO MITOMAP.mitomap;

#------------------------------

# Delete the now-empty new DB
DROP DATABASE MITOMAP_NEW;