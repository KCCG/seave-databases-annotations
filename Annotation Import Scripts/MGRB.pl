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
my $database = "MGRB_NEW";
my $dsn = "DBI:$driver:database=$database;host=$mysql_host";

my $dbh = DBI->connect($dsn, $mysql_user, $mysql_password) or die $DBI::errstr;

####################################

my $num_input_file_columns = 7;
my $num_insert_columns_per_line = 7;
my $num_columns_to_add_per_insert = 100000;

my @input_file_lines;
my $line_counter = 1;
my $inserted_rows = 0;
my @insert_values;

####################################

# Check that the file exists
-e $input_file or die "File \"$input_file\" does not exist.\n";

print "\nIndexing input file.\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $input_file or die "Cannot index input file.\n";;

####################################

my $mysql_query_fresh = "INSERT INTO mgrb_vafs (chr, pos, ref, alt, ac, an, filters) VALUES ";
my $mysql_query = $mysql_query_fresh;

for (my $i=0; $i<scalar(@input_file_lines); $i++) {
	if ($input_file_lines[$i] =~ /^chrom.*/) { # Disregard the header lines
		# Print the index finished message on parsing the first line
		if ($line_counter == 1) {
			print "\nFinished indexing input file.\n";
		}
		
		$line_counter++;
		
		next;
	} else {
		my @split_line = split(/\t/, $input_file_lines[$i], -1); # -1 to capture still split on empty columns because filters is empty when PASS
		
		if (scalar(@split_line) == 0) {
			print "WARNING: Found a line in the input file that does not contain tab-separated values. Line number: ".$line_counter." Line contents: ".$input_file_lines[$i]."\n";
			
			$line_counter++;
			
			next;
		} elsif (scalar(@split_line) != $num_input_file_columns) {
			print "WARNING: Found a line that doesn't contain ".$num_input_file_columns." columns of information. Line number: ".$line_counter." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
			
			$line_counter++;
			
			next;
		} else {
			# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
			$mysql_query .= "(?, ?, ?, ?, ?, ?, ?), ";
			
			$inserted_rows++;
			
			my $chr = $split_line[0];
			
			my $pos = $split_line[1];
			
			my $ref = $split_line[2];
			
			my $alt = $split_line[3];
			
			my $filters = $split_line[4];
			
			my $ac = sprintf("%.10g", $split_line[6]);
			
			my $an = sprintf("%.10g", $split_line[5]);
			
			# If no problems with the above, add all the info to the values to be inserted into the DB
			push(@insert_values, $chr, $pos, $ref, $alt, $ac, $an, $filters);
			
			# If there are ($num_insert_columns_per_line*$num_columns_to_add_per_insert) waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
			if (scalar(@insert_values) == ($num_insert_columns_per_line*$num_columns_to_add_per_insert) || $line_counter == scalar(@input_file_lines)) {
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

print "\nIMPORT COMPLETE!\nInserted a total of ".$inserted_rows." from ".(scalar(@input_file_lines)-1)." lines in the input file (total includes header lines).\n\n";

exit;