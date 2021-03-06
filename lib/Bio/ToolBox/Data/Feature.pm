package Bio::ToolBox::Data::Feature;
our $VERSION = '1.54';

=head1 NAME

Bio::ToolBox::Data::Feature - Objects representing rows in a data table

=head1 DESCRIPTION

A Bio::ToolBox::Data::Feature is an object representing a row in the 
data table. Usually, this in turn represents an annotated feature or 
segment in the genome. As such, this object provides convenient 
methods for accessing and manipulating the values in a row, as well as 
methods for working with the represented genomic feature.

This class should NOT be used directly by the user. Rather, Feature 
objects are generated from a Bio::ToolBox::Data::Iterator object 
(generated itself from the L<row_stream|Bio::ToolBox::Data/row_stream> 
function in Bio::ToolBox::Data), or the L<iterate|Bio::ToolBox::Data/iterate> 
function in Bio::ToolBox::Data. Please see the respective documentation 
for more information.

Example of working with a stream object.

	  my $Data = Bio::ToolBox::Data->new(file => $file);
	  
	  # stream method
	  my $stream = $Data->row_stream;
	  while (my $row = $stream->next_row) {
		 # each $row is a Bio::ToolBox::Data::Feature object
		 # representing the row in the data table
		 my $value = $row->value($index);
		 # do something with $value
	  }
	  
	  # iterate method
	  $Data->iterate( sub {
	     my $row = shift;
	     my $number = $row->value($index);
	     my $log_number = log($number);
	     $row->value($index, $log_number);
	  } );


=head1 METHODS

=head2 General information methods

=over 4

=item row_index

Returns the index position of the current data row within the 
data table. Useful for knowing where you are at within the data 
table.

=item feature_type

Returns one of three specific values describing the contents 
of the data table inferred by the presence of specific column 
names. This provides a clue as to whether the table features 
represent genomic regions (defined by coordinate positions) or 
named database features. The return values include:

=over 4

=item * coordinate: Table includes at least chromosome and start

=item * named: Table includes name, type, and/or Primary_ID

=item * unknown: unrecognized

=back

=item column_name

Returns the column name for the given index. 

item data

Returns the parent L<Bio::ToolBox::Data> object, in case you may 
have lost it by going out of scope.

=back

=head2 Methods to access row feature attributes

These methods return the corresponding value, if present in the 
data table, based on the column header name. If the row represents 
a named database object, try calling the L</feature> method first. 
This will retrieve the database SeqFeature object, and the attributes 
can then be retrieved using the methods below or on the actual 
database SeqFeature object.

These methods do not set attribute values. If you need to change the 
values in a table, use the L</value> method below.

=over 4

=item seq_id

The name of the chromosome the feature is on.

=item start

=item end

=item stop

The coordinates of the feature or segment. Coordinates from known 
0-based file formats, e.g. BED, are returned as 1-based. Coordinates 
must be integers to be returned. Zero or negative start coordinates 
are assumed to be accidents or poor programming and transformed to 1. 
Use the L</value> method if you don't want this to happen.

=item strand

The strand of the feature or segment. Returns -1, 0, or 1. Default is 0, 
or unstranded.

=item name

=item display_name

The name of the feature.

=item coordinate

Returns a coordinate string formatted as "seqid:start-stop".

=item type

The type of feature. Typically either primary_tag or primary_tag:source_tag. 
In a GFF3 file, this represents columns 3 and 2, respectively. In annotation 
databases such as L<Bio::DB::SeqFeature::Store>, the type is used to restrict 
to one of many different types of features, e.g. gene, mRNA, or exon.

=item id

=item primary_id

Here, this represents the primary_ID in the database. Note that this number 
is generally unique to a specific database, and not portable between databases.

=item length

The length of the feature or segment.

=item score

Returns the value of the Score column, if one is available. Typically 
associated with defined file formats, such as GFF files (6th column), 
BED and related Peak files (5th column), and bedGraph (4th column).

=back

=head2 Accessing and setting values in the row.

=over 4

=item value

  # retrieve a value 
  my $v = $row->value($index);
  # set a value
  $row->value($index, $v + 1);

Returns or sets the value at a specific column index in the 
current data row. Null values return a '.', symbolizing an 
internal null value. 

=item row_values

Returns an array or array reference representing all the values 
in the current data row. 

=back

=head2 Special feature attributes

GFF and VCF files have special attributes in the form of key = value pairs. 
These are stored as specially formatted, character-delimited lists in 
certain columns. These methods will parse this information and return as 
a convenient hash reference. The keys and values of this hash may be 
changed, deleted, or added to as desired. To write the changes back to 
the file, use the rewrite_attributes() to properly write the attributes 
back to the file with the proper formatting.

=over 4

=item attributes

Generic method that calls either gff_attributes() or vcf_attributes() 
depending on the data table format. 

=item gff_attributes

Parses the 9th column of GFF files. URL-escaped characters are converted 
back to text. Returns a hash reference of key =E<gt> value pairs. 

=item vcf_attributes

Parses the INFO (8th column) and all sample columns (10th and higher 
columns) in a version 4 VCF file. The Sample columns use the FORMAT 
column (9th column) as keys. The returned hash reference has two levels:
The first level keys are both the column names and index (0-based). The 
second level keys are the individual attribute keys to each value. 
For example:

   my $attr = $row->vcf_attributes;
   # access by column name
   my $genotype = $attr->{sample1}{GT};
   my $depth = $attr->{INFO}{ADP};
   # access by 0-based column index 
   my $genotype = $attr->{9}{GT};
   my $depth = $attr->{7}{ADP}

=item rewrite_attributes

Generic method that either calls L</rewrite_gff_attributes> or 
L</rewrite_vcf_attributes> depending on the data table format.

=item rewrite_gff_attributes

Rewrites the GFF attributes column (the 9th column) based on the 
contents of the attributes hash that was previously generated with 
the L</gff_attributes> method. Useful when you have modified the 
contents of the attributes hash.

=item rewrite_vcf_attributes

Rewrite the VCF attributes for the INFO (8th column), FORMAT (9th 
column), and sample columns (10th and higher columns) based on the 
contents of the attributes hash that was previously generated with 
the L</vcf_attributes> method. Useful when you have modified the 
contents of the attributes hash.

=back

=head2 Convenience Methods to database functions

The next three functions are convenience methods for using the 
attributes in the current data row to interact with databases. 
They are wrappers to methods in the L<Bio::ToolBox::db_helper> 
module.

=over 4

=item seqfeature

=item feature

Returns a SeqFeature object representing the feature or item in 
the current row. If the SeqFeature object is stored in the parent 
$Data object, it is retrieved from there. Otherwise, the SeqFeature 
object is retrieved from the database using the name and 
type values in the current Data table row. The SeqFeature object 
is requested from the database named in the general metadata. If 
an alternate database is desired, you should change it first using  
the $Data-E<gt>database() method. If the feature name or type is not 
present in the table, then nothing is returned.

