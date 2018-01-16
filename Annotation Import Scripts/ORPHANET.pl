#!/usr/bin/perl

use strict;
use warnings;
use DBI; # MySQL connection
use Tie::File; # File -> array for parsing without loading whole thing into RAM

####################################

# Store the input paths and filenames of the input files from the arguments passed to the script
my $disorder2gene_tsv;
my $disorder2age_tsv;
my $disorder2inheritance_tsv;

my $mysql_host; # Stores the MySQL hostname to connect to from the argument passed to the script
my $mysql_user; # Stores the MySQL username to connect to from the argument passed to the script
my $mysql_password; # Stores the MySQL password to connect to from the argument passed to the script

if (scalar(@ARGV) != 6) {
	print "FATAL ERROR: arguments must be supplied as 1) disorder2gene input path and file 2) disorder2age input path and file 3) disorder2inheritance input path and file 4) MySQL host 5) MySQL user 6) MySQL password.\n";
	exit;
} else {
	$disorder2gene_tsv = $ARGV[0];
	$disorder2age_tsv = $ARGV[1];
	$disorder2inheritance_tsv = $ARGV[2];
	
	$mysql_host = $ARGV[3];
	$mysql_user = $ARGV[4];
	$mysql_password = $ARGV[5];
}

####################################

my $driver = "mysql"; 
my $database = "ORPHANET_NEW";
my $dsn = "DBI:$driver:database=$database;host=$mysql_host";

my $dbh = DBI->connect($dsn, $mysql_user, $mysql_password) or die $DBI::errstr;

####################################

# Used for holding the input files
my @input_file_lines;

# Arrays to store the number of columns expected in the input files
my $num_input_columns_disorder2gene = 8;
my $num_input_columns_disorder2age = 3;
my $num_input_columns_disorder2inheritance = 3;

# Hashes to store unique values to be inserted into tables
my %unique_genes;
my %unique_inheritances;
my %unique_age_of_onsets;
my %unique_association_types;
my %unique_association_statuses;

# Variables to store counts of how many links between various columns are to be made in the DB
my $num_genes_to_disorders_links = 0;
my $num_inheritances_to_disorders_links = 0;
my $num_age_of_onsets_to_disorders_links = 0;

# Number of columns to insert for the different tables
my $num_insert_columns_orphanet_genes = 1;
my $num_insert_columns_orphanet_disorders = 2;
my $num_insert_columns_orphanet_inheritances = 1;
my $num_insert_columns_orphanet_ages_of_onset = 1;
my $num_insert_columns_association_types = 1;
my $num_insert_columns_association_statuses = 1;
my $num_insert_columns_genes_to_disorders = 4; # Insert column here means the ? in the queries
my $num_insert_columns_inheritances_to_disorders = 2; # Insert column here means the ? in the queries
my $num_insert_columns_age_of_onsets_to_disorders = 2; # Insert column here means the ? in the queries
my $num_rows_to_add_per_insert = 1000; # The number of rows to add to the MySQL DB per query sent to it

my $mysql_query;
my $mysql_query_fresh;

my $inserted_rows = 0;
my @insert_values;

#my $num_variants = 0; # Tracks the number of variants for knowing how many rows will be inserted into the DB
#my $num_variant_links = 0; # Tracks the number of variant to COSMIC number links fro knowing how many rows will be inserted into the DB

my %disorders; # Hash to store disorders information

####################################

# Check that the input files exist
-e $disorder2gene_tsv or die "File \"$disorder2gene_tsv\" does not exist.\n";
-e $disorder2age_tsv or die "File \"$disorder2age_tsv\" does not exist.\n";
-e $disorder2inheritance_tsv or die "File \"$disorder2inheritance_tsv\" does not exist.\n";

####################################

print "\nParsing disorder2gene input file.\n\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $disorder2gene_tsv or die "Cannot index input file.\n";

# Go through every line
for (my $i = 0; $i < scalar(@input_file_lines); $i++) {
	# Ignore header lines
	if ($input_file_lines[$i] =~ /^disorder.*/) {
		next;
	}
	
	# Split the row by tab characters
	my @split_line = split(/\t/, $input_file_lines[$i]);
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input VCF file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	} elsif (scalar(@split_line) != $num_input_columns_disorder2gene) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns_disorder2gene." columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		next;
	}
	
	#disorder_id	disorder_on	disorder_name	gene_symbol	gene_on	assoc_type	assoc_status
	#1	17601	166024	Multiple epiphyseal dysplasia, Al-Gazali type	KIF7	268061	Disease-causing germline mutation(s) in	Assessed
	
	# Store the disorder<->gene links
	$disorders{$split_line[2]}{"name"} = $split_line[3];
	push(@{$disorders{$split_line[2]}{"genes"}{$split_line[4]}{"association_type"}}, $split_line[6]);
	push(@{$disorders{$split_line[2]}{"genes"}{$split_line[4]}{"association_status"}}, $split_line[7]);
	
	# Iterate the number of dirorder<->gene links
	$num_genes_to_disorders_links++;
	
	# Store unique values
	$unique_genes{$split_line[4]} = 1;
	$unique_association_types{$split_line[6]} = 1;
	$unique_association_statuses{$split_line[7]} = 1;
	
	if ($i =~ /000$/) {
		print "[".localtime()."] Parsed: ".$i." lines (out of ".(scalar(@input_file_lines)-1).")\n";
	}
}

