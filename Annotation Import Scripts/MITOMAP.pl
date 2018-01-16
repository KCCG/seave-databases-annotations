#!/usr/bin/perl

use strict;
use warnings;
use DBI; # MySQL connection
use Tie::File; # File -> array for parsing without loading whole thing into RAM

####################################

my $disease_input_file; # Stores the disease input path/filename from the argument passed to the script
my $polymorphisms_input_file; # Stores the polymorphisms input path/filename from the argument passed to the script
my $mysql_host; # Stores the MySQL hostname to connect to from the argument passed to the script
my $mysql_user; # Stores the MySQL username to connect to from the argument passed to the script
my $mysql_password; # Stores the MySQL password to connect to from the argument passed to the script

if (scalar(@ARGV) != 5) {
	print "FATAL ERROR: arguments must be supplied as 1) input file path to disease.vcf 2) input file path to polymorphisms.vcf 3) MySQL host 4) MySQL user 5) MySQL password.\n";
	exit;
} else {
	$disease_input_file = $ARGV[0];
	$polymorphisms_input_file = $ARGV[1];
	$mysql_host = $ARGV[2];
	$mysql_user = $ARGV[3];
	$mysql_password = $ARGV[4];
}

####################################

my $driver = "mysql"; 
my $database = "MITOMAP_NEW";
my $dsn = "DBI:$driver:database=$database;host=$mysql_host";

my $dbh = DBI->connect($dsn, $mysql_user, $mysql_password) or die $DBI::errstr;

####################################

my $num_input_columns = 8; # The number of columns expected in the input VCF
my $num_insert_columns = 8; # The number of columns being inserted into the DB
my $num_rows_to_add_per_insert = 1000;

my @input_file_lines;
my $total_variants = 0;
my $inserted_rows = 0;
my @insert_values;

my %variant_store;

####################################

# Check that the input file exists
-e $disease_input_file or die "File \"$disease_input_file\" does not exist.\n";

print "\nParsing diseases input file.\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $disease_input_file or die "Cannot index input file.\n";

for (my $i = 0; $i < scalar(@input_file_lines); $i++) {
	# MT	616	.	T	C,G	.	.	AC=1,1;AF=0.00,0.00;Disease=Maternally inherited epilepsy;DiseaseStatus=Reported
	
	# Ignore header lines
	if ($input_file_lines[$i] =~ /^#.*/) {
		next;
	}
	
	# Split the row by tab characters
	my @split_line = split(/\t/, $input_file_lines[$i]);
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	} elsif (scalar(@split_line) != $num_input_columns) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns." columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		next;
	}
	
	my $chr = $split_line[0];
	my $position = $split_line[1];
	my $ref = $split_line[3];
	my $alt = $split_line[4];
	my $disease = "";
	my $diseasestatus = "";
	
	# Extract the disease
	if ($split_line[7] =~ /Disease=(.*?);/) {
		$disease = $1;
	} else {
		print "ERROR: could not find the associated disease on line: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		exit;
	}
	
	# Extract the disease status
	if ($split_line[7] =~ /DiseaseStatus=(.*)$/) {
		$diseasestatus = $1;
	} else {
		print "ERROR: could not find the associated disease status on line: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		exit;
	}
	
	my @split_alt = split(/,/, $alt);
	
	# Go through each ALT allele and save the disease info
	foreach my $current_alt (@split_alt) {
		# Iterate the total number of variants observed
		$total_variants++;
		
		$variant_store{$chr}{$position}{$ref}{$current_alt}{"disease"} = $disease;
		$variant_store{$chr}{$position}{$ref}{$current_alt}{"diseasestatus"} = $diseasestatus;
	}

}

####################################

# Check that the input file exists
-e $polymorphisms_input_file or die "File \"$polymorphisms_input_file\" does not exist.\n";

print "\nParsing polymorphisms input file.\n";

# Load the input file into an array (each element is a line but the whole thing is not loaded into memory)
tie @input_file_lines, 'Tie::File', $polymorphisms_input_file or die "Cannot index input file.\n";

