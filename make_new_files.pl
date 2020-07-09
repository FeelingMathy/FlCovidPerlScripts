#!C:/Strawberry/perl/bin/perl.exe
#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;

#
# This software is provided as is, where is, etc with no guarantee that it is
# fit for any purpose whatsoever. Use at your own risk. Mileage may vary.
#

#
# This script is horribly inefficient on purpose. Some (a lot?) of people reviewing it
# may not know perl and being able to say "I can see that this section just does so and
# so" will help
#
use File::Find;           
use File::chdir;
use File::Basename;
use Cwd qw(cwd);
use List::Util qw (shuffle);
use POSIX;
use File::Copy;
use DateTime;

use lib '.';
use translate;
use global_definitions;
use set_up_column_matches;

package main;

#
# Debug stuff
# Set to -1 to disable. See global_definitions.pm
#
my $record_debug_limit = $global_definitions::record_debug_limit_value;

my $cwd = Cwd::cwd();
my $windows_flag = 0;
if ($cwd =~ /^[C-Z]:/) {
    $windows_flag = 1;
}

my $dir;
if ($windows_flag) {
    $dir = lc $global_definitions::fq_root_dir_for_windows;
}
else {
    $dir = $global_definitions::fq_root_dir_for_linux;
}
$CWD = $dir;
$cwd = Cwd::cwd();
print ("Current working directory is $cwd\n");

my $f = "$dir/$global_definitions::column_name_output_file";
open (FILE, "<", $f) or die "Can not open $f: $!";
my $unified_name_string = <FILE>;
close (FILE);

print ("$unified_name_string\n");

my $NF_hash_ptr = make_name_hash ($unified_name_string);

#
# Read dirs.txt
#
my @fq_all_dirs_by_date;
if (open (FILE, "<", 'dirs.txt')) {
    while (my $record = <FILE>) {
        $record =~ s/[\r\n]+//;  # remove <cr><lf>
        push (@fq_all_dirs_by_date, "$cwd/$record");
    }
}
close (FILE);

#
# For each directory, process all the .csv files
#
my @suffixlist = qw (.csv);
foreach my $fq_dir (@fq_all_dirs_by_date) {
    my @csv_files_in_this_dir;
    my $fq_output_file;

    #
    # Start the output file with the combined column names
    #
    my @raw_new_file = $unified_name_string;

    #
    # Make a list of all the .csv files in the $fq_dir. As (if) the first one
    # is found, make up the fully qualified name of the output file
    #
    opendir (DIR, $fq_dir) or die "Can't open $fq_dir: $!";
    while (my $rel_filename = readdir (DIR)) {
        my $fq_filename = "$fq_dir/$rel_filename";
        if (-d $fq_filename) {
            next;
        }

        if ($rel_filename eq $global_definitions::NF_csv_file_name || $rel_filename eq $global_definitions::NF_normalized_csv_file_name) {
            next;
        }

        my ($name, $path, $suffix) = fileparse ($fq_filename, @suffixlist);
        $path =~ s/\/\z//;

        if ($suffix eq '.csv') {
            push (@csv_files_in_this_dir, $fq_filename);

            if (!(defined ($fq_output_file))) {
                $fq_output_file = "$path/$global_definitions::NF_csv_file_name";
            }
        }
    }

    #
    # Since it takes at least one .csv file to trigger the making of the
    # output file name, no output file => no .csv file => move on to the
    # next directory
    #
    if (!(defined ($fq_output_file))) {
        next;
    }

    my $file_number = 1;
    foreach my $fq_filename (@csv_files_in_this_dir) {

        #
        # Report to the user
        #
        if ($file_number == 1) {
            print ("\n");
        }
        my $string = sprintf ("%02d %s", $file_number++, $fq_filename);
        print ("$string\n");

        add_to_new_file ($fq_filename, \@raw_new_file,
            $NF_hash_ptr, $record_debug_limit);
    }

    #
    # @raw_new_file contains identical records extracted from multiple files
    #
    my $hdr = shift (@raw_new_file);
    my %hash = map { $_ => 1 } @raw_new_file;
    my @unsorted_new_file = keys %hash;
    my @new_file;
    if (0) {
        @new_file = sort (@unsorted_new_file);
    }
    else {
        @new_file = @unsorted_new_file;
    }
    unshift (@new_file, $hdr);

    #
    # Write the output file
    #
    print ("Creating $fq_output_file...\n");
    open (FILE, ">", $fq_output_file) or die "Can not open $fq_output_file: $!";
    foreach my $s (@new_file) {
        print (FILE "$s\n");
    }
    close (FILE);

}