print "\nFinished parsing disorder2gene input file.\n";

untie @input_file_lines;

####################################

print "\nParsing disorder2age input file.\n\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $disorder2age_tsv or die "Cannot index input file.\n";

# Go through every line
for (my $i = 0; $i < scalar(@input_file_lines); $i++) {
	# Ignore header lines
	if ($input_file_lines[$i] =~ /^disorder.*/) {
		next;
	}
	
	# Split the row by tab characters
	my @split_line = split(/\t/, $input_file_lines[$i]);
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input VCF file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	} elsif (scalar(@split_line) != $num_input_columns_disorder2age) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns_disorder2age." columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		next;
	}
	
	#disorder_on	age_of_onset
	#1	166024	Neonatal
	
	# Only store ages of onset for disorders seen in the disorders<->genes parsing
	if (defined($disorders{$split_line[1]})) {
		# Store the age of onset for the disorder
		push(@{$disorders{$split_line[1]}{"age_of_onset"}}, $split_line[2]);
		
		# Iterate the number of age of onset<->disorder links
		$num_age_of_onsets_to_disorders_links++;
	
		# Store unique values
		$unique_age_of_onsets{$split_line[2]} = 1;
	
		if ($i =~ /000$/) {
			print "[".localtime()."] Parsed: ".$i." lines (out of ".(scalar(@input_file_lines)-1).")\n";
		}
	}
}

print "\nFinished parsing disorder2age input file.\n";

untie @input_file_lines;

####################################

print "\nParsing disorder2inheritance input file.\n\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $disorder2inheritance_tsv or die "Cannot index input file.\n";

# Go through every line
for (my $i = 0; $i < scalar(@input_file_lines); $i++) {
	# Ignore header lines
	if ($input_file_lines[$i] =~ /^disorder.*/) {
		next;
	}
	
	# Split the row by tab characters
	my @split_line = split(/\t/, $input_file_lines[$i]);
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input VCF file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	} elsif (scalar(@split_line) != $num_input_columns_disorder2inheritance) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns_disorder2inheritance." columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		next;
	}
	
	#disorder_on	inheritance
	#1	166024	Autosomal recessive
	
	# Only store inheritances for disorders seen in the disorders<->genes parsing
	if (defined($disorders{$split_line[1]})) {
		# Store the inheritance for the disorder
		push(@{$disorders{$split_line[1]}{"inheritance"}}, $split_line[2]);
		
		# Iterate the number of inheritance<->disorder links
		$num_inheritances_to_disorders_links++;
		
		# Store unique values
		$unique_inheritances{$split_line[2]} = 1;
	
		if ($i =~ /000$/) {
			print "[".localtime()."] Parsed: ".$i." lines (out of ".(scalar(@input_file_lines)-1).")\n";
		}
	}
}

print "\nFinished parsing disorder2inheritance input file.\n";

untie @input_file_lines;

####################################

print "\nAdding unique genes to the database.\n\n";

$mysql_query_fresh = "INSERT INTO orphanet_genes (gene_name) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $unique_gene (keys %unique_genes) {
	# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
	$mysql_query .= "(?), ";
	
	# Add the values to be inserted
	push(@insert_values, $unique_gene);
	
	# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
	if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_orphanet_genes || (scalar(keys(%unique_genes)) == (scalar(@insert_values) / $num_insert_columns_orphanet_genes) + $inserted_rows)) {		
		execute_query($num_insert_columns_orphanet_genes, scalar(keys(%unique_genes)));
	}	
}

print "\nFinished adding unique genes to the database. Inserted a total of ".$inserted_rows." rows.\n";

# Reset the inserted rows count
$inserted_rows = 0;

####################################

print "\nAdding unique disorders to the database.\n\n";

