package Bio::ToolBox::db_helper::constants;

# modules
require Exporter;
use strict;
use constant {
	CHR  => 0,  # chromosome
	STRT => 1,  # start
	STOP => 2,  # stop
	STR  => 3,  # strand
	STND => 4,  # strandedness
	METH => 5,  # method
	RETT => 6,  # return type
	DB   => 7,  # database object
	DATA => 8,  # first dataset, additional may be present
};

our @ISA = qw(Exporter);
our @EXPORT = qw(CHR STRT STOP STR STND METH RETT DB DATA);

# The true statement
1; 

__END__

=head1 NAME

Bio::ToolBox::db_helper::constants

=head1 DESCRIPTION

This module provides the named fields for the internal data collection array.
It's not meant to be used by individuals. Please see <Bio::ToolBox::db_helper>.

=head1 AUTHOR

 Timothy J. Parnell, PhD
 Huntsman Cancer Institute
 University of Utah
 Salt Lake City, UT, 84112

This package is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.  



