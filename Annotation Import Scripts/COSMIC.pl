#!/usr/bin/perl

use strict;
use warnings;
use DBI; # MySQL connection
use Tie::File; # File -> array for parsing without loading whole thing into RAM

####################################

my $input_file_vcf; # Stores the VCF input path and filename from the argument passed to the script
my $input_file_tsv; # Stores the TSV input path and filename from the argument passed to the script
my $mysql_host; # Stores the MySQL hostname to connect to from the argument passed to the script
my $mysql_user; # Stores the MySQL username to connect to from the argument passed to the script
my $mysql_password; # Stores the MySQL password to connect to from the argument passed to the script

if (scalar(@ARGV) != 5) {
	print "FATAL ERROR: arguments must be supplied as 1) VCF input path and file (CosmicCodingMuts.vcf) 2) TSV input file path and file (CosmicMutantExport.tsv) 3) MySQL host 4) MySQL user 5) MySQL password.\n";
	exit;
} else {
	$input_file_vcf = $ARGV[0];
	$input_file_tsv = $ARGV[1];
	$mysql_host = $ARGV[2];
	$mysql_user = $ARGV[3];
	$mysql_password = $ARGV[4];
}

####################################

my $driver = "mysql"; 
my $database = "COSMIC_NEW";
my $dsn = "DBI:$driver:database=$database;host=$mysql_host";

my $dbh = DBI->connect($dsn, $mysql_user, $mysql_password) or die $DBI::errstr;

####################################

my $num_input_columns_vcf = 8; # The number of columns expected in the input VCF
my $num_input_columns_tsv = 35; # The number of columns expected in the input TSV
my $num_insert_columns_cosmic = 4; # The number of columns being inserted into the DB
my $num_insert_columns_variants = 4; # The number of columns being inserted into the DB
my $num_insert_columns_links = 5; # The number of columns being inserted into the DB
my $num_rows_to_add_per_insert = 10000; # The number of rows to add to the MySQL DB per query sent to it

my $num_ignored_cosmic_snps = 0;

my $mysql_query;
my $mysql_query_fresh;

my $inserted_rows = 0;
my @insert_values;

my $num_variants = 0; # Tracks the number of variants for knowing how many rows will be inserted into the DB
my $num_variant_links = 0; # Tracks the number of variant to COSMIC number links fro knowing how many rows will be inserted into the DB

####################################

# Check that the input files exist
-e $input_file_vcf or die "File \"$input_file_vcf\" does not exist.\n";
-e $input_file_tsv or die "File \"$input_file_tsv\" does not exist.\n";

####################################

my %variants; # Hash to store variants and their COSMIC numbers

print "\nParsing VCF input file.\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
my @input_file_lines;
tie @input_file_lines, 'Tie::File', $input_file_vcf or die "Cannot index input file.\n";

# Go through every line
for (my $i = 0; $i < scalar(@input_file_lines); $i++) {
	# Ignore header lines
	if ($input_file_lines[$i] =~ /^#.*/) {
		next;
	}
	
	# Split the row by tab characters
	my @split_line = split(/\t/, $input_file_lines[$i]);
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input VCF file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	} elsif (scalar(@split_line) != $num_input_columns_vcf) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns_vcf." columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		next;
	}
	
	my $chr = $split_line[0];
	my $position = $split_line[1];
	my $cosmic_id = $split_line[2];
	my $ref = $split_line[3];
	my $alt = $split_line[4];
	
	# Split INFO by semicolon to check for specific values
	my @info_annotations = split(/;/, $split_line[7]);
	
	# Remove any variants that have a SNP tag in INFO - these are in 1000 Genomes or in panels of normals and some can be somatic but the decision was made that overall they add too much noise to our results
	if (grep(/^SNP/, @info_annotations)) {
		$num_ignored_cosmic_snps++;
		
		next;
	}
	
	# QC the ref/alt length
	if (length($ref) > 4000 || length($alt) > 4000) {
		print "Warning: found a variant that has a ref or alt length greater than 4,000 characters (the maximum currently allowed this DB). It will be ignored. Line number: ".($i + 1)."\n";
	
		next;
	}
	
	if (defined($variants{$chr}{$position}{$ref}{$alt})) {
		push(@{$variants{$chr}{$position}{$ref}{$alt}}, $cosmic_id);
		
		# Iterate the number of variant to COSMIC number links
		$num_variant_links++;
	} else {
		$variants{$chr}{$position}{$ref}{$alt} = ();
		
		push(@{$variants{$chr}{$position}{$ref}{$alt}}, $cosmic_id);
		
		# Iterate the number of unique variants count
		$num_variants++;
		
		# Iterate the number of variant to COSMIC number links
		$num_variant_links++;
	}
	
	if ($i =~ /00000$/) {
		print "[".localtime()."] Parsed: ".$i." lines (out of ".(scalar(@input_file_lines)-1).")\n";
	}
}