$mysql_query_fresh = "INSERT INTO orphanet_disorders (orphanet_number, orphanet_name) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $unique_orphanumber (keys %disorders) {
	# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
	$mysql_query .= "(?, ?), ";
	
	# Add the values to be inserted
	push(@insert_values, $unique_orphanumber);
	push(@insert_values, $disorders{$unique_orphanumber}{"name"});
	
	# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
	if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_orphanet_disorders || (scalar(keys(%disorders)) == (scalar(@insert_values) / $num_insert_columns_orphanet_disorders) + $inserted_rows)) {		
		execute_query($num_insert_columns_orphanet_disorders, scalar(keys(%disorders)));
	}
}

print "\nFinished adding unique disorders to the database. Inserted a total of ".$inserted_rows." rows.\n";

# Reset the inserted rows count
$inserted_rows = 0;

####################################

print "\nAdding unique inheritances to the database.\n\n";

$mysql_query_fresh = "INSERT INTO orphanet_inheritances (inheritance_name) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $unique_inheritance (keys %unique_inheritances) {
	# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
	$mysql_query .= "(?), ";
	
	# Add the values to be inserted
	push(@insert_values, $unique_inheritance);
	
	# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
	if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_orphanet_inheritances || (scalar(keys(%unique_inheritances)) == (scalar(@insert_values) / $num_insert_columns_orphanet_inheritances) + $inserted_rows)) {		
		execute_query($num_insert_columns_orphanet_inheritances, scalar(keys(%unique_inheritances)));
	}
}

print "\nFinished adding unique inheritances to the database. Inserted a total of ".$inserted_rows." rows.\n";

# Reset the inserted rows count
$inserted_rows = 0;

####################################

print "\nAdding unique ages of onset to the database.\n\n";

$mysql_query_fresh = "INSERT INTO orphanet_age_of_onsets (age_of_onset) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $unique_age_of_onset (keys %unique_age_of_onsets) {
	# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
	$mysql_query .= "(?), ";
	
	# Add the values to be inserted
	push(@insert_values, $unique_age_of_onset);
	
	# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
	if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_orphanet_ages_of_onset || (scalar(keys(%unique_age_of_onsets)) == (scalar(@insert_values) / $num_insert_columns_orphanet_ages_of_onset) + $inserted_rows)) {		
		execute_query($num_insert_columns_orphanet_ages_of_onset, scalar(keys(%unique_age_of_onsets)));
	}
}

print "\nFinished adding unique ages of onset to the database. Inserted a total of ".$inserted_rows." rows.\n";

# Reset the inserted rows count
$inserted_rows = 0;

####################################

print "\nAdding unique association types to the database.\n\n";

$mysql_query_fresh = "INSERT INTO association_types (association_type) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $unique_association_type (keys %unique_association_types) {
	# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
	$mysql_query .= "(?), ";
	
	# Add the values to be inserted
	push(@insert_values, $unique_association_type);
	
	# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
	if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_association_types || (scalar(keys(%unique_association_types)) == (scalar(@insert_values) / $num_insert_columns_association_types) + $inserted_rows)) {		
		execute_query($num_insert_columns_association_types, scalar(keys(%unique_association_types)));
	}
}

print "\nFinished adding unique association types to the database. Inserted a total of ".$inserted_rows." rows.\n";

# Reset the inserted rows count
$inserted_rows = 0;

####################################

print "\nAdding unique association statuses to the database.\n\n";

$mysql_query_fresh = "INSERT INTO association_statuses (association_status) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $unique_association_status (keys %unique_association_statuses) {
	# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
	$mysql_query .= "(?), ";
	
	# Add the values to be inserted
	push(@insert_values, $unique_association_status);
	
	# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
	if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_association_statuses || (scalar(keys(%unique_association_statuses)) == (scalar(@insert_values) / $num_insert_columns_association_statuses) + $inserted_rows)) {		
		execute_query($num_insert_columns_association_statuses, scalar(keys(%unique_association_statuses)));
	}
}

print "\nFinished adding unique association statuses to the database. Inserted a total of ".$inserted_rows." rows.\n";

# Reset the inserted rows count
$inserted_rows = 0;

####################################

print "\nLinking genes to disorders in the database.\n\n";

