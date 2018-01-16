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
my $database = "DBNSFP_NEW";
my $dsn = "DBI:$driver:database=$database;host=$mysql_host";

my $dbh = DBI->connect($dsn, $mysql_user, $mysql_password) or die $DBI::errstr;

####################################

my $num_input_columns = 119;
my $num_columns_to_add_per_insert = 1000;

my @input_file_lines;
my $line_counter = 1;
my $inserted_rows = 0;
my @insert_values;
my %header_index;

####################################

# Check that the file exists
-e $input_file or die "File \"$input_file\" does not exist.\n";

print "\nIndexing input file.\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $input_file or die "Cannot index input file.\n";;

####################################

# Columns that will be pulled out from the input file
my @columns_to_save = ("chr", "pos(1-coor)", "ref", "alt", "Uniprot_acc", "Uniprot_id", "Uniprot_aapos", "FATHMM_score", "FATHMM_rankscore", "FATHMM_pred", "MetaSVM_score", "MetaSVM_rankscore", "MetaSVM_pred", "MetaLR_score", "MetaLR_rankscore", "MetaLR_pred", "PROVEAN_score", "PROVEAN_pred", "GERP++_NR"); 

# The INSERT MySQL query that will be used for each bundle of INSERTs
my $mysql_query_fresh = "INSERT INTO dbnsfp (`".join("`, `", @columns_to_save)."`) VALUES ";

# Define the working MySQL query
my $mysql_query = $mysql_query_fresh;

for (my $i=0; $i<scalar(@input_file_lines); $i++) {
	my @split_line = split(/\t/, $input_file_lines[$i]);
	
	# If the line has no tab characters
	if (scalar(@split_line) < 2) {
		print "WARNING: Found a line in the input file that does not contain tab-separated values. Line number: ".$line_counter." Line contents: ".$input_file_lines[$i]."\n";
		
		$line_counter++;
		next;
	# If the line does not have the expected number of columns - a check on DB integrity/structure
	} elsif (scalar(@split_line) != $num_input_columns) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns." columns of information. Line number: ".$line_counter." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		$line_counter++;
		next;
	# If the line checks out
	} else {
		# Index the header line
		if ($line_counter == 1) {
			print "\nFinished indexing input file.\n";
			
			# Remove the header # from the line
			$split_line[0] =~ s/#//;
			
			# Go through each header column
			for (my $x = 0; $x < scalar(@split_line); $x++) {
				$header_index{$split_line[$x]} = $x;
			}
			
			# Make sure each of the @columns_to_save exist in the input file
			foreach my $column_to_save (@columns_to_save) {
				if (!defined($header_index{$column_to_save})) {
					print "FATAL ERROR: Could not find required column '".$column_to_save."' in the input file.\n\n";
					
					exit;
				}
			}
			
			$line_counter++;
			
			next;
		} else {
			# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
			$mysql_query .= "(";
			
			for (my $x = 0; $x < scalar(@columns_to_save); $x++) {
				$mysql_query .= "?, "; # Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
			}
						
			chop($mysql_query); # Remove the extra space at the end of the list of data
			chop($mysql_query); # Remove the extra comma at the end of the list of data
			
			$mysql_query .= "), ";
			
			$inserted_rows++;
			
			# Go through each column to save and add the value from the current line to an array to insert 
			for (my $x = 0; $x < scalar(@columns_to_save); $x++) {
				push(@insert_values, $split_line[$header_index{$columns_to_save[$x]}]);
			}
			
			# If there are ($num_input_columns*$num_columns_to_add_per_insert) waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
			if (scalar(@insert_values) == (scalar(@columns_to_save)*$num_columns_to_add_per_insert) || $line_counter == scalar(@input_file_lines)) {
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
		}
	}
	
	if ($line_counter =~ /0000$/) {
		print "[".localtime()."] Processed: ".$line_counter." lines.\n";
	}
	
	$line_counter++;
}

print "\nPARSING COMPLETE!\nInserted a total of ".$inserted_rows." from ".(scalar(@input_file_lines)-1)." lines in the input file.\n\n";

exit;