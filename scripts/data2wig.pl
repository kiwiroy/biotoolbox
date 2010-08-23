#!/usr/bin/perl

# A script to convert a generic data file into a wig file
# this presumes it has chromosomal coordinates to convert

use strict;
use Getopt::Long;
use Pod::Usage;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use tim_file_helper;
use tim_db_helper qw(open_db_connection);

print "\n This script will export a data file to a wig file\n\n";


### Quick help
unless (@ARGV) { 
	# when no command line options are present
	# print SYNOPSIS
	pod2usage( {
		'-verbose' => 0, 
		'-exitval' => 1,
	} );
}



### Get command line options and initialize values
my (
	$infile, 
	$outfile,
	$step,
	$step_size,
	$score_index,
	$track_name,
	$use_track,
	$midpoint,
	$format,
	$bigwig,
	$database,
	$method,
	$gz,
	$help
);


# Command line options
GetOptions( 
	'in=s'      => \$infile, # name of input file
	'out=s'     => \$outfile, # name of output gff file 
	'step=s'    => \$step, # wig step method
	'size=i'    => \$step_size, # wig step size
	'score=i'   => \$score_index, # index for the score column
	'name=s'    => \$track_name, # index for the name column
	'track!'    => \$use_track, # boolean to include a track line
	'midpoint!' => \$midpoint, # boolean to use the midpoint
	'format=i'  => \$format, # format output to indicated number of places
	'bigwig'    => \$bigwig, # generate a binary bigwig file
	'db=s'      => \$database, # database for bigwig file generation
	'gz!'       => \$gz, # boolean to compress output file
	'help'      => \$help # request help
);

# Print help
if ($help) {
	# print entire POD
	pod2usage( {
		'-verbose' => 2,
		'-exitval' => 1,
	} );
}



### Check for required values
unless ($infile) {
	$infile = shift @ARGV or
		die "  OOPS! No source data file specified! \n use $0 --help\n";
}
unless (defined $use_track) {
	if ($bigwig) {
		# if we're generating bigwig file, no track is needed
		$use_track = 0;
	}
	else {
		# default is to to generate a track
		$use_track = 1;
	}
}
if ($bigwig) {
	eval {use Bio::DB::BigFile};
	die "can't use bigwig function! $@ \n" if $@;
}



### Load file
my ($in_fh, $metadata_ref) = open_tim_data_file($infile);
unless ($in_fh) {
	die "Unable to open data table!\n";
}

# identify indices
my ($chr_index, $start_index, $stop_index);
for (my $i = 0; $i < $metadata_ref->{'number_columns'}; $i++) {
	# check the names of each column
	# looking for chromo, start, stop
	if ($metadata_ref->{$i}{'name'} =~ /^chrom|refseq/i) {
		$chr_index = $i;
	}
	elsif ($metadata_ref->{$i}{'name'} =~ /start/i) {
		$start_index = $i;
	}
	elsif ($metadata_ref->{$i}{'name'} =~ /stop|end/i) {
		$stop_index = $i;
	}
}
unless (defined $chr_index and defined $start_index) {
	die " No genomic coordinates found in the file!\n";
}

# identify database if needed
if ($bigwig and !$database) {
	if (exists $metadata_ref->{db}) {
		$database = $metadata_ref->{db};
	}
	else {
		die " No database identified for generating bigwig file!\n";
	}
}



### Check and/or ask for specific options
# request score index
unless (defined $score_index) {
	
	# gff
	if ( $metadata_ref->{'gff'} ) {
		# if it is a gff file, it will be the score index
		$score_index = 5;
	}
	
	# sgr
	elsif ( $metadata_ref->{'extension'} =~ /sgr/ ) {
		# if it is a sgr file, it will be the score index
		$score_index = 2;
	}
	
	# bed
	elsif ( 
		$metadata_ref->{'extension'} =~ /bed/ and
		$metadata_ref->{'number_columns'} >=5
	) {
		# if it is a bed file, it will be the score index
		$score_index = 4;
	}
	
	# ask the user
	else {
	
		# print the column names
		print " These are the column names in the datafile\n";
		for (my $i = 0; $i < $metadata_ref->{'number_columns'}; $i++) {
			print "   $i\t", $metadata_ref->{$i}{'name'}, "\n";
		}
		
		# ask for the score index
		print " Enter the index for the feature score column  ";
		$score_index = <STDIN>;
		chomp $score_index;
	}
}

# request track name
unless (defined $track_name) {
	if ( 
		$metadata_ref->{'gff'} or
		$metadata_ref->{'extension'} =~ /sgr/ or
		$metadata_ref->{'extension'} =~ /bed/
	) {
		# if it is a gff/sgr/bed file, use the base file name
		# I have a practice of using the GFF type as the file name
		# this is easier than attempting to read the type column from the gff file
		$track_name = $metadata_ref->{'basename'};
	}
	else {
		# use the name of the score column
		$track_name = $metadata_ref->{$score_index}{'name'};
	}
}