print "\nFinished parsing VCF input file.\n";

print "\nFound ".$num_ignored_cosmic_snps." common variants marked as SNPs. These were ignored. This number should NOT be zero or the VCF format has changed!\n";

untie @input_file_lines;

####################################

my %cosmic_numbers; # Hash to store COSMIC count, primary sites and histology counts

print "\nParsing TSV input file.\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $input_file_tsv or die "Cannot index input file.\n";

# Go through every line
for (my $i = 0; $i < scalar(@input_file_lines); $i++) {
	# Ignore header line
	if ($input_file_lines[$i] =~ /^Gene.*/) {
		next;
	}
	
	# Split the row by tab characters
	my @split_line = split(/\t/, $input_file_lines[$i], -1); # -1 here will treat a tab character following by nothing as an element rather than ignoring it
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input TSV file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	} elsif (scalar(@split_line) != $num_input_columns_tsv) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns_tsv." columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		print join("\n",@split_line),"\n";
		
		die;
	}
	
	my $cosmic_number = $split_line[16];
	my $primary_site = $split_line[7];
	my $primary_histology = $split_line[11];
	
	# Iterate the primary site for the COSMIC number
	$cosmic_numbers{$cosmic_number}{"primary_site"}{$primary_site}++;
	
	# Iterate the primary histology for the COSMIC number
	$cosmic_numbers{$cosmic_number}{"primary_histology"}{$primary_histology}++;
		
	if ($i =~ /00000$/) {
		print "[".localtime()."] Parsed: ".$i." lines (out of ".(scalar(@input_file_lines)-1).")\n";
	}
}

print "\nFinished parsing TSV input file.\n";

####################################

print "\nAdding COSMIC number information to the database.\n";

$mysql_query_fresh = "INSERT INTO cosmic_numbers (cosmic_number, cosmic_count, cosmic_primary_site, cosmic_primary_histology) VALUES ";
$mysql_query = $mysql_query_fresh;

foreach my $cosmic_number (keys %cosmic_numbers) {
	# Define variables to store the concatenated primary site and primary histology counts
	my $primary_site_count;
	my $primary_histology_count;
	my $cosmic_count = 0;
	
	# Create the primary site count string
	foreach my $primary_site (keys $cosmic_numbers{$cosmic_number}{"primary_site"}) {
		$primary_site_count .= $primary_site.": ".$cosmic_numbers{$cosmic_number}{"primary_site"}{$primary_site}."; ";
		
		# Determine the total COSMIC count from the number of primary sites observed for the COSMIC number
		$cosmic_count += $cosmic_numbers{$cosmic_number}{"primary_site"}{$primary_site};
	}
	
	# Create the primary histology count string
	foreach my $primary_histology (keys $cosmic_numbers{$cosmic_number}{"primary_histology"}) {
		$primary_histology_count .= $primary_histology.": ".$cosmic_numbers{$cosmic_number}{"primary_histology"}{$primary_histology}."; ";
	}
	
	# Remove the last 2 characters added by the loops above
	$primary_site_count = substr($primary_site_count, 0, -2);
	$primary_histology_count = substr($primary_histology_count, 0, -2);
	
	# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
	$mysql_query .= "(?, ?, ?, ?), ";
	
	# Add the values to be inserted
	push(@insert_values, $cosmic_number); # cosmic_number
	push(@insert_values, $cosmic_count); # count
	push(@insert_values, $primary_site_count); # primary_site
	push(@insert_values, $primary_histology_count); # primary_histology

	# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
	if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_cosmic || (scalar(keys(%cosmic_numbers)) == (scalar(@insert_values) / $num_insert_columns_cosmic) + $inserted_rows)) {		
		# Remove extra ", " at the end of the query
		$mysql_query = substr($mysql_query, 0, -2);
		
		# Execute the insertion of the row into the MySQL DB
		my $sth = $dbh->prepare($mysql_query);
		$sth->execute(@insert_values) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
		$sth->finish();
		
		# Iterate the count of inserted rows but the number that will be inserted
		$inserted_rows += (scalar(@insert_values) / $num_insert_columns_cosmic);
		
		print "[".localtime()."] Inserted: ".$inserted_rows." rows (out of ".(scalar(keys(%cosmic_numbers))).")\n";
		
		# Empty the array of values to add
		@insert_values = ();
	
		# Reset the MySQL query
		$mysql_query = $mysql_query_fresh;
	}
}