$mysql_query_fresh = "INSERT INTO genes_to_disorders (gene_id, disorder_id, association_type_id, association_status_id) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $disorder_orphanumber (keys %disorders) {
	foreach my $gene (keys $disorders{$disorder_orphanumber}{"genes"}) {
		for (my $i = 0; $i < scalar(@{$disorders{$disorder_orphanumber}{"genes"}{$gene}{"association_type"}}); $i++) {
			$mysql_query .= "(";
				$mysql_query .= "(SELECT id FROM orphanet_genes WHERE gene_name = ?), ";
				$mysql_query .= "(SELECT id FROM orphanet_disorders WHERE orphanet_number = ?), ";
				$mysql_query .= "(SELECT id FROM association_types WHERE association_type = ?), ";
				$mysql_query .= "(SELECT id FROM association_statuses WHERE association_status = ?)";
			$mysql_query .= "), ";
			
			# Add the values to be inserted
			push(@insert_values, $gene); # gene_name
			push(@insert_values, $disorder_orphanumber); # orphanet_number
			push(@insert_values, @{$disorders{$disorder_orphanumber}{"genes"}{$gene}{"association_type"}}[$i]); # association_type
			push(@insert_values, @{$disorders{$disorder_orphanumber}{"genes"}{$gene}{"association_status"}}[$i]); # association_status

			# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
			if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_genes_to_disorders || ($num_genes_to_disorders_links == (scalar(@insert_values) / $num_insert_columns_genes_to_disorders) + $inserted_rows)) {		
				execute_query($num_insert_columns_genes_to_disorders, $num_genes_to_disorders_links);
			}
		}
	}
}

print "\nFinished linking genes to disorders in the database. Inserted a total of ".$inserted_rows." rows.\n";

# Reset the inserted rows count
$inserted_rows = 0;

####################################

print "\nLinking inheritances to disorders in the database.\n\n";

$mysql_query_fresh = "INSERT INTO inheritances_to_disorders (inheritance_id, disorder_id) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $disorder_orphanumber (keys %disorders) {
	foreach my $inheritance (@{$disorders{$disorder_orphanumber}{"inheritance"}}) {
		$mysql_query .= "(";
			$mysql_query .= "(SELECT id FROM orphanet_inheritances WHERE inheritance_name = ?), ";
			$mysql_query .= "(SELECT id FROM orphanet_disorders WHERE orphanet_number = ?)";
		$mysql_query .= "), ";
		
		# Add the values to be inserted
		push(@insert_values, $inheritance); # inheritance_name
		push(@insert_values, $disorder_orphanumber); # orphanet_number

		# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
		if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_inheritances_to_disorders || ($num_inheritances_to_disorders_links == (scalar(@insert_values) / $num_insert_columns_inheritances_to_disorders) + $inserted_rows)) {		
			execute_query($num_insert_columns_inheritances_to_disorders, $num_inheritances_to_disorders_links);
		}
	}
}

print "\nFinished inheritances to disorders in the database. Inserted a total of ".$inserted_rows." rows.\n";

# Reset the inserted rows count
$inserted_rows = 0;

####################################

print "\nLinking ages of onset to disorders in the database.\n\n";

$mysql_query_fresh = "INSERT INTO age_of_onsets_to_disorders (age_of_onset_id, disorder_id) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $disorder_orphanumber (keys %disorders) {
	foreach my $age_of_onset (@{$disorders{$disorder_orphanumber}{"age_of_onset"}}) {
		$mysql_query .= "(";
			$mysql_query .= "(SELECT id FROM orphanet_age_of_onsets WHERE age_of_onset = ?), ";
			$mysql_query .= "(SELECT id FROM orphanet_disorders WHERE orphanet_number = ?)";
		$mysql_query .= "), ";
		
		# Add the values to be inserted
		push(@insert_values, $age_of_onset); # age_of_onset
		push(@insert_values, $disorder_orphanumber); # orphanet_number

		# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
		if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_age_of_onsets_to_disorders || ($num_age_of_onsets_to_disorders_links == (scalar(@insert_values) / $num_insert_columns_age_of_onsets_to_disorders) + $inserted_rows)) {		
			execute_query($num_insert_columns_age_of_onsets_to_disorders, $num_age_of_onsets_to_disorders_links);
		}
	}
}

print "\nFinished ages of onset to disorders in the database. Inserted a total of ".$inserted_rows." rows.\n";

# Reset the inserted rows count
$inserted_rows = 0;

####################################

print "\nFinished adding all rows to the database!\n";

exit;

####################################

# Function to execute a DB query
sub execute_query {
	my ($num_insert_columns, $num_rows_to_insert) = @_;
	
	# Remove extra ", " at the end of the query
	$mysql_query = substr($mysql_query, 0, -2);
	
	# Execute the query on the DB
	my $sth = $dbh->prepare($mysql_query);
	$sth->execute(@insert_values) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
	$sth->finish();
	
	# Iterate the count of inserted rows with the number that will be inserted
	$inserted_rows += (scalar(@insert_values) / $num_insert_columns);
	
	print "[".localtime()."] Inserted: ".$inserted_rows." rows (out of ".$num_rows_to_insert.")\n";
	
	# Empty the array of values to add
	@insert_values = ();

	# Reset the MySQL query
	$mysql_query = $mysql_query_fresh;
	
	return 1;
}
