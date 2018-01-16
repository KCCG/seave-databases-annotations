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
my $database = "OMIM_NEW";
my $dsn = "DBI:$driver:database=$database;host=$mysql_host";

my $dbh = DBI->connect($dsn, $mysql_user, $mysql_password) or die $DBI::errstr;

####################################

my @input_file_lines;
my $inserted_rows = 0;

####################################

# Check that the file exists
-e $input_file or die "File \"$input_file\" does not exist.\n";

print "\nIndexing input file.\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $input_file or die "Cannot index input file.\n";;

print "\nFinished indexing input file.\n";

####################################

print "\nAdding data to MySQL DB.\n";

for (my $i=0; $i<scalar(@input_file_lines); $i++) {
	# Ignore comment lines
	if ($input_file_lines[$i] =~ /^#.*/) {
		next;
	}
	
	my @split_line = split(/\t/, $input_file_lines[$i], -1); # The -1 here allows multiple delimiters after each other to still trigger as empty elements http://stackoverflow.com/questions/3711649/perl-split-with-empty-text-before-after-delimiters
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	} elsif (scalar(@split_line) != 13) {
		print "WARNING: Found a line that doesn't contain 13 columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		next;
	} else {
		my $omim_number = $split_line[8];
		my $omim_title = $split_line[7];
		my $omim_status = $split_line[6];
		
		my @genes = split(/,\s+/, $split_line[5]);
		
		my @disorders = split(/;/, $split_line[11]." "); # Add space here so there is a disorder element which becomes empty so all empty disorders get populated correctly as having an empty disorder
		
		# Create the SQL query for the omim number info
		my $mysql_query = "INSERT INTO omim_numbers ";
		$mysql_query .= "(omim_number, omim_title, omim_status) ";
		$mysql_query .= "VALUES (?, ?, ?);";
		
		# Insert the omim number info into the DB
		my $sth = $dbh->prepare($mysql_query);
		$sth->execute($omim_number, $omim_title, $omim_status) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
		$sth->finish();
		
		# Go through each gene and link them to the omim number
		foreach my $gene (@genes) {
			$gene =~ s/^[\s\t]*//; # Remove spaces or tabs from the start
			$gene =~ s/[\s\t]*$//; # Remove spaces or tabs from the end
			
			my $gene_id = ""; # Store the inserted/fetched gene id
			
			$mysql_query = "SELECT gene_id FROM omim_genes WHERE gene_name = ?;";
			
			$sth = $dbh->prepare($mysql_query);
			$sth->execute($gene) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
			
			if (my @result = $sth->fetchrow_array) {
				$gene_id = $result[0];
			}
			
			$sth->finish();
			
			# Determine the gene id either from an existing result or from inserting a new one
			if (length($gene_id) == 0) {
				# Add the gene to the list of unique genes
				$mysql_query = "INSERT INTO omim_genes ";
				$mysql_query .= "(gene_name) ";
				$mysql_query .= "VALUES (?);";
			
				$sth = $dbh->prepare($mysql_query);
				$sth->execute($gene) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
				$sth->finish();
			
				$gene_id = $dbh->{mysql_insertid};
			}
			
			# Link the gene to the omim number
			$mysql_query = "INSERT INTO omim_number_to_gene ";
			$mysql_query .= "(omim_number, gene_id) ";
			$mysql_query .= "VALUES (?, ?);";
			
			$sth = $dbh->prepare($mysql_query);
			$sth->execute($omim_number, $gene_id) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
			$sth->finish();
		}
		
		foreach my $disorder (@disorders) {
			$disorder =~ s/^[\s\t]*//; # Remove spaces or tabs from the start
			$disorder =~ s/[\s\t]*$//; # Remove spaces or tabs from the end
			
			my $disorder_id = "";
		
			$mysql_query = "SELECT disorder_id FROM omim_disorders WHERE omim_disorder = ?;";
	
			$sth = $dbh->prepare($mysql_query);
			$sth->execute($disorder) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
			if (my @result = $sth->fetchrow_array) {
				$disorder_id = $result[0];
			}
		
			$sth->finish();
		
			# Determine the disorder id either from an existing result or from inserting a new one
			if (length($disorder_id) == 0) {
				# Add the gene to the list of unique genes
				$mysql_query = "INSERT INTO omim_disorders ";
				$mysql_query .= "(omim_disorder) ";
				$mysql_query .= "VALUES (?);";
	
				$sth = $dbh->prepare($mysql_query);
				$sth->execute($disorder) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
				$sth->finish();
	
				$disorder_id = $dbh->{mysql_insertid};
			}
		
			# Link the disorder to the omim number
			$mysql_query = "INSERT INTO omim_disorders_to_omim_numbers ";
			$mysql_query .= "(omim_number, disorder_id) ";
			$mysql_query .= "VALUES (?, ?);";
	
			$sth = $dbh->prepare($mysql_query);
			$sth->execute($omim_number, $disorder_id) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
			$sth->finish();
		}
		
		$inserted_rows++;
	}
	
	if (($i + 1) =~ /00$/) {
		print "[".localtime()."] Processed: ".($i + 1)." lines from: ".scalar(@input_file_lines).".\n";
	}
}

print "\n\nPARSING COMPLETE!\nInserted a total of ".$inserted_rows." from ".scalar(@input_file_lines)." lines in the input file (includes commented lines).\n\n";

exit;