See L<Bio::ToolBox::SeqFeature> and L<Bio::SeqFeatureI> for more 
information about working with these objects.

This method normally only works with "named" feature_types in a 
L<Bio::ToolBox::Data> Data table. If your Data table has coordinate 
information, i.e. chromosome, start, and stop columns, then it will 
likely be recognized as a "coordinate" feature_type and not work.

Pass a true value to this method to force the seqfeature lookup. This 
will still require the presence of Name, ID, and/or Type columns to 
perform the database lookup. The L<Bio::ToolBox::Data> method feature() 
is used to determine the type if a Type column is not present.

=item segment

Returns a database Segment object corresponding to the coordinates 
defined in the Data table row. If a named feature and type are 
present instead of coordinates, then the feature is first automatically 
retrieved and a Segment returned based on its coordinates. The 
database named in the general metadata is used to establish the 
Segment object. If a different database is desired, it should be 
changed first using the general database() method. 

See L<Bio::DB::SeqFeature::Segment> and L<Bio::RangeI> for more information 
about working with Segment objects.

=item get_features

  my @overlap_features = $row->get_features(type => $type);

Returns seqfeature objects from a database that overlap the Feature 
or interval in the current Data table row. This is essentially a 
convenience wrapper for a Bio::DB style I<features> method using the 
coordinates of the Feature. Optionally pass an array of key value pairs 
to specify alternate coordinates if so desired. Potential keys 
include 

=over 4

=item seq_id

=item start

=item end

=item type

The type of database features to retrieve.

=item db

An alternate database object to collect from.

=back

=item get_sequence

Fetches genomic sequence based on the coordinates of the current seqfeature 
or interval in the current Feature. This requires a database that 
contains the genomic sequence, either the database specified in the 
Data table metadata or an external indexed genomic fasta file. The 
sequence is returned as simple string. If the feature is on the reverse 
strand, then the reverse complement sequence is automatically returned. 
Pass an array of key value pairs to specify alternate coordinates if so 
desired. Potential keys include

=over 4

=item seq_id

=item start

=item end

=item strand

=item extend

Indicate additional basepairs of sequence added to both sides

=item db

The fasta file or database from which to fetch the sequence

=back

=back

=head2 Data collection

The following methods allow for data collection from various 
sources, including bam, bigwig, bigbed, useq, Bio::DB databases, etc. 

=over 4

=item get_score

  my $score = $row->get_score(
       dataset => 'scores.bw',
       method  => 'max',
  );

This method collects a single score over the feature or interval. 
Usually a mathematical or statistical value is employed to derive the 
single score. Pass an array of key value pairs to control data collection.
Keys include the following:

=over 4

=item db

=item ddb

Specify a Bio::DB database from which to collect the data. The default 
value is the database specified in the Data table metadata, if present.
Examples include a L<Bio::DB::SeqFeature::Store> or L<Bio::DB::BigWigSet> 
database.

=item dataset 

Specify the name of the dataset. If a database was specified, then this 
value would be the I<primary_tag> or I<type:source> feature found in the 
database. Otherwise, the name of a data file, such as a bam, bigWig, 
bigBed, or USeq file, would be provided here. This options is required!

=item method

Specify the mathematical or statistical method combining multiple scores 
over the interval into one value. Options include the following:

=over 4

=item * mean

=item * sum

=item * min

=item * max

=item * median

=item * count

Count all overlapping items.

=item * pcount

Precisely count only containing (not overlapping) items.

=item * ncount

Count overlapping unique names only.

=item * range

The difference between minimum and maximum values.

=item * stddev

Standard deviation.

=back

=item strandedness 

Specify what strand from which the data should be taken, with respect 
to the Feature strand. Three options are available. Only really relevant 
for data sources that support strand. 

=over 4

=item * sense

The same strand as the Feature.

=item * antisense

The opposite strand as the Feature.

=item * all

Strand is ignored, all is taken (default).

=back

=item subfeature

Specify the subfeature type from which to collect the scores. Typically 
a SeqFeature object representing a transcript is provided, and the 
indicated subfeatures are collected from object. Pass the name of the 
subfeature to use. Accepted values include the following.

=over 4 

=item * exon

All exons included

=item * cds

The CDS or coding sequence are extracted from mRNA

=item * 5p_utr

The 5' UTR of mRNA

=item * 3p_utr

The 3' UTR of mRNA

=back

=item extend

Specify the number of basepairs that the Data table Feature's 
coordinates should be extended in both directions. Ignored 
when used with the subfeature option.

=item seq_id

=item chromo

=item start

=item end

=item stop

=item strand

Optionally specify zero or more alternate coordinates to use. 
By default, these are obtained from the Data table Feature.

=back
  
=item get_relative_point_position_scores

  while (my $row = $stream->next_row) {
     my $pos2score = $row->get_relative_point_position_scores(
        'ddb'       => '/path/to/BigWigSet/',
        'dataset'   => 'MyData',
        'position'  => 5,
        'extend'    => 1000,
     );
  }

This method collects indexed position scores centered around a 
specific reference point. The returned data is a hash of 
relative positions (example -20, -10, 1, 10, 20) and their score 
values. Pass an array of key value pairs to control data collection.
Keys include the following:

=over 4

=item db

=item ddb

Specify a Bio::DB database from which to collect the data. The default 
value is the database specified in the Data table metadata, if present.
Examples include a L<Bio::DB::SeqFeature::Store> or L<Bio::DB::BigWigSet> 
database.

=item dataset 

Specify the name of the dataset. If a database was specified, then this 
value would be the I<primary_tag> or I<type:source> feature found in the 
database. Otherwise, the name of a data file, such as a bam, bigWig, 
bigBed, or USeq file, would be provided here. This options is required!

=item position

