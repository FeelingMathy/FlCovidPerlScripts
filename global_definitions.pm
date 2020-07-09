#!/usr/bin/perl
package global_definitions;
use warnings FATAL => 'all';
use strict;

#
# For your operating system, enter the location of
# the root directory for your case line data directories.
#
# Your root directory should contain the daily directories
# like so:
# D:/Covid/CaseLineData:
#    2020-03-19
#    2020-03-20
#       etc
#    2020-07-08
#
our $fq_root_dir_for_windows = 'D:/Covid/CaseLineData';
our $fq_root_dir_for_linux = '/home/mickey/Covid/CaseLineData';

#
# This is the name of the file containing the selected column names
# It will be placed in the directory specified above
#
our $column_name_output_file = 'unified_column_names.csv';

#
# These are the names of the new .csv files created for each date
# They will be placed in the date directories
#
our $NF_csv_file_name = 'new_file.csv';
our $NF_normalized_csv_file_name = 'normalized_new_file.csv';
