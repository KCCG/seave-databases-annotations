#!/bin/bash

# Author: Velimir Gayevskiy (vel@vel.nz)
# Purpose: Downloads all gene panels from the Genomics England PanelApp and creates SQL statements to store the panels and the genes belonging to them in a format that Seave can use

# Download the current panels in JSON format and save the results to a file
curl https://panelapp.genomicsengland.co.uk/WebServices/list_panels/?format=json > PanelApp.json

# Extract all panel names and ids from the all panels JSON into a separate file
jq '.result | .[] | [.Name,.Panel_Id]' PanelApp.json > PanelApp.panels.json

# Create the SQL file to import into the DB and populate it with a line to use the expected DB name when importing
echo "USE GEPANELAPP_NEW;" > GEPANELAPP_data.sql

# Create an SQL statement to populate the panels table with the panel name and panel id for all panels
echo -n "INSERT INTO panels (name, ge_panelid) VALUES " >> GEPANELAPP_data.sql # -n for no newline character at the end
jq -r -c '. | "(" + @csv + ")"' PanelApp.panels.json | paste -d, -s - | tr -d '\n' >> GEPANELAPP_data.sql 
echo ";" >> GEPANELAPP_data.sql

# Go through each panel by GE panel id
jq -r '.[1]' PanelApp.panels.json | while read panelid; do 
	# Fetch the panel information from the server and only save the gene symbols and the level of confidence in their belonging to the panel
	PANELLINE=$(curl https://panelapp.genomicsengland.co.uk/WebServices/get_panel/$panelid/ | jq ".result | .Genes | .[] | [.GeneSymbol,.LevelOfConfidence]")
	
	# If there are genes in the current panel (found that some don't!)
	if [[ $PANELLINE != "" ]]; then
		# Create an SQL statement to populate the gene symbols for the current panel into the genes table if they're not already in there
		echo -n "INSERT IGNORE INTO genes (symbol) VALUES " >> GEPANELAPP_data.sql
		
		# Extract the gene symbol field from the fetched data for the current panel
		echo $PANELLINE | jq -r '"(\"" + .[0] + "\")"' - | paste -d, -s - | tr -d '\n' >> GEPANELAPP_data.sql
	
		echo ";" >> GEPANELAPP_data.sql
		
		# Create an SQL statement to populate the table storing all genes belonging to panels
		echo -n "INSERT INTO genes_in_panels (panel_id, gene_id, confidence_level) VALUES " >> GEPANELAPP_data.sql
		
		# Create the statement per gene linking the panel ID, gene symbol and level of confidence
		echo $PANELLINE | jq -r '"((SELECT id FROM panels WHERE ge_panelid=\"'$panelid'\"),(SELECT id FROM genes WHERE symbol=\"" + .[0] + "\"),\"" + .[1] + "\")"' - | paste -d, -s - | tr -d '\n' >> GEPANELAPP_data.sql
	
		echo ";" >> GEPANELAPP_data.sql
	fi
done

exit;