#
#
#
exit (1);

###################################################################################
#
#
#  'FBT' = file being tested
#  'NF_' = new file being created
#
sub add_to_new_file {
    my $fbt_file = shift;
    my $NF_record_list_ptr = shift;
    my $NF_hash_ptr = shift;
    my $record_debug_limit = shift;

    #
    # Define a simple list of numbers. The 1st number ([0]) represents the 1st column
    # in the FBT. It contains a number that represents the destination column in the 
    # in the new output file with the standard names
    #
    my @column_matcher;
    my $column_matcher_len;
    my @deleted_columns;
    my $deleted_column_list_len;

    my $NF_column_count = %$NF_hash_ptr;
    my @pre_initialized_NF_record;
    for (my $i = 0; $i < $NF_column_count; $i++) {
        $pre_initialized_NF_record[$i] = '';
    }

    #
    # Loop through the records in the single specified file
    #
    my $record_number = 0;
    open (FILE, "<", $fbt_file) or die "Can not open $fbt_file: $!";
    while (my $record = <FILE>) {
        #
        # Chomp seems to work differently on Windows and Linux Mint. Use the regex to get
        # rid of any carriage control, new line characters
        #
        $record =~ s/[\r\n]+//;  # remove <cr><lf>

        #
        # If the record ends with a comma, remove it
        #
        $record =~ s/,\z//;

        $record_number++;

        my $header;
        if ($record_number == 1) {
            #
            # 1st record has column heading names
            #
            # Remove BOM if any
            #
            if ($record =~ /^\xef\xbb\xbf/) {
                $header = substr ($record, 3);
            }
            # elsif ($record =~ /^\xfe\xff\x00\x30\x00\x20\x00\x48\x00\x45\x00\x41\x00\x44/) {
            #     print ("File is Unicode\n");
            #     die;
            # }
            else {
                $header = $record;
            }

            my ($column_matcher_ptr) = set_up_column_matches::set_up_column_matches (
                $header,
                $NF_hash_ptr);
            @column_matcher = @$column_matcher_ptr;
            $column_matcher_len = @column_matcher;
        }
        else {
            #
            # 2nd+ record has information
            #
            
            #
            # See top of file
            #
            if ($record_debug_limit == 0) {
                last;
            }
            elsif ($record_debug_limit > 0) {
                $record_debug_limit--;
            }


            #
            # Split the FBT column data into a list of values
            #
            my @FBT_column_values = split (',', $record);
            my $FBT_column_count = @FBT_column_values;
            # print ("  \$FBT_column_count = $FBT_column_count at record $record_number\n");
            # print ("  \$record = $record\n");

            #
            # Move values from FBT to NF
            #
            my @NF_record = @pre_initialized_NF_record;
            for (my $from_column = 0; $from_column < $FBT_column_count; $from_column++) {
                my $to_column = $column_matcher[$from_column];
                if ($to_column != -1) {
                    my $value = $FBT_column_values[$from_column];
                    $NF_record[$to_column] = $value;
                }
            }

            #
            # Make a new NF record
            #
            my $new_csv_record = join (',', @NF_record);

            push (@$NF_record_list_ptr, $new_csv_record);
        }

    }

    close (FILE);
}


sub make_name_hash {
    my $names_string = shift;

    my @names_list = split (',', $names_string);
    my $names_list_len = @names_list;
    my %names_hash;
    for (my $i = 0; $i < $names_list_len; $i++) {
        my $key = $names_list[$i];
        $names_hash{$key} = $i;
    }

    return (\%names_hash);
}



1;  # required

