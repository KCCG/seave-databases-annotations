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
my $database = "RVIS_NEW";
my $dsn = "DBI:$driver:database=$database;host=$mysql_host";

my $dbh = DBI->connect($dsn, $mysql_user, $mysql_password) or die $DBI::errstr;

####################################

my $num_input_columns = 24; # The number of columns expected in the input file
my $num_insert_columns = 2; # The number of columns being inserted into the DB
my $num_rows_to_add_per_insert = 1000;

my @input_file_lines;
my $inserted_rows = 0;
my @insert_values;

my $percentile_NA_rows = 0;

# Check that the file exists
-e $input_file or die "File \"$input_file\" does not exist.\n";

print "\nIndexing input file.\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $input_file or die "Cannot index input file.\n";;

####################################

my $mysql_query_fresh = "INSERT INTO rvis (gene, percentile) VALUES ";
my $mysql_query = $mysql_query_fresh;

for (my $i = 0; $i < scalar(@input_file_lines); $i++) {
	if ($i == 0) { # Disregard the header line
		print "\nFinished indexing input file.\n";
		
		next;
	}
	
	my @split_line = split(/\t/, $input_file_lines[$i]);
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	}
	
	if (scalar(@split_line) != $num_input_columns) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns." columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		next;
	}
	
	my $gene = $split_line[0];
	my $percentile = $split_line[20]; # Grab the %ExAC_0.05%popn column
	
	# Ignore rows where the percentile value is NA
	if ($percentile eq "NA") {
		$percentile_NA_rows++;
		
		next;
	}
	
	# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
	$mysql_query .= "(?, ?), ";
	
	$inserted_rows++;
	
	# Add the data to be inserted
	push(@insert_values, $gene);
	push(@insert_values, $percentile);
	
	# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
	if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns || $inserted_rows == (scalar(@input_file_lines) - 1 - $percentile_NA_rows)) {
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
	
	if ($inserted_rows =~ /000$/) {
		print "[".localtime()."] Inserted: ".$inserted_rows." lines from a total of ".scalar(@input_file_lines).".\n";
	}
}

print "\n\nPARSING COMPLETE!\nInserted a total of ".$inserted_rows." from ".(scalar(@input_file_lines) - 1)." lines in the input file. ".$percentile_NA_rows." rows contained NA values for the percentile and were ignored.\n\n";

exit;