Indicate the position of the reference point relative to the Data table 
Feature. 5 is the 5C<'> coordinate, 3 is the 3C<'> coordinate, and 4 is the 
midpoint (get it? it's between 5 and 3). Default is 5.

=item extend

Indicate the number of base pairs to extend from the reference coordinate. 
This option is required!

=item coordinate

Optionally provide the real chromosomal coordinate as the reference point.

=item absolute 

Boolean option to indicate that the returned hash of positions and scores 
should not be transformed into relative positions but kept as absolute 
chromosomal coordinates.

=item avoid

Provide a I<primary_tag:source> database feature type to avoid overlapping 
scores. Each found score is checked for overlapping features and is 
discarded if found to do so. The database should be set to use this.

=item strandedness 

Specify what strand from which the data should be taken, with respect 
to the Feature strand. Three options are available. Only really relevant 
for data sources that support strand. 

=over 4

=item * sense

The same strand as the Feature.

=item * antisense

The opposite strand as the Feature.

=item * all

Strand is ignored, all is taken (default).

=back

=item method

Only required when counting objects.

=over 4

=item * count

Count all overlapping items.

=item * pcount

Precisely count only containing (not overlapping) items.

=item * ncount

Count overlapping unique names only.

=back

=back

=item get_region_position_scores

  while (my $row = $stream->next_row) {
     my $pos2score = $row->get_relative_point_position_scores(
        'ddb'       => '/path/to/BigWigSet/',
        'dataset'   => 'MyData',
        'position'  => 5,
        'extend'    => 1000,
     );
  }

This method collects indexed position scores across a defined 
region or interval. The returned data is a hash of positions and 
their score values. The positions are by default relative to a 
region coordinate, usually to the 5' end. Pass an array of key value 
pairs to control data collection. Keys include the following:

=over 4

=item db

=item ddb

Specify a Bio::DB database from which to collect the data. The default 
value is the database specified in the Data table metadata, if present.
Examples include a L<Bio::DB::SeqFeature::Store> or L<Bio::DB::BigWigSet> 
database.

=item dataset 

Specify the name of the dataset. If a database was specified, then this 
value would be the I<primary_tag> or I<type:source> feature found in the 
database. Otherwise, the name of a data file, such as a bam, bigWig, 
bigBed, or USeq file, would be provided here. This options is required!

=item subfeature

Specify the subfeature type from which to collect the scores. Typically 
a SeqFeature object representing a transcript is provided, and the 
indicated subfeatures are collected from object. When converting to 
relative coordinates, the coordinates will be relative to the length of 
the sum of the subfeatures, i.e. the length of the introns will be ignored.

Pass the name of the subfeature to use. Accepted values include the following.

=over 4 

=item * exon

All exons included

=item * cds

The CDS or coding sequence are extracted from mRNA

=item * 5p_utr

The 5' UTR of mRNA

=item * 3p_utr

The 3' UTR of mRNA

=back

=item extend

Specify the number of basepairs that the Data table Feature's 
coordinates should be extended in both directions. 

=item seq_id

=item chromo

=item start

=item end

=item stop

=item strand

Optionally specify zero or more alternate coordinates to use. 
By default, these are obtained from the Data table Feature.

=item position

Indicate the position of the reference point relative to the Data table 
Feature. 5 is the 5' coordinate, 3 is the 3' coordinate, and 4 is the 
midpoint (get it? it's between 5 and 3). Default is 5.

=item coordinate

Optionally provide the real chromosomal coordinate as the reference point.

=item absolute 

Boolean option to indicate that the returned hash of positions and scores 
should not be transformed into relative positions but kept as absolute 
chromosomal coordinates.

=item avoid

Provide a I<primary_tag:source> database feature type to avoid overlapping 
scores. Each found score is checked for overlapping features and is 
discarded if found to do so. The database should be set to use this.

=item strandedness 

Specify what strand from which the data should be taken, with respect 
to the Feature strand. Three options are available. Only really relevant 
for data sources that support strand. 

=over 4

=item * sense

The same strand as the Feature.

=item * antisense

The opposite strand as the Feature.

=item * all

Strand is ignored, all is taken (default).

=back

=item method

Only required when counting objects.

=over 4

=item * count

Count all overlapping items.

=item * pcount

Precisely count only containing (not overlapping) items.

=item * ncount

Count overlapping unique names only.

=back

=back

=back

=head2 Feature Export

These methods allow the feature to be exported in industry standard 
formats, including the BED format and the GFF format. Both methods 
return a formatted tab-delimited text string suitable for printing to 
file. The string does not include a line ending character.

These methods rely on coordinates being present in the source table. 
If the row feature represents a database item, the L</feature> method 
should be called prior to these methods, allowing the feature to be 
retrieved from the database and coordinates obtained.

=over 4

=item bed_string

Returns a BED formatted string. By default, a 6-element string is 
generated, unless otherwise specified. Pass an array of key values 
to control how the string is generated. The following arguments 
are supported.

=over 4

=item bed

Specify the number of BED elements to include. The number of elements 
correspond to the number of columns in the BED file specification. A 
minimum of 3 (chromosome, start, stop) is required, and maximum of 6 
is allowed (chromosome, start, stop, name, score, strand). 

=item chromo

=item seq_id

Provide a text string of an alternative chromosome or sequence name.

=item start

=item stop

=item end

Provide alternative integers for the start and stop coordinates. 
Note that start values are automatically converted to 0-base 
by subtracting 1.

=item strand

Provide alternate an alternative strand value. 

=item name

Provide an alternate or missing name value to be used as text in the 4th 
column. If no name is provided or available, a default name is generated.

=item score

Provide a numerical value to be included as the score. BED files typically 
use integer values ranging from 1..1000. 

=back

=item gff_string

Returns a GFF3 formatted string. Pass an array of key values 
to control how the string is generated. The following arguments 
are supported.

=over 4

=item chromo

=item seq_id

=item start

=item stop

=item end

=item strand

Provide alternate values from those defined or missing in the current 
row Feature. 

=item source

Provide a text string to be used as the source_tag value in the 2nd 
column. The default value is null ".".

=item primary_tag

Provide a text string to be used as the primary_tag value in the 3rd 
column. The default value is null ".".

=item type

Provide a text string. This can be either a "primary_tag:source_tag" value 
as used by GFF based BioPerl databases, or "primary_tag" alone.

=item score

Provide a numerical value to be included as the score. The default 
value is null ".". 

=item name

Provide alternate or missing name value to be used as the display_name. 
If no name is provided or available, a default name is generated.

=item attributes

Provide an anonymous array reference of one or more row Feature indices 
to be used as GFF attributes. The name of the column is used as the GFF 
attribute key. 

=back

=back

=cut

use strict;
use Carp qw(carp cluck croak confess);
use Module::Load;
use Bio::ToolBox::db_helper qw(
	get_db_feature 
	get_segment_score
	calculate_score
	get_genomic_sequence
);

my $GENETOOL_LOADED = 0;
1;



### Initialization

sub new {
	# this should ONLY be called from Bio::ToolBox::Data* iterators
	my $class = shift;
	my %self = @_;
	# we trust that new is called properly with data and index values
	return bless \%self, $class;
}


### Set and retrieve values

sub data {
	return shift->{data};
}

sub column_name {
	my ($self, $column) = @_;
	return unless defined $column;
	return $self->{data}->name($column);
}

sub feature_type {
	my $self = shift;
	carp "feature_type is a read only method" if @_;
	return $self->{data}->feature_type;
}

sub row_index {
	my $self = shift;
	carp "row_index is a read only method" if @_;
	return $self->{'index'};
}

sub line_number {
	my $self = shift;
	carp "line_number is a read only method" if @_;
	if (exists $self->{data}->{line_count}) {
		return $self->{data}->{line_count};
	}
	elsif (exists $self->{data}->{header_line_count}) {
		return $self->{data}->{header_line_count} + $self->row_index;
	}
	else {
		return;
	}
}

sub row_values {
	my $self  = shift;
	carp "row_values is a read only method" if @_;
	my $row = $self->{'index'};
	my @data = @{ $self->{data}->{data_table}->[$row] };
	return wantarray ? @data : \@data;
}

sub value {
	my ($self, $column, $value) = @_;
	return unless defined $column;
	my $row = $self->{'index'};
	
	if (defined $value) {
		# set a value
		$self->{data}->{data_table}->[$row][$column] = $value;
	}
	my $v = $self->{data}->{data_table}->[$row][$column];
	return defined $v ? $v : '.'; # internal null value
}

sub seq_id {
	my $self = shift;
	carp "seq_id is a read only method" if @_;
	my $i = $self->{data}->chromo_column;
	my $v = $self->value($i) if defined $i;
	if (defined $v and $v ne '.') {
		return $v;
	}
	return $self->{feature}->seq_id if exists $self->{feature};
	return undef;
}

sub start {
	my $self = shift;
	carp "start is a read only method" if @_;
	my $i = $self->{data}->start_column;
	if (defined $i) {
		my $v = $self->value($i);
		$v++ if (substr($self->{data}->name($i), -1) eq '0'); # compensate for 0-based
		return $v < 1 ? 1 : $v;
	}
	elsif (exists $self->{feature}) {
		return $self->{feature}->start;
	}
	else {
		return;
	}
}

*stop = \&end;
sub end {
	my $self = shift;
	carp "end is a read only method" if @_;
	my $i = $self->{data}->stop_column;
	if (defined $i) {
		return $self->value($i);
	}
	elsif (exists $self->{feature}) {
		return $self->{feature}->end;
	}
	else {
		return;
	}
}

sub strand {
	my $self = shift;
	carp "strand is a read only method" if @_;
	my $i = $self->{data}->strand_column;
	if (defined $i) {
		my $str = $self->value($i);
		if (defined $str and $str !~ /^\-?[01]$/) {
			$str = $str eq '+' ? 1 : $str eq '-' ? -1 : 0;
		}
		$str ||= 0;
		return $str;
	}
	elsif (exists $self->{feature}) {
		return $self->{feature}->strand;
	}
	return 0;
}

*name = \&display_name;
sub display_name {
	my $self = shift;
	carp "name is a read only method" if @_;
	my $i = $self->{data}->name_column;
	my $v = $self->value($i) if defined $i;
	if (defined $v and $v ne '.') {
		return $v;
	}
	return $self->{feature}->display_name if exists $self->{feature};
	if (my $att = $self->gff_attributes) {
		return $att->{Name} || $att->{ID} || $att->{transcript_name};
	}
	return undef;
}

sub coordinate {
	my $self = shift;
	carp "name is a read only method" if @_;
	my $coord = sprintf("%s:%d", $self->seq_id, $self->start);
	my $end = $self->end;
	$coord .= "-$end" if $end;
	return CORE::length($coord) > 2 ? $coord : undef;
}

sub type {
	my $self = shift;
	carp "type is a read only method" if @_;
	my $i = $self->{data}->type_column;
	my $v = $self->value($i) if defined $i;
	if (defined $v and $v ne '.') {
		return $v;
	}
	return $self->{feature}->primary_tag if exists $self->{feature};
	return $self->{data}->feature if $self->{data}->feature; # general metadata feature type
	return undef;
}

*id = \&primary_id;
sub primary_id {
	my $self = shift;
	carp "id is a read only method" if @_;
	my $i = $self->{data}->id_column;
	my $v = $self->value($i) if defined $i;
	if (defined $v and $v ne '.') {
		return $v;
	}
	return $self->{feature}->primary_id if exists $self->{feature};
	if (my $att = $self->gff_attributes) {
		return $att->{ID} || $att->{Name} || $att->{transcript_id};
	}
	return undef;
}

sub length {
	my $self = shift;
	carp "length is a read only method" if @_;
	if ($self->{data}->vcf) {
		# special case for vcf files, measure the length of the ALT allele
		return CORE::length($self->value(4)); 
	}
	my $s = $self->start;
	my $e = $self->end;
	if (defined $s and defined $e) {
		return $e - $s + 1;
	}
	elsif (defined $s) {
		return 1;
	}
	else {
		return undef;
	}
}

sub score {
	my $self = shift;
	my $c = $self->{data}->score_column;
	return defined $c ? $self->value($c) : undef;
}

sub attributes {
	my $self = shift;
	return $self->gff_attributes if ($self->{data}->gff);
	return $self->vcf_attributes if ($self->{data}->vcf);
	return;
}

sub gff_attributes {
	my $self = shift;
	return unless ($self->{data}->gff);
	return $self->{attributes} if (exists $self->{attributes});
	$self->{attributes} = {};
	foreach my $g (split(/\s*;\s*/, $self->value(8))) {
		my ($tag, $value) = split /\s+/, $g;
		next unless ($tag and $value);
		# unescape URL encoded values, borrowed from Bio::DB::GFF
		$value =~ tr/+/ /;
		$value =~ s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
		$self->{attributes}->{$tag} = $value;
	}
	return $self->{attributes};
}

sub vcf_attributes {
	my $self = shift;
	return unless ($self->{data}->vcf);
	return $self->{attributes} if (exists $self->{attributes});
	$self->{attributes} = {};
	
	# INFO attributes
	my %info;
	if ($self->{data}->name(7) eq 'INFO') {
		%info = 	map {$_->[0] => defined $_->[1] ? $_->[1] : undef} 
						# some tags are simple and have no value, eg SOMATIC 
					map { [split(/=/, $_)] } 
					split(/;/, $self->value(7));
	}
	$self->{attributes}->{INFO} = \%info;
	$self->{attributes}->{7}    = \%info;
	
	# Sample attributes
	if ($self->{data}->number_columns > 8) {
		my @formatKeys = split /:/, $self->value(8);
		foreach my $i (9 .. $self->{data}->last_column) {
			my $name = $self->{data}->name($i);
			my @sampleVals = split /:/, $self->value($i);
			my %sample = map { 
				$formatKeys[$_] => defined $sampleVals[$_] ? $sampleVals[$_] : undef } 
				(0 .. $#formatKeys);
			$self->{attributes}->{$name} = \%sample;
			$self->{attributes}->{$i}    = \%sample;
		}
	}
	return $self->{attributes};
}

sub rewrite_attributes {
	my $self = shift;
	return $self->rewrite_gff_attributes if ($self->{data}->gff);
	return $self->rewrite_vcf_attributes if ($self->{data}->vcf);
	return;
}

sub rewrite_gff_attributes {
	my $self = shift;
	return unless ($self->{data}->gff);
	return unless exists $self->{attributes};
	my @pairs; # of key=value items
	if (exists $self->{attributes}{ID}) {
		# I assume this does not need to be escaped!
		push @pairs, 'ID=' . $self->{attributes}{ID};
	}
	if (exists $self->{attributes}{Name}) {
		my $name = $self->{attributes}{Name};
		$name =~ s/([\t\n\r%&\=;, ])/sprintf("%%%X",ord($1))/ge;
		push @pairs, "Name=$name";
	}
	foreach my $key (sort {$a cmp $b} keys %{ $self->{attributes} }) {
		next if $key eq 'ID';
		next if $key eq 'Name';
		my $value = $self->{attributes}{$key};
		$key =~ s/([\t\n\r%&\=;, ])/sprintf("%%%X",ord($1))/ge;
		$value =~ s/([\t\n\r%&\=;, ])/sprintf("%%%X",ord($1))/ge;
		push @pairs, "$key=$value";
	}
	$self->value(8, join("; ", @pairs));
	return 1;
}

sub rewrite_vcf_attributes {
	my $self = shift;
	return unless ($self->{data}->vcf);
	return unless exists $self->{attributes};
	
	# INFO
	my $info = join(';', 
		map { 
			defined $self->{attributes}->{INFO}{$_} ? 
			join('=', $_, $self->{attributes}->{INFO}{$_}) : $_
		} 
		sort {$a cmp $b} 
		keys %{$self->{attributes}->{INFO}}
	);
	$info ||= '.'; # sometimes we have nothing left
	$self->value(7, $info);
	
	# FORMAT
	my @order;
	push @order, 'GT' if exists $self->{attributes}{9}{GT};
	foreach my $key (sort {$a cmp $b} keys %{ $self->{attributes}{9} } ) {
		next if $key eq 'GT';
		push @order, $key;
	}
	if (@order) {
		$self->value(8, join(':', @order));
	}
	else {
		$self->value(8, '.');
	}
	
	# SAMPLES
	foreach my $i (9 .. $self->{data}->last_column) {
		if (@order) {
			$self->value($i, join(":", 
				map { $self->{attributes}{$i}{$_} } @order 
			) );
		}
		else {
			$self->value($i, '.');
		}
	}
	return 1;
}

### Data collection convenience methods

*feature = \&seqfeature;
sub seqfeature {
	my $self = shift;
	my $force = shift || 0;
	carp "feature is a read only method" if @_;
	return $self->{feature} if exists $self->{feature};
	# normally this is only for named features in a data table
	# skip this for coordinate features like bed files
	return unless $self->feature_type eq 'named' or $force;
	
	# retrieve from main Data store
	my $f = $self->{data}->get_seqfeature( $self->{'index'} );
	if ($f) {
		$self->{feature} = $f;
		return $f;
	}
	
	# retrieve the feature from the database
	return unless $self->{data}->database;
	$f = get_db_feature(
		'db'    => $self->{data}->open_meta_database,
		'id'    => $self->id || undef,
		'name'  => $self->name || undef, 
		'type'  => $self->type || $self->{data}->feature,
	);
	return unless $f;
	$self->{feature} = $f;
	return $f;
}

sub segment {
	my $self   = shift;
	carp "segment is a read only method" if @_;
	return unless $self->{data}->database;
	if ($self->feature_type eq 'coordinate') {
		my $chromo = $self->seq_id;
		my $start  = $self->start;
		my $stop   = $self->end || $start;
		my $db = $self->{data}->open_meta_database;
		return $db ? $db->segment($chromo, $start, $stop) : undef;
	}
	elsif ($self->feature_type eq 'named') {
		my $f = $self->feature;
		return $f ? $f->segment : undef;
	}
	else {
		return undef;
	}
}

sub get_features {
	my $self = shift;
	my %args = @_;
	my $db = $args{db} || $self->{data}->open_meta_database || undef;
	carp "no database defined to get features!" unless defined $db;
	return unless $db->can('features');
	
	# convert the argument style for most bioperl db APIs
	my %opts;
	$opts{-seq_id} = $args{chromo} || $self->seq_id;
	$opts{-start}  = $args{start}  || $self->start;
	$opts{-end}    = $args{end}    || $self->end;
	$opts{-type}   = $args{type}   || $self->type;
	
	return $db->features(%opts);
}

sub get_sequence {
	my $self = shift;
	my %args = @_;
	my $db = $args{db} || $args{database} || $self->{data}->open_meta_database || undef;
	my $seqid = $args{seq_id} || $args{chromo} || $self->seq_id;
	my $start = $args{start} || $self->start;
	my $stop  = $args{stop} || $args{end} || $self->end;
	my $strand = $self->strand;
	if (exists $args{strand}) {
		# user supplied strand, gotta check it
		$strand = $args{strand} =~ /\-|r/i ? -1 : 1;
	}
	if (exists $args{extend} and $args{extend}) {
		$start -= $args{extend};
		$start = 1 if $start <= 0;
		$stop += $args{extend};
	}
	return unless (defined $seqid and defined $start and defined $stop);
	my $seq = get_genomic_sequence($db, $seqid, $start, $stop);
	if ($strand == -1) {
		$seq =~ tr/gatcGATC/ctagCTAG/;
		$seq = reverse $seq;
	}
	return $seq;
}

sub get_score {
	my $self = shift;
	my %args = @_;
	
	# verify the dataset for the user, cannot trust whether it has been done or not
	my $db = $args{ddb} || $args{db} || $self->{data}->open_meta_database || undef;
	$args{dataset} = $self->{data}->verify_dataset($args{dataset}, $db);
	unless ($args{dataset}) {
		croak "provided dataset was unrecognized format or otherwise could not be verified!";
	}
	
	# score attributes
	$args{'method'}     ||= 'mean';
	$args{strandedness} ||= $args{stranded} || 'all';
	
	# get positioned scores over subfeatures only
	$args{subfeature} ||= $args{exon} || q();
	if ($self->feature_type eq 'named' and $args{subfeature}) {
		# this is more complicated so we have a dedicated method
		return $self->_get_subfeature_scores($db, \%args);
	}
	
	# verify coordinates based on type of feature
	if ($self->feature_type eq 'coordinate') {
		# coordinates are already in the table, use those
		$args{chromo} ||= $args{seq_id} || $self->seq_id;
		$args{start}  ||= $self->start;
		$args{stop}   ||= $args{end} || $self->end;
	}
	elsif ($self->feature_type eq 'named') {
		# must retrieve feature from the database first
		my $f = $self->seqfeature;
		return unless $f;
		$args{chromo} ||= $args{seq_id} || $f->seq_id;
		$args{start}  ||= $f->start;
		$args{stop}   ||= $args{end} || $f->end;
	}
	else {
		croak "data table does not have identifiable coordinate or feature identification columns for score collection";
	}
	
	# adjust coordinates as necessary
	if (exists $args{extend} and $args{extend}) {
		$args{start} -= $args{extend};
		$args{stop}  += $args{extend};
	}
	
	# check coordinates
	$args{start} = 1 if $args{start} <= 0;
	if ($args{stop} < $args{start}) {
		# coordinates are flipped, reverse strand
		return if ($args{stop} <= 0);
		my $stop = $args{start};
		$args{start} = $args{stop};
		$args{stop}  = $stop;
		$args{strand} = -1;
	}
	unless (exists $args{strand} and defined $args{strand}) {
		$args{strand} = $self->strand; 
	}
	return unless ($args{chromo} and defined $args{start});
	
	# get the score
	return get_segment_score(
		$args{chromo},
		$args{start},
		$args{stop},
		$args{strand},
		$args{strandedness},
		$args{'method'},
		0, # return type should be a calculated value
		$db,
		$args{dataset},
	);
}

sub _get_subfeature_scores {
	my ($self, $db, $args) = @_;
	
	# load GeneTools
	unless ($GENETOOL_LOADED) {
		load('Bio::ToolBox::GeneTools', qw(get_exons get_cds get_5p_utrs get_3p_utrs));
		if ($@) {
			croak "missing required modules! $@";
		}
		else {
			$GENETOOL_LOADED = 1;
		}
	}
	
	# feature
	my $feature = $self->seqfeature;
	unless ($feature) {
		carp "no SeqFeature available! Cannot collect exon data!";
		return;
	}
	
	# get the subfeatures
	my @subfeatures;
	if ($args->{subfeature} eq 'exon') {
		@subfeatures = get_exons($feature);
	}
	elsif ($args->{subfeature} eq 'cds') {
		@subfeatures = get_cds($feature);
	}
	elsif ($args->{subfeature} eq '5p_utr') {
		@subfeatures = get_5p_utrs($feature);
	}
	elsif ($args->{subfeature} eq '3p_utr') {
		@subfeatures = get_3p_utrs($feature);
	}
	else {
		croak sprintf "unrecognized subfeature parameter '%s'!", $args->{subfeature};
	}
	# it's possible nothing is returned, which means no score will be calculated
	
	# collect over each subfeature
	my @scores;
	foreach my $exon (@subfeatures) {
		my $exon_scores = get_segment_score(
			$exon->seq_id,
			$exon->start,
			$exon->end,
			defined $args->{strand} ? $args->{strand} : $exon->strand, 
			$args->{strandedness}, 
			$args->{method},
			1, # return type should be an array reference of scores
			$db,
			$args->{dataset}, 
		);
		push @scores, @$exon_scores if defined $exon_scores;
	}
	
	# combine all the scores based on the requested method
	return calculate_score($args->{'method'}, \@scores);
}

sub get_relative_point_position_scores {
	my $self = shift;
	my %args = @_;
	
	# get the database and verify the dataset
	my $ddb = $args{ddb} || $args{db} || $self->{data}->open_meta_database;
	$args{dataset} = $self->{data}->verify_dataset($args{dataset}, $ddb);
	unless ($args{dataset}) {
		croak "provided dataset was unrecognized format or otherwise could not be verified!\n";
	}
	
	# assign some defaults
	$args{strandedness} ||= $args{stranded} || 'all';
	$args{position}     ||= 5;
	$args{coordinate}   ||= undef;
	$args{avoid}        ||= undef;
	$args{'method'}     ||= 'mean'; # in most cases this doesn't do anything
	unless ($args{extend}) {
		croak "must provide an extend value!";
	}
	$args{avoid} = undef unless ($args{db} or $self->{data}->open_meta_database);
	
	# Assign coordinates
	$self->_calculate_reference(\%args) unless defined $args{coordinate};
	my $fchromo = $self->seq_id;
	my $fstart = $args{coordinate} - $args{extend};
	my $fstop  = $args{coordinate} + $args{extend};
	my $fstrand = defined $args{strand} ? $args{strand} : $self->strand;
	
	# Data collection
	$fstart = 1 if $fstart < 1; # sanity check
	my $pos2data = get_segment_score(
		$fchromo,
		$fstart,
		$fstop,
		$fstrand, 
		$args{strandedness}, 
		$args{'method'},
		2, # return type should be a hash reference of positioned scores
		$ddb,
		$args{dataset}, 
	);
	
	# Avoid positions
	if ($args{avoid}) {
		$self->_avoid_positions($pos2data, \%args, $fchromo, $fstart, $fstop);
	}
	
	# covert to relative positions
	if ($args{absolute}) {
		# do not convert to relative positions
		return wantarray ? %$pos2data : $pos2data;
	}
	else {
		# return the collected dataset hash
		return $self->_convert_to_relative_positions($pos2data, 
			$args{coordinate}, $fstrand);
	}
}

sub get_region_position_scores {
	my $self = shift;
	my %args = @_;
	
	# get the database and verify the dataset
	my $ddb = $args{ddb} || $args{db} || $self->{data}->open_meta_database;
	$args{dataset} = $self->{data}->verify_dataset($args{dataset}, $ddb);
	unless ($args{dataset}) {
		croak "provided dataset was unrecognized format or otherwise could not be verified!\n";
	}
	
	# assign some defaults
	$args{strandedness} ||= $args{stranded} || 'all';
	$args{extend}       ||= 0;
	$args{exon}         ||= 0;
	$args{position}     ||= 5;
	$args{'method'}     ||= 'mean'; # in most cases this doesn't do anything
	$args{avoid} = undef unless ($args{db} or $self->{data}->open_meta_database);
	
	# get positioned scores over subfeatures only
	$args{subfeature} ||= $args{exon} || q();
	if ($self->feature_type eq 'named' and $args{subfeature}) {
		# this is more complicated so we have a dedicated method
		return $self->_get_subfeature_position_scores(\%args, $ddb);
	}
	
	# Assign coordinates
	my $feature = $self->seqfeature || $self;
	my $fchromo = $args{chromo} || $args{seq_id} || $feature->seq_id;
	my $fstart  = $args{start} || $feature->start;
	my $fstop   = $args{stop} || $args{end} || $feature->end;
	my $fstrand = defined $args{strand} ? $args{strand} : $feature->strand;
	if ($args{extend}) {
		$fstart -= $args{extend};
		$fstop  += $args{extend};
	}
	
	# Data collection
	$fstart = 1 if $fstart < 1; # sanity check
	my $pos2data = get_segment_score(
		$fchromo,
		$fstart,
		$fstop,
		$fstrand, 
		$args{strandedness}, 
		$args{'method'},
		2, # return type should be a hash reference of positioned scores
		$ddb,
		$args{dataset}, 
	);
	
	# Avoid positions
	if ($args{avoid}) {
		$self->_avoid_positions($pos2data, \%args, $fchromo, $fstart, $fstop);
	}
	
	# covert to relative positions
	if ($args{absolute}) {
		# do not convert to relative positions
		return wantarray ? %$pos2data : $pos2data;
	}
	else {
		# return data converted to relative positions
		$self->_calculate_reference(\%args) unless defined $args{coordinate};
		return $self->_convert_to_relative_positions($pos2data, 
			$args{coordinate}, $fstrand);
	}
}

sub _get_subfeature_position_scores {
	my ($self, $args, $ddb) = @_;
	
	# load GeneTools
	unless ($GENETOOL_LOADED) {
		load('Bio::ToolBox::GeneTools', qw(get_exons get_cds get_5p_utrs get_3p_utrs));
		if ($@) {
			croak "missing required modules! $@";
		}
		else {
			$GENETOOL_LOADED = 1;
		}
	}
	
	# feature
	my $feature = $self->seqfeature;
	unless ($feature) {
		carp "no SeqFeature available! Cannot collect exon data!";
		return;
	}
	my $fstrand = defined $args->{strand} ? $args->{strand} : $self->strand;
	
	# get the subfeatures
	my @subfeatures;
	my $subf = lc $args->{subfeature};
	if ($subf eq 'exon') {
		@subfeatures = get_exons($feature);
	}
	elsif ($subf eq 'cds') {
		@subfeatures = get_cds($feature);
	}
	elsif ($subf eq '5p_utr') {
		@subfeatures = get_5p_utrs($feature);
	}
	elsif ($subf eq '3p_utr') {
		@subfeatures = get_3p_utrs($feature);
	}
	else {
		croak "unrecognized subfeature parameter '$subf'!";
	}
	
	# it's possible no subfeatures are returned
	unless (@subfeatures) {
		return;
	}
	
	# reset the practical start and stop to the actual subfeatures' final start and stop
	# we can no longer rely on the feature start and stop, consider CDS
	# these subfeatures should already be genomic sorted by GeneTools
	my $practical_start = $subfeatures[0]->start;
	my $practical_stop  = $subfeatures[-1]->end;
	
	# collect over each exon
	# we will adjust the positions of each reported score so that 
	# it will appear as if all the exons are adjacent to each other
	# and no introns exist
	my $pos2data = {};
	my $namecheck = {}; # to check unique names when using ncount method....
	my $current_end = $practical_start;
	my $adjustment = 0;
	foreach my $exon (@subfeatures) {
		
		# exon positions
		my $start = $exon->start;
		my $end = $exon->end;
		
		# collect scores
		my $exon_scores = get_segment_score(
			$exon->seq_id,
			$start,
			$end,
			$fstrand, 
			$args->{strandedness}, 
			$args->{method},
			2, # return type should be a hash reference of positioned scores
			$ddb,
			$args->{dataset}, 
		);
		
		# adjust the scores
		$adjustment = $start - $current_end;
		$self->_process_exon_scores($exon_scores, $pos2data, $adjustment, $start, $end, 
			$namecheck, $args->{method});
		
		# reset
		$current_end += $exon->length;
	}
	
	# collect extensions if requested
	if ($args->{extend}) {
		# left side
		my $start = $practical_start - $args->{extend};
		my $end = $practical_start - 1;
		my $ext_scores = get_segment_score(
			$feature->seq_id,
			$start,
			$end,
			$fstrand, 
			$args->{strandedness}, 
			$args->{method},
			2, # return type should be a hash reference of positioned scores
			$ddb,
			$args->{dataset}, 
		);

		# no adjustment should be needed
		$self->_process_exon_scores($ext_scores, $pos2data, 0, $start, $end, 
			$namecheck, $args->{method});
		
		
		# right side
		$start = $practical_stop + 1;
		$end = $practical_stop + $args->{extend};
		$ext_scores = get_segment_score(
			$feature->seq_id,
			$start,
			$end,
			$fstrand, 
			$args->{strandedness}, 
			$args->{method},
			2, # return type should be a hash reference of positioned scores
			$ddb,
			$args->{dataset}, 
		);

		# the adjustment should be the same as the last exon
		$self->_process_exon_scores($ext_scores, $pos2data, $adjustment, $start, $end, 
			$namecheck, $args->{method});
	}
	
	# covert to relative positions
	if ($args->{absolute}) {
		# do not convert to relative positions
		return wantarray ? %$pos2data : $pos2data;
	}
	else {
		# return data converted to relative positions
		# can no longer use original coordinates, but instead the new shifted coordinates
		$args->{practical_start} = $practical_start;
		$args->{practical_stop} = $current_end; 
		$self->_calculate_reference($args);
		return $self->_convert_to_relative_positions($pos2data, 
			$args->{coordinate}, $fstrand);
	}
}

sub _calculate_reference {
	my ($self, $args) = @_;
	my $feature = $self->seqfeature || $self;
	my $strand = defined $args->{strand} ? $args->{strand} : $feature->strand;
	if ($args->{position} == 5 and $strand >= 0) {
		$args->{coordinate} = $args->{practical_start} || $feature->start;
	}
	elsif ($args->{position} == 3 and $strand >= 0) {
		$args->{coordinate} = $args->{practical_stop} || $feature->end;
	}
	elsif ($args->{position} == 5 and $strand < 0) {
		$args->{coordinate} = $args->{practical_stop} || $feature->end;
	}
	elsif ($args->{position} == 3 and $strand < 0) {
		$args->{coordinate} = $args->{practical_start} || $feature->start;
	}
	elsif ($args->{position} == 4) {
		# strand doesn't matter here
		my $s = $args->{practical_start} || $feature->start;
		$args->{coordinate} = $s + int(($feature->length / 2) + 0.5);
	}
	else {
		croak "position must be one of 5, 3, or 4";
	}
}

sub _avoid_positions {
	my ($self, $pos2data, $args, $seqid, $start, $stop) = @_;
	
	# first check the list of avoid types
	if (ref $args->{avoid} eq 'ARRAY') {
		# we have types, presume they're ok
	}
	elsif ($args->{avoid} eq '1') {
		# old style boolean value
		if (defined $args->{type}) {
			$args->{avoid} = [ $args->{type} ];
		}
		else {
			# no type provided, we can't avoid that which is not defined! 
			# this is an error, but won't complain as we never did before
			$args->{avoid} = $self->type;
		}
	}
	elsif ($args->{avoid} =~ /w+/i) {
		# someone passed a string, a feature type perhaps?
		$args->{avoid} = [ $args->{avoid} ];
	}
	
	### Check for conflicting features
	my $db = $args->{db} || $self->{data}->open_meta_database;
	my @overlap_features = $self->get_features(
		seq_id  => $seqid,
		start   => $start,
		end     => $stop,
		type    => $args->{avoid},
	);
	
	# get the overlapping features of the same type
	if (@overlap_features) {
		my $primary = $self->primary_id;
		# there are one or more feature of the type in this region
		# one of them is likely the one we're working with
		# but not necessarily - user may be looking outside original feature
		# the others are not what we want and therefore need to be 
		# avoided
		foreach my $feat (@overlap_features) {
			# skip the one we want
			next if ($feat->primary_id eq $primary);
			# now eliminate those scores which overlap this feature
			my $start = $feat->start;
			my $stop  = $feat->end;
			foreach my $position (keys %$pos2data) {
				# delete the scored position if it overlaps with 
				# the offending feature
				if (
					$position >= $start and
					$position <= $stop
				) {
					delete $pos2data->{$position};
				}
			}
		}
	}
}

sub _convert_to_relative_positions {
	my ($self, $pos2data, $position, $strand) = @_;
	
	my %relative_pos2data;
	if ($strand >= 0) {
		foreach my $p (keys %$pos2data) {
			$relative_pos2data{ $p - $position } = $pos2data->{$p};
		}
	}
	elsif ($strand < 0) {
		foreach my $p (keys %$pos2data) {
			$relative_pos2data{ $position - $p } = $pos2data->{$p};
		}
	}
	return wantarray ? %relative_pos2data : \%relative_pos2data;
}

sub _process_exon_scores {
	my ($self, $exon_scores, $pos2data, $adjustment, $start, $end, 
		$namecheck, $method) = @_;
	
	# ncount method
	if ($method eq 'ncount') {
		# we need to check both names and adjust position
		foreach my $p (keys %$exon_scores) {
			next unless ($p >= $start and $p <= $end); 
			foreach my $n (@{ $exon_scores->{$p} }) {
				if (exists $namecheck->{$n} ) {
					$namecheck->{$n}++;
					next;
				}
				else {
					$namecheck->{$n} = 1;
					my $a = $p - $adjustment;
					$pos2data->{$a} ||= [];
					push @{ $pos2data->{$a} }, $n;
				}
			}
		}
	}
	else {
		# just adjust scores
		foreach my $p (keys %$exon_scores) {
			next unless ($p >= $start and $p <= $end); 
			$pos2data->{ $p - $adjustment } = $exon_scores->{$p};
		}
	}
}

### String export

sub bed_string {
	my $self = shift;
	my %args = @_;
	$args{bed} ||= 6; # number of bed columns
	croak "bed count must be an integer!" unless $args{bed} =~ /^\d+$/;
	croak "bed count must be at least 3!" unless $args{bed} >= 3;
	
	# coordinate information
	$self->seqfeature; # retrieve the seqfeature object first
	my $chr   = $args{chromo} || $args{seq_id} || $self->seq_id;
	my $start = $args{start} || $self->start;
	my $stop  = $args{stop} || $args{end} || $self->stop || 
		$start + $self->length - 1 || $start;
	unless ($chr and defined $start) {
		carp "Not enough information to generate bed string. Need identifiable " . 
			"chromosome and start columns or SeqFeature object";
		return;
	}
	$start -= 1; # 0-based coordinates
	my $string = "$chr\t$start\t$stop";
	
	# additional information
	if ($args{bed} >= 4) {
		my $name = $args{name} || $self->name || 'Feature_' . $self->line_number;
		$string .= "\t$name";
	}
	if ($args{bed} >= 5) {
		my $score = exists $args{score} ? $args{score} : 1;
		$string .= "\t$score";
	}
	if ($args{bed} >= 6) {
		my $strand = $args{strand} || $self->strand;
		$strand = $strand == 0 ? '+' : $strand == 1 ? '+' : $strand == -1 ? '-' : $strand;
		$string .= "\t$strand";
	}
	# we could go on with other columns, but there's no guarantee that additional 
	# information is available, and we would have to implement user provided data 
	
	# done
	return $string;
}

sub gff_string {
	my $self = shift;
	my %args = @_;
	
	# coordinate information
	$self->seqfeature; # retrieve the seqfeature object first
	my $chr   = $args{chromo} || $args{seq_id} || $self->seq_id;
	my $start = $args{start} || $self->start;
	my $stop  = $args{stop} || $args{end} || $self->stop || 
		$start + $self->length - 1 || $start;
	unless ($chr and defined $start) {
		carp "Not enough information to generate GFF string. Need identifiable " . 
			"chromosome and start columns";
		return;
	}
	my $strand = $args{strand} || $self->strand;
	$strand = $strand == 0 ? '.' : $strand == 1 ? '+' : $strand == -1 ? '-' : $strand;
	
	# type information
	my $type = $args{type} || $self->type || undef;
	my ($source, $primary_tag);
	if (defined $type and $type =~ /:/) {
		($primary_tag, $source) = split /:/, $type;
	}
	unless ($source) {
		$source = $args{source} || '.';
	}
	unless ($primary_tag) {
		$primary_tag = $args{primary_tag} || defined $type ? $type : '.';
	}
	
	# score
	my $score = exists $args{score} ? $args{score} : '.';
	my $phase = '.'; # do not even bother!!!!
	
	# attributes
	my $name = $args{name} || $self->name || 'Feature_' . $self->line_number;
	my $attributes = "Name=$name";
	my $id = $args{id} || sprintf("%08d", $self->line_number);
	$attributes .= ";ID=$id";
	if (exists $args{attributes} and ref($args{attributes}) eq 'ARRAY') {
		foreach my $i (@{$args{attributes}}) {
			my $k = $self->{data}->name($i);
			$k =~ s/([\t\n\r%&\=;, ])/sprintf("%%%X",ord($1))/ge;
			my $v = $self->value($i);
			$v =~ s/([\t\n\r%&\=;, ])/sprintf("%%%X",ord($1))/ge;
			$attributes .= ";$k=$v";
		}
	}
	
	# done
	my $string = join("\t", $chr, $source, $primary_tag, $start, $stop, $strand, 
		$score, $phase, $attributes);
	return $string;
}


__END__

=head1 AUTHOR

 Timothy J. Parnell, PhD
 Dept of Oncological Sciences
 Huntsman Cancer Institute
 University of Utah
 Salt Lake City, UT, 84112

This package is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.  