for (my $i = 0; $i < scalar(@input_file_lines); $i++) {
	# MT	16	.	A	C,G,T	.	.	AC=0,0,31;AF=0.00,0.00,0.10
	
	# Ignore header lines
	if ($input_file_lines[$i] =~ /^#.*/) {
		next;
	}
	
	# Split the row by tab characters
	my @split_line = split(/\t/, $input_file_lines[$i]);
	
	if (scalar(@split_line) == 0) {
		print "WARNING: Found a line in the input file that does not contain tab-separated values. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		next;
	} elsif (scalar(@split_line) != $num_input_columns) {
		print "WARNING: Found a line that doesn't contain ".$num_input_columns." columns of information. Line number: ".($i + 1)." Line contents: ".$input_file_lines[$i]." Number of columns detected: ".scalar(@split_line)."\n";
		
		next;
	}
	
	my $chr = $split_line[0];
	my $position = $split_line[1];
	my $ref = $split_line[3];
	my $alt = $split_line[4];
	my $AC = "";
	my $AF = "";
	
	# Extract the allele count
	if ($split_line[7] =~ /AC=(.*?);/) {
		$AC = $1;
	} else {
		print "ERROR: could not find the AC on line: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		exit;
	}
	
	# Extract the allele frequency
	if ($split_line[7] =~ /AF=(.*)$/) {
		$AF = $1;
	} else {
		print "ERROR: could not find the AF on line: ".($i + 1)." Line contents: ".$input_file_lines[$i]."\n";
		
		exit;
	}
	
	my @split_alt = split(/,/, $alt);
	my @split_ac = split(/,/, $AC);
	my @split_af = split(/,/, $AF);
	
	# Make sure the number of AC and AF values is the same as the number of alt alleles
	if (scalar(@split_alt) != scalar(@split_ac) || scalar(@split_alt) != scalar(@split_af)) {
		print "ERROR: number of alt alleles does not equal number of AC or AF values on line: ".($i + 1)."\n";
		
		exit;
	}
	
	# Go through each ALT allele and save the AC and AF
	for (my $x = 0; $x < scalar(@split_alt); $x++) {
		# If the variant has not been seen in the previous input file
		if (!defined($variant_store{$chr}{$position}{$ref}{$split_alt[$x]})) {
			# Iterate the total number of variants observed
			$total_variants++;
		}
		
		$variant_store{$chr}{$position}{$ref}{$split_alt[$x]}{"AC"} = $split_ac[$x];
		$variant_store{$chr}{$position}{$ref}{$split_alt[$x]}{"AF"} = $split_af[$x]/100; # Allele frequency is stored as a percentage in the MITOMAP output (e.g. 75.36) so divide this by 100 to make it 0.7536 and comparable to our other allele frequencies
	}
}

####################################

my $mysql_query_fresh = "INSERT INTO `mitomap` (chr, pos, ref, alt, AC, AF, Disease, DiseaseStatus) VALUES ";
my $mysql_query = $mysql_query_fresh;

foreach my $chromosome (keys(%variant_store)) {
	foreach my $position (keys($variant_store{$chromosome})) {
		foreach my $ref (keys($variant_store{$chromosome}{$position})) {
			foreach my $alt (keys($variant_store{$chromosome}{$position}{$ref})) {
				# Insert a ? as a reference to each variable, this is then populated in the execute() function below on the array of values to put in
				$mysql_query .= "(?, ?, ?, ?, ?, ?, ?, ?), ";
				
				$inserted_rows++;
		
				# Add the values to be inserted
				push(@insert_values, $chromosome); # chr
				push(@insert_values, $position); # position
				push(@insert_values, $ref); # ref
				push(@insert_values, $alt); # alt
				
				# AC
				if (defined($variant_store{$chromosome}{$position}{$ref}{$alt}{"AC"})) {
					push(@insert_values, $variant_store{$chromosome}{$position}{$ref}{$alt}{"AC"});
				} else {
					push(@insert_values, undef); # undef maps to NULL in the DB
				}
				
				# AF
				if (defined($variant_store{$chromosome}{$position}{$ref}{$alt}{"AF"})) {
					push(@insert_values, $variant_store{$chromosome}{$position}{$ref}{$alt}{"AF"});
				} else {
					push(@insert_values, undef); # undef maps to NULL in the DB
				}
				
				# Disease
				if (defined($variant_store{$chromosome}{$position}{$ref}{$alt}{"disease"})) {
					push(@insert_values, $variant_store{$chromosome}{$position}{$ref}{$alt}{"disease"});
				} else {
					push(@insert_values, undef); # undef maps to NULL in the DB
				}
				
				# DiseaseStatus
				if (defined($variant_store{$chromosome}{$position}{$ref}{$alt}{"diseasestatus"})) {
					push(@insert_values, $variant_store{$chromosome}{$position}{$ref}{$alt}{"diseasestatus"});
				} else {
					push(@insert_values, undef); # undef maps to NULL in the DB
				}
				
				# If there are $num_rows_to_add_per_insert waiting to be inserted OR the end of the input file has been reached so all the remaining rows should be inserted
				if ($num_rows_to_add_per_insert == scalar(@insert_values) / $num_insert_columns || $inserted_rows == $total_variants) {
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
					print "[".localtime()."] Processed: ".$inserted_rows." lines from a total of ".$total_variants.".\n";
				}	
			}
		}
	}
}

print "\nPARSING COMPLETE!\nInserted a total of ".$inserted_rows." from ".$total_variants." variants in the input files.\n\n";

exit;