# check step 
if ($step eq 'variable') {
	# this is ok, we can work with it
}
elsif ($step eq 'fixed') {
	# double check that the data file supports this
	# assign the step size as necessary
	if ( exists $metadata_ref->{$start_index}{'step'} ) {
		$step_size = $metadata_ref->{$start_index}{'step'};
	}
	else {
		warn " no step size indicated for 'fixedStep' wig file! Using 'variableStep'\n";
		$step = 'variable';
	}
}
else {
	# attempt to determine automatically
	if ( exists $metadata_ref->{$start_index}{'step'} ) {
		print " Automatically generating 'fixedStep' wig....\n";
		$step = 'fixed';
		$step_size = $metadata_ref->{$start_index}{'step'};
	}
	else {
		print " Automatically generating 'variableStep' wig....\n";
		$step = 'variable';
	}
}



### Open output file
unless ($outfile) {
	# automatically generate output file name based on track name
	$outfile = $track_name;
}
unless ($outfile =~ /\.wig$/i) {
	# add extension
	$outfile .= '.wig';
}
my $out_fh = open_to_write_fh($outfile, $gz) or 
	die " unable to open output file '$outfile' for writing!\n";

# write track line
if ($use_track) {
	print {$out_fh} "track type=wiggle_0 name=$track_name\n";
}



### Start the conversion 
print " converting '" . $metadata_ref->{$score_index}{'name'} . "'....\n";
my $current_chr; # current chromosome
while (my $line = $in_fh->getline) {
	chomp $line;
	my @data = split /\t/, $line;
	
	# write definition line if necessary
	if ($data[$chr_index] ne $current_chr) {
		# new chromosome, new definition line
		
		if ($step eq 'fixed') {
			
			# need to determine start position first
			my $start;
			if ($midpoint) {
				# user requested to use the midpoint
				if ( 
					defined $stop_index and 
					$data[$start_index] != $data[$stop_index] 
				) {
					# not same position, so calculate midpoint
					$start = sprintf "%.0f", 
						( $data[$start_index] + $data[$stop_index] ) / 2;
				}
				else {
					# same position
					$start = $data[$start_index];
				}
			}
			else {
				# otherwise use the start position
				$start = $data[$start_index];
			}
			
			# print definition line
			print {$out_fh} 'fixedStep chrom=' . $data[$chr_index] . ' start=' .
				$start . ' step=' . $step_size . "\n";
			
		}
		else { 
			# only other possibility should be variable
			print {$out_fh} 'variableStep chrom=' . $data[$chr_index] . "\n";
		}
		
		# reset the current chromosome
		$current_chr = $data[$chr_index];
	}
	
	
	# adjust score formatting as requested
	my $score;
	if ($data[$score_index] eq '.') {
		# an internal null value
		# treat it as 0, is that ok?
		$score = 0;
	}
	else {
		# numerical (I presume) score
		if (defined $format) {
			# format the score value to the indicated number of spaces
			if ($format == 0) {
				# no decimal places
				$score = sprintf( "%.0f", $data[$score_index]);
			}
			elsif ($format == 1) {
				# 1 decimal place
				$score = sprintf( "%.1f", $data[$score_index]);
			}
			elsif ($format == 2) {
				# 2 decimal places
				$score = sprintf( "%.2f", $data[$score_index]);
			}
			elsif ($format == 3) {
				# 3 decimal places
				$score = sprintf( "%.3f", $data[$score_index]);
			}
			else {
				# unrecognized value, no formatting
				$score = $data[$score_index];
			}
		}
		else {
			# no formatting, take as is
			$score = $data[$score_index];
		}
	}
	
	
	# write data line
	if ($step eq 'fixed') {
		print {$out_fh} "$score\n";
	}
	else {
		# variable step data line
		my $position;
		if ($midpoint) {
			# user requested to use the midpoint
			if (
				defined $stop_index and 
				$data[$start_index] != $data[$stop_index] 
			) {
				# not same position, so calculate midpoint
				$position = sprintf "%.0f", 
					( $data[$start_index] + $data[$stop_index] ) / 2;
			}
			else {
				# same position
				$position = $data[$start_index];
			}
		}
		else {
			# default to start position
			$position = $data[$start_index];
		}
		
		print {$out_fh} "$position $score\n";
	}
}

# close files
$in_fh->close;
$out_fh->close;



### Generate BigWig file format
if ($bigwig) {
	# requested to continue and generate a binary bigwig file
	print " temporary wig file '$outfile' generated\n";
	print " converting to bigwig file....\n";
	
	
	# open database connection
	my $db = open_db_connection($database) or
		die " unable to open database to get chromosome lengths!\n";
	
	
	# generate chromosome lengths file
	my @chromos = $db->features(-type => 'chromosome');
	unless (@chromos) {
		die " no chromosome features identified in database!\n";
	}
	open FILE, ">chromosome_lengths.txt";
	foreach (@chromos) {
		print FILE $_->name, "\t", $_->length, "\n";
	}
	close FILE;
	
	
	# generate the bigwig file 
		# we are using the Bio::DB::BigFile module to generate the 
		# bigwig file
		# however, Lincoln notes that this method may be deprecated
		# in future versions
		# for the time being we will use this method as it avoids
		# having to hunt down Jim Kent's utility in the path
		
		# we'll use Lincoln's default values, which are slightly
		# different from Kent's default values in his utility
		# but I'm not sure the reasoning behind the differences
	my $bw_file = $outfile;
	$bw_file =~ s/\.wig$/.bw/;
	Bio::DB::BigFile->createBigWig(
		$outfile, 
		"chromosome_lengths.txt",
		$bw_file
	);
	unlink "chromosome_lengths.txt"; # we don't need this anymore
	
	
	# confirm
	if (-e $bw_file) {
		print " bigwig file '$bw_file' generated\n";
		unlink $outfile; # remove the wig file
	}
	else {
		die " bigwig file not generated! see standard error\n";
	}
	
}

