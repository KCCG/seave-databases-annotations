# Delete the current DB backup
DROP DATABASE `COSMIC_OLD`;

#------------------------------

# Recreate the current DB backup
CREATE DATABASE `COSMIC_OLD`;

#------------------------------

# Move the current production DB to the backup DB 
RENAME TABLE 
	COSMIC.variants TO COSMIC_OLD.variants, 
	COSMIC.cosmic_numbers TO COSMIC_OLD.cosmic_numbers, 
	COSMIC.cosmic_number_to_variant TO COSMIC_OLD.cosmic_number_to_variant
;

#------------------------------

# Move the current new DB to the production DB
RENAME TABLE 
	COSMIC_NEW.variants TO COSMIC.variants, 
	COSMIC_NEW.cosmic_numbers TO COSMIC.cosmic_numbers, 
	COSMIC_NEW.cosmic_number_to_variant TO COSMIC.cosmic_number_to_variant
;

#------------------------------

# Delete the now-empty new DB
DROP DATABASE `COSMIC_NEW`;