print "\nFinished adding COSMIC number information to the database. Inserted a total of ".$inserted_rows." rows.\n";

####################################

print "\nAdding variants to the database.\n";

# Clear the MySQL query from the last block
$mysql_query = "";

# Empty the array of values to add
@insert_values = ();

# Reset the inserted rows count
$inserted_rows = 0;

# MySQL query for adding the variant
$mysql_query_fresh = "INSERT INTO variants (chr, pos, ref, alt) VALUES ";
$mysql_query = $mysql_query_fresh;

# Go through every variant
foreach my $chr (keys %variants) {
	foreach my $position (keys $variants{$chr}) {
		foreach my $ref (keys $variants{$chr}{$position}) {
			foreach my $alt (keys $variants{$chr}{$position}{$ref}) {
				$mysql_query .= "(?, ?, ?, ?), ";
				
				# Add the values to be inserted
				push(@insert_values, $chr); # chr
				push(@insert_values, $position); # pos
				push(@insert_values, $ref); # ref
				push(@insert_values, $alt); # alt
				
				# If the number of rows awaiting insertion is greater than or equal to the insertion count or the batch of rows has been reached
				if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_variants || ($num_variants == (scalar(@insert_values) / $num_insert_columns_variants) + $inserted_rows)) {		
					# Remove extra ", " at the end of the query added by the loop above
					$mysql_query = substr($mysql_query, 0, -2);
				
					$mysql_query .= "; ";

					# Execute the insertion of the row into the MySQL DB
					my $sth = $dbh->prepare($mysql_query);
					$sth->execute(@insert_values) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query;
					$sth->finish();
		
					# Iterate the count of inserted rows but the number that will be inserted
					$inserted_rows += (scalar(@insert_values) / $num_insert_columns_variants);
					
					print "[".localtime()."] Inserted: ".$inserted_rows." rows (out of ".$num_variants.")\n";
					
					# Empty the array of values to add
					@insert_values = ();
	
					# Reset the MySQL query
					$mysql_query = $mysql_query_fresh;
				}
			}
		}
	}
}

print "\nFinished adding variants to the database. Inserted a total of ".$inserted_rows." rows.\n";

####################################

print "\nLinking variants to COSMIC numbers in the database.\n";

# Clear the MySQL query from the last block
$mysql_query = "";

# Empty the array of values to add
@insert_values = ();

# Reset the inserted rows count
$inserted_rows = 0;

# MySQL query for adding the variant
$mysql_query_fresh = "INSERT INTO cosmic_number_to_variant (cosmic_number, variant_id) VALUES ";
$mysql_query = $mysql_query_fresh;

# Go through every COSMIC number for every variant
foreach my $chr (keys %variants) {
	foreach my $position (keys $variants{$chr}) {
		foreach my $ref (keys $variants{$chr}{$position}) {
			foreach my $alt (keys $variants{$chr}{$position}{$ref}) {
				foreach my $cosmic_number (@{$variants{$chr}{$position}{$ref}{$alt}}) {
					$mysql_query .= "(?, (SELECT variants.id FROM variants WHERE chr = ? AND pos = ? AND ref = ? AND alt = ?)), ";
				
					# Add the values to be inserted
					push(@insert_values, $cosmic_number); # chr
					push(@insert_values, $chr); # chr
					push(@insert_values, $position); # pos
					push(@insert_values, $ref); # ref
					push(@insert_values, $alt); # alt
				
					# If the number of rows awaiting insertion is greater than or equal to the insertion count or the batch of rows has been reached
					if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns_links || ($num_variant_links == (scalar(@insert_values) / $num_insert_columns_links) + $inserted_rows)) {		
						# Remove extra ", " at the end of the query added by the loop above
						$mysql_query = substr($mysql_query, 0, -2);
				
						$mysql_query .= "; ";

						# Execute the insertion of the row into the MySQL DB
						my $sth = $dbh->prepare($mysql_query);
						$sth->execute(@insert_values) or die $DBI::errstr."\n\nQuery causing problem: ".$mysql_query." values:". join(",",@insert_values);
						$sth->finish();
		
						# Iterate the count of inserted rows but the number that will be inserted
						$inserted_rows += (scalar(@insert_values) / $num_insert_columns_links);
					
						print "[".localtime()."] Inserted: ".$inserted_rows." rows (out of ".$num_variant_links.")\n";
					
						# Empty the array of values to add
						@insert_values = ();
	
						# Reset the MySQL query
						$mysql_query = $mysql_query_fresh;
					}
				}
			}
		}
	}
}

print "\nFinished linking variants to COSMIC numbers in the database. Inserted a total of ".$inserted_rows." rows.\n";

####################################

exit;