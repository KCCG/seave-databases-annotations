#!/usr/bin/perl

use strict;
use warnings;
use DBI; # MySQL connection
use Tie::File; # File -> array for parsing without loading whole thing into RAM

####################################

my $input_file; # Stores the input filename from the argument passed to the script
my $mysql_host; # Stores the MySQL hostname to connect to from the argument passed to the script
my $mysql_user; # Stores the MySQL username to connect to from the argument passed to the script
my $mysql_password; # Stores the MySQL password to connect to from the argument passed to the script

if (scalar(@ARGV) != 4) {
	print "FATAL ERROR: arguments must be supplied as 1) input file path 2) MySQL host 3) MySQL user 4) MySQL password.\n";
	exit;
} else {
	$input_file = $ARGV[0];
	$mysql_host = $ARGV[1];
	$mysql_user = $ARGV[2];
	$mysql_password = $ARGV[3];
}

####################################

my $driver = "mysql"; 
my $database = "COSMIC_CGC_NEW";
my $dsn = "DBI:$driver:database=$database;host=$mysql_host";

my $dbh = DBI->connect($dsn, $mysql_user, $mysql_password) or die $DBI::errstr;

####################################

my $num_input_columns = 18; # The number of columns expected in the input VCF
my $num_insert_columns = 4; # The number of columns being inserted into the DB
my $num_rows_to_add_per_insert = 100;

my @input_file_lines;
my $inserted_rows = 0;
my @insert_values;

####################################

# Check that the file exists
-e $input_file or die "File \"$input_file\" does not exist.\n";

print "\nIndexing input file.\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $input_file or die "Cannot index input file.\n";

####################################

my $mysql_query_fresh = "INSERT INTO `cosmic_cgc` (gene, associations, mutation_types, translocation_partner) VALUES ";
my $mysql_query = $mysql_query_fresh;

for (my $i=0; $i<scalar(@input_file_lines); $i++) {
	# Print indexing finished message once parsing starts
	if ($i == 0) { # Disregard the header line
		print "\nFinished indexing input file.\n";
		
		next;
	}
	
	# Ignore header line
	if ($input_file_lines[$i] =~ /^Gene Symbol.*/) {
		next;
	}
	
	# Split the row by tab characters
	my @split_line = split(/\t/, $input_file_lines[$i], -1); # -1 to keep empty fields as empty (i.e. multiple tab characters in a row split correctly)
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	} elsif (scalar(@split_line) != $num_input_columns) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns." columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		next;
	}
	
	# Go through each value
	for (my $i = 0; $i < scalar(@split_line); $i++) {
		# If the value is encased with quotation marks "", remove them
		if ($split_line[$i] =~ /^"(.*)"$/) {
			$split_line[$i] = $1;
		}
	}
	
	my $gene = $split_line[0];
	my $associations = "";
	my $mutation_types = $split_line[13];
	my $translocation_partner = $split_line[14];
	
	# Add the somatic tumour type to the Associations column
	if ($split_line[5] eq "yes") {
		$associations .= "Somatic variant in ".$split_line[7].". ";
	}
	
	# Add the germline tumour type to the Associations column
	if ($split_line[6] eq "yes") {
		$associations .= "Germline variant in ".$split_line[8].". ";
	}
	
	# Add the cancer syndrome to the Associations column
	if ($split_line[9] ne "") {
		$associations .= "Cancer syndrome ".$split_line[9].". ";
	}
	
	# Add the molecular genetics to the Associations column
	if ($split_line[11] ne "") {
		$associations .= "Molecular genetics ".$split_line[11].". ";
	}
	
	# Add the tissue type to the Associations column
	if ($split_line[10] ne "") {
		$associations .= "Tissue type ".$split_line[10].". ";
	}
	
	# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
	$mysql_query .= "(?, ?, ?, ?), ";

	$inserted_rows++;
	
	# Add the values to be inserted
	push(@insert_values, $gene); # gene
	push(@insert_values, $associations); # associations
	push(@insert_values, $mutation_types); # mutation_types
	push(@insert_values, $translocation_partner); # translocation_partner
	
	# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
	if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns || ($i + 1) == scalar(@input_file_lines)) {
		chop($mysql_query); # Remove the extra space at the end of the list of data
		chop($mysql_query); # Remove the extra comma at the end of the list of data
		
		$mysql_query .= ";";
		
		# Execute the insertion of the row into the MySQL DB
		my $sth = $dbh->prepare($mysql_query);
		$sth->execute(@insert_values) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
		$sth->finish();
	
		# Empty the array of values to add
		@insert_values = ();
	
		# Reset the MySQL query
		$mysql_query = $mysql_query_fresh;
	}
	
	if ($i =~ /00$/) {
		print "[".localtime()."] Processed: ".$i." lines from a total of ".(scalar(@input_file_lines)-1).".\n";
	}
}

print "\nPARSING COMPLETE!\nInserted a total of ".$inserted_rows." from ".(scalar(@input_file_lines)-1)." lines in the input file.\n\n";

exit;