else {
	# no big wig file needed, we're finished
	print " finished! wrote file '$outfile'\n";
}




__END__

=head1 NAME

data2wig.pl

A script to convert a generic data file into a wig file.

=head1 SYNOPSIS

data2wig.pl [--options...] <filename> 
  
  Options:
  --in <filename>
  --out <filename> 
  --step [fixed,variable]
  --size <integer>
  --score <column_index>
  --name <text>
  --(no)track
  --format [0,1,2,3]
  --(no)midpoint
  --bigwig
  --db <database>
  --(no)gz
  --help


=head1 OPTIONS

The command line flags and descriptions:

=over 4

=item --in <filename>

Specify the file name of a data file, with or without the --in flag. 
The file may be any tab-delimited text file (preferably in the tim data 
format as described in L<tim_file_helper.pm>), GFF, SGR, or BED file. 
Recognizeable genome coordinate columns should be present, including 
chromosome, start, and stop. Data files collected using the 'genome' 
windows feature are ideal. The file may be compressed with gzip.

=item --out <filename>

Optionally specify the name of of the output file. The track name is 
used as default. The '.wig' extension is automatically added if required.

=item --step [fixed,variable]

The type of step progression for the wig file. Two wig formats are available:
'fixedStep' where data points are positioned at equal distances along the 
chromosome, and 'variableStep' where data points are not equally spaced 
along the chromosome. The 'fixedStep' wig file has one column of data 
values (score), while the 'variableStep' wig file has two columns
(position and score). If the option is not defined, then the format is 
automatically determined from the metadata of the file.

=item --size <integer>

Optionally define the step size in bp for 'fixedStep' wig file. This 
value is automatically determined from the table's metadata, if available. 
If the --step option is explicitly defined as 'fixed', then the step size 
may also be explicitly defined. If this value is not explicitly
defined or automatically determined, the variableStep format is used by
default.

=item --score <column_index>

Indicate the column index (0-based) of the dataset in the data table 
to be used for the score. If a GFF file is used as input, the score column is 
automatically selected. If not defined as an option, then the program will
interactively ask the user for the column index from a list of available
columns.

=item --name <text>

The name of the track defined in the wig file. The default is to use 
the name of the chosen score column, or, if the input file is a GFF file, 
the base name of the input file. 

=item --(no)track

Do (not) include the track line at the beginning of the wig file. Wig 
files normally require a track line, but if you will be converting to 
the binary bigwig format, the converter requires no track line. Why it 
can't simply ignore the line is beyond me. This option is automatically 
set to false when the --bigwig option is enabled.

=item --(no)midpoint

A boolean value to indicate whether the 
midpoint between the actual 'start' and 'stop' values
should be used. The default is to use only the 'start' position. 

=item --format [0,1,2,3]

Indicate the number of decimal places the score value should
be formatted. Acceptable values include 0, 1, 2, or 3 places.
The default is to not format the score value.

=item --bigwig

Indicate that a binary BigWig file should be generated instead of 
a text wiggle file. A .wig file is first generated, then converted to 
a .bw file, and then the .wig file is removed.

=item --db <database>

Specify the database from which chromosome lengths can be derived when 
generating a bigwig file. This option is only required when generating 
bigwig files. It may be supplied from the metadata in the source data 
file.

=item --(no)gz

A boolean value to indicate whether the output wiggle 
file should be compressed with gzip.

=item --help

Display the POD documentation

=back

=head1 DESCRIPTION

This program will convert a data file into a wig formatted text
file. This presumes that the data file contains the chromosomal coordinates, 
i.e. chromosome, start, and (optionally) stop. If they are not found, the 
conversion will fail. The relevant columns should 
therefore be labeled 'chromosome', 'start', and 'stop' or 'end'. 

The wig file format is specified by documentation supporting the UCSC 
Genome Browser and detailed at this location:
http://genome.ucsc.edu/goldenPath/help/wiggle.html
Two formats are supported, 'fixedStep' and 'variableStep'. 

Alternatively, a binary BigWig file may be generated as opposed to a 
text wiggle file. The binary format is preferential to the text version 
for a variety of reasons, including fast, random access and no loss in 
data value precision. More information can be found at this location:
http://genome.ucsc.edu/goldenPath/help/bigWig.html


=head1 AUTHOR

 Timothy J. Parnell, PhD
 Howard Hughes Medical Institute
 Dept of Oncological Sciences
 Huntsman Cancer Institute
 University of Utah
 Salt Lake City, UT, 84112











