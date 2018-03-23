# Delete the current DB backup
DROP DATABASE IF EXISTS GEPANELAPP_OLD;

#------------------------------

# Recreate the current DB backup
CREATE DATABASE GEPANELAPP_OLD;

#------------------------------

# Move the current production DB to the backup DB 
RENAME TABLE 
	GEPANELAPP.panels TO GEPANELAPP_OLD.panels, 
	GEPANELAPP.genes TO GEPANELAPP_OLD.genes, 
	GEPANELAPP.genes_in_panels TO GEPANELAPP_OLD.genes_in_panels
;

#------------------------------

# Move the current new DB to the production DB
RENAME TABLE 
	GEPANELAPP_NEW.panels TO GEPANELAPP.panels, 
	GEPANELAPP_NEW.genes TO GEPANELAPP.genes, 
	GEPANELAPP_NEW.genes_in_panels TO GEPANELAPP.genes_in_panels
;

#------------------------------

# Delete the now-empty new DB
DROP DATABASE GEPANELAPP_